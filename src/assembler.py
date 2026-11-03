"""x86_64 NASM Assembler Implementation.

This module implements an x86_64 NASM assembler supporting 8, 16, 32, and 64-bit
instructions, various addressing modes (direct, indirect, base-index-scale-disp),
and standard Intel instruction formats.
"""

import sys
from typing import Dict, List, Optional, Tuple, Union

# ------------------------------------------------------------------------------
# Lookup Tables and Encodings
# ------------------------------------------------------------------------------

SINGLE_OPCODE_TABLE: Dict[str, str] = {
    "stc": "11111001",
    "clc": "11111000",
    "std": "11111101",
    "cld": "11111100",
    "syscall": "0000111100000101",
    "ret": "11000011",
}

# Maps register mnemonic to (3-bit NasM register code, register width in bits)
REGISTER_TABLE: Dict[str, Tuple[str, int]] = {
    "null": ("101", 0),
    # 64-bit general-purpose registers
    "rax": ("000", 64),
    "rcx": ("001", 64),
    "rdx": ("010", 64),
    "rbx": ("011", 64),
    "rsp": ("100", 64),
    "rbp": ("101", 64),
    "rsi": ("110", 64),
    "rdi": ("111", 64),
    # 32-bit registers
    "eax": ("000", 32),
    "ecx": ("001", 32),
    "edx": ("010", 32),
    "ebx": ("011", 32),
    "esp": ("100", 32),
    "ebp": ("101", 32),
    "esi": ("110", 32),
    "edi": ("111", 32),
    # 16-bit registers
    "ax": ("000", 16),
    "cx": ("001", 16),
    "dx": ("010", 16),
    "bx": ("011", 16),
    "sp": ("100", 16),
    "bp": ("101", 16),
    "si": ("110", 16),
    "di": ("111", 16),
    # 8-bit registers (low and high bytes)
    "al": ("000", 8),
    "cl": ("001", 8),
    "dl": ("010", 8),
    "bl": ("011", 8),
    "ah": ("100", 8),
    "ch": ("101", 8),
    "dh": ("110", 8),
    "bh": ("111", 8),
    # Extended 64-bit, 32-bit, 16-bit, 8-bit registers (r8-r15)
    "r8": ("000", 64),
    "r8d": ("000", 32),
    "r8w": ("000", 16),
    "r8b": ("000", 8),
    "r9": ("001", 64),
    "r9d": ("001", 32),
    "r9w": ("001", 16),
    "r9b": ("001", 8),
    "r10": ("010", 64),
    "r10d": ("010", 32),
    "r10w": ("010", 16),
    "r10b": ("010", 8),
    "r11": ("011", 64),
    "r11d": ("011", 32),
    "r11w": ("011", 16),
    "r11b": ("011", 8),
    "r12": ("100", 64),
    "r12d": ("100", 32),
    "r12w": ("100", 16),
    "r12b": ("100", 8),
    "r13": ("101", 64),
    "r13d": ("101", 32),
    "r13w": ("101", 16),
    "r13b": ("101", 8),
    "r14": ("110", 64),
    "r14d": ("110", 32),
    "r14w": ("110", 16),
    "r14b": ("110", 8),
    "r15": ("111", 64),
    "r15d": ("111", 32),
    "r15w": ("111", 16),
    "r15b": ("111", 8),
}

# Extended x86_64 registers that require REX prefix extension bits (R, X, B)
EXTENDED_REGISTERS: List[str] = [
    "r8", "r8d", "r8w", "r8b",
    "r9", "r9d", "r9w", "r9b",
    "r10", "r10d", "r10w", "r10b",
    "r11", "r11d", "r11w", "r11b",
    "r12", "r12d", "r12w", "r12b",
    "r13", "r13d", "r13w", "r13b",
    "r14", "r14d", "r14w", "r14b",
    "r15", "r15d", "r15w", "r15b",
]

SIZE_IDENTIFIERS: List[str] = ["BYTE", "WORD", "DWORD", "QWORD"]

SIZE_IDENTIFIER_MAP: Dict[str, int] = {
    "QWORD": 64,
    "DWORD": 32,
    "WORD": 16,
    "BYTE": 8,
}

SCALE_MAP: Dict[str, str] = {
    "1": "00",
    "2": "01",
    "4": "10",
    "8": "11",
}

# Condition codes for conditional jumps (Jcc)
CONDITION_CODE_MAP: Dict[str, str] = {
    "o": "0000",
    "no": "0001",
    "b": "0010",
    "nae": "0010",
    "nb": "0011",
    "ae": "0011",
    "e": "0100",
    "z": "0100",
    "ne": "0101",
    "nz": "0101",
    "be": "0110",
    "na": "0110",
    "nbe": "0111",
    "a": "0111",
    "s": "1000",
    "ns": "1001",
    "p": "1010",
    "pe": "1010",
    "np": "1011",
    "po": "1011",
    "l": "1100",
    "nge": "1100",
    "nl": "1101",
    "ge": "1101",
    "le": "1110",
    "ng": "1110",
    "nle": "1111",
    "g": "1111",
}


# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------

def pad_to_multiple_of_four(bit_string: str) -> str:
    """Pad binary string with leading zeros so length is a multiple of 4."""
    while len(bit_string) % 4 != 0:
        bit_string = "0" + bit_string
    return bit_string


def normalize_hex_to_binary(hex_value: str, target_bit_size: int) -> str:
    """Convert hexadecimal string into little-endian binary bit string.

    Args:
        hex_value: Hexadecimal string (without 0x prefix).
        target_bit_size: Target bit size (8, 16, 32, 64).

    Returns:
        Binary string formatted in little-endian byte ordering.
    """
    result_binary = ""
    # Pad to target hex character width
    expected_hex_length = target_bit_size // 4
    while len(hex_value) < expected_hex_length:
        hex_value = "0" + hex_value

    # Process byte by byte in reverse (little-endian order)
    for index in range(len(hex_value) - 1, 0, -2):
        high_nibble = pad_to_multiple_of_four(bin(int(hex_value[index - 1], 16))[2:])
        low_nibble = pad_to_multiple_of_four(bin(int(hex_value[index], 16))[2:])
        result_binary += high_nibble + low_nibble

    return result_binary


def parse_instruction(instruction_line: str) -> list:
    """Parse instruction line into mnemonic and structured operands.

    Supports registers, immediates, and memory addressing modes:
    [base+index*scale+disp]

    Args:
        instruction_line: Raw NASM assembly line (e.g. 'mov rax, rbx').

    Returns:
        Parsed representation: [mnemonic, [[op1_parts...], [op2_parts...]]]
    """
    parts = instruction_line.strip().split(" ", 1)
    if len(parts) > 1:
        operand_tokens = parts[1].split(",")
        parsed_operands = []
        for operand in operand_tokens:
            parsed_operands.append(operand.split())

        for operand_index in range(len(parsed_operands)):
            token_list = parsed_operands[operand_index]
            if len(token_list) > 0 and token_list[0] in SIZE_IDENTIFIERS:
                # Memory operand: e.g. ["DWORD", "PTR", "[ebx+ecx*1+0x10]"]
                memory_expression = token_list[2][1:-1]  # Strip '[' and ']'
                plus_index = memory_expression.find("+")
                star_index = memory_expression.find("*")

                if plus_index == -1:
                    if star_index == -1:
                        # Single displacement or single base
                        if memory_expression.startswith("0x") or memory_expression.startswith("0"):
                            displacement = (
                                memory_expression[2:]
                                if memory_expression.startswith("0x")
                                else memory_expression
                            )
                            parsed_operands[operand_index][2] = ["null", "null", "null", displacement]
                        else:
                            parsed_operands[operand_index][2] = [memory_expression, "null", "null", "null"]
                    else:
                        # Index * Scale
                        scale_parts = memory_expression.split("*")
                        parsed_operands[operand_index][2] = ["null", scale_parts[0], scale_parts[1], "null"]
                elif star_index == -1:
                    # Base + Displacement
                    base_parts = memory_expression.split("+")
                    displacement = base_parts[1]
                    if displacement.startswith("0x"):
                        displacement = displacement[2:]
                    parsed_operands[operand_index][2] = [base_parts[0], "null", "null", displacement]
                else:
                    if plus_index < star_index:
                        # Base + Index*Scale (+ Disp)
                        plus_count = memory_expression.count("+")
                        normalized = memory_expression.replace("*", "+").split("+")
                        if plus_count == 2:
                            displacement = normalized[3]
                            if displacement.startswith("0x"):
                                displacement = displacement[2:]
                            parsed_operands[operand_index][2] = [normalized[0], normalized[1], normalized[2], displacement]
                        else:
                            parsed_operands[operand_index][2] = [normalized[0], normalized[1], normalized[2], "null"]
                    else:
                        # Index*Scale + Disp
                        normalized = memory_expression.replace("*", "+").split("+")
                        displacement = normalized[2]
                        if displacement.startswith("0x"):
                            displacement = displacement[2:]
                        parsed_operands[operand_index][2] = ["null", normalized[0], normalized[1], displacement]
            elif len(token_list) > 0 and token_list[0] not in REGISTER_TABLE:
                # Immediate operand
                raw_immediate = token_list[0]
                if raw_immediate.startswith("0x"):
                    parsed_operands[operand_index][0] = raw_immediate[2:]
                elif raw_immediate.startswith("0") and len(raw_immediate) > 1:
                    parsed_operands[operand_index][0] = raw_immediate[1:]
                else:
                    try:
                        parsed_operands[operand_index][0] = hex(int(raw_immediate))[2:]
                    except ValueError:
                        pass
        parts[1] = parsed_operands
    return parts


# ------------------------------------------------------------------------------
# Assembler Engine
# ------------------------------------------------------------------------------

def assemble(instruction_line: str) -> str:
    """Assemble a single NASM x86_64 instruction into hexadecimal machine code.

    Args:
        instruction_line: NASM assembly instruction string (e.g. 'mov rax, rbx').

    Returns:
        Hexadecimal machine code string (lowercase, no 0x prefix).
    """
    instruction_line = instruction_line.strip()
    if not instruction_line or instruction_line.startswith(";"):
        return ""

    instruction = parse_instruction(instruction_line)
    mnemonic = instruction[0]

    # Fast path for standalone solo instructions
    if mnemonic in SINGLE_OPCODE_TABLE and len(instruction) == 1:
        binary_code = SINGLE_OPCODE_TABLE[mnemonic]
        return hex(int(binary_code, 2))[2:].zfill(len(binary_code) // 4)

    # Instruction encoding state dictionary
    result: Dict[str, str] = {}
    operand_size = 0
    address_size = 0
    displacement_size = 0

    # 1. Determine Operand Size
    if len(instruction) > 1 and len(instruction[1]) > 0:
        first_token = instruction[1][0][0]
        if first_token in REGISTER_TABLE:
            operand_size = REGISTER_TABLE[first_token][1]
        elif first_token in SIZE_IDENTIFIERS:
            operand_size = SIZE_IDENTIFIER_MAP[first_token]
        elif len(instruction[1]) > 1:
            second_token = instruction[1][1][0]
            if second_token in REGISTER_TABLE:
                operand_size = REGISTER_TABLE[second_token][1]
            elif second_token in SIZE_IDENTIFIERS:
                operand_size = SIZE_IDENTIFIER_MAP[second_token]

    # 2. Determine Address Size and Displacement Size from Memory Operands
    for operand_index in range(len(instruction[1]) if len(instruction) > 1 else 0):
        operand_tokens = instruction[1][operand_index]
        if len(operand_tokens) > 0 and operand_tokens[0] in SIZE_IDENTIFIERS:
            base_register = operand_tokens[2][0]
            index_register = operand_tokens[2][1]
            displacement_value_str = operand_tokens[2][3]

            if base_register != "null" and base_register in REGISTER_TABLE:
                address_size = REGISTER_TABLE[base_register][1]
            elif index_register != "null" and index_register in REGISTER_TABLE:
                address_size = REGISTER_TABLE[index_register][1]

            if displacement_value_str != "null":
                try:
                    numeric_displacement = int(displacement_value_str, 16)
                    displacement_size = 32 if numeric_displacement > 127 else 8
                except ValueError:
                    displacement_size = 32

    # Prefixes: Operand Size Override (0x66) & Address Size Override (0x67)
    if operand_size == 16:
        result["66"] = "01100110"
    if address_size == 32:
        result["67"] = "01100111"

    # Helper subroutines
    def handle_second_register():
        nonlocal operand_size, address_size, displacement_size
        result["OpCode_W"] = "0" if operand_size == 8 else "1"
        result["OpCode_D"] = "0"
        result["Reg"] = REGISTER_TABLE[instruction[1][1][0]][0]

        if instruction[1][1][0].startswith("r"):
            result["Rex_Pre"] = "0100"
            result["Rex_W"] = "1" if REGISTER_TABLE[instruction[1][1][0]][1] == 64 else "0"
            if instruction[1][1][0] in EXTENDED_REGISTERS:
                result["Rex_R"] = "1"

        if instruction[1][0][0] in REGISTER_TABLE:  # First operand is register
            result["Mod"] = "11"
            result["RM"] = REGISTER_TABLE[instruction[1][0][0]][0]
            if instruction[1][0][0] in EXTENDED_REGISTERS:
                result["Rex_Pre"] = "0100"
                result["Rex_B"] = "1"
        elif instruction[1][0][0] in SIZE_IDENTIFIERS:  # First operand is memory
            memory_spec = instruction[1][0][2]
            base, index, scale, displacement = memory_spec[0], memory_spec[1], memory_spec[2], memory_spec[3]
            if index == "null" and displacement == "null":
                if base in ["rbp", "ebp", "bp", "ch"]:
                    result["Mod"] = "01"
                    result["RM"] = "101"
                    result["Dis"] = "00000000"
                else:
                    if base in EXTENDED_REGISTERS:
                        result["Rex_Pre"] = "0100"
                        result["Rex_B"] = "1"
                    result["Mod"] = "00"
                    result["RM"] = REGISTER_TABLE[base][0]
            elif base != "null" and index == "null":
                result["Mod"] = "01" if displacement_size == 8 else "10"
                result["RM"] = REGISTER_TABLE[base][0]
                if base in EXTENDED_REGISTERS:
                    result["Rex_Pre"] = "0100"
                    result["Rex_B"] = "1"
                result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)
            else:
                result["Mod"] = "01" if displacement_size == 8 else ("10" if displacement_size == 32 else "00")
                if base == "null":
                    result["Mod"] = "00"
                    displacement_size = 32
                result["RM"] = "100"
                result["Base"] = REGISTER_TABLE[base][0]
                if base in EXTENDED_REGISTERS:
                    result["Rex_Pre"] = "0100"
                    result["Rex_B"] = "1"
                if index == "null":
                    result["Scale"] = "00"
                    result["Index"] = "100"
                    result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)
                else:
                    result["Scale"] = SCALE_MAP[scale]
                    result["Index"] = REGISTER_TABLE[index][0]
                    if index in EXTENDED_REGISTERS:
                        result["Rex_Pre"] = "0100"
                        result["Rex_X"] = "1"
                    if displacement == "null":
                        result["Dis"] = normalize_hex_to_binary("0", displacement_size)
                    else:
                        result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)

    def handle_second_immediate():
        nonlocal operand_size, address_size, displacement_size
        immediate_str = instruction[1][1][0]
        try:
            immediate_int = int(immediate_str, 16)
        except ValueError:
            immediate_int = 0

        # Sign-extension bit (s bit / OpCode_D): 1 when imm fits in 8-bit sign-extended and op_sz > 8
        if immediate_int <= 127 and operand_size != 8:
            result["OpCode_D"] = "1"
            result["Data"] = normalize_hex_to_binary(immediate_str, 8)
        else:
            result["OpCode_D"] = "0"
            result["Data"] = normalize_hex_to_binary(immediate_str, min(operand_size, 32))

        result["OpCode_W"] = "0" if operand_size == 8 else "1"
        if operand_size == 64:
            result["Rex_Pre"] = "0100"
            result["Rex_W"] = "1"

        first_operand = instruction[1][0]
        if first_operand[0] in REGISTER_TABLE:
            result["Mod"] = "11"
            result["RM"] = REGISTER_TABLE[first_operand[0]][0]
            if first_operand[0].startswith("r"):
                result["Rex_Pre"] = "0100"
                if REGISTER_TABLE[first_operand[0]][1] == 64:
                    result["Rex_W"] = "1"
                if first_operand[0] in EXTENDED_REGISTERS:
                    result["Rex_B"] = "1"
        else:
            memory_spec = first_operand[2]
            base, index, scale, displacement = memory_spec[0], memory_spec[1], memory_spec[2], memory_spec[3]
            if index == "null" and displacement == "null":
                if base in ["rbp", "ebp", "bp", "ch"]:
                    result["Mod"] = "01"
                    result["RM"] = "101"
                    result["Dis"] = "00000000"
                else:
                    if base in EXTENDED_REGISTERS:
                        result["Rex_Pre"] = "0100"
                        result["Rex_B"] = "1"
                    result["Mod"] = "00"
                    result["RM"] = REGISTER_TABLE[base][0]
            elif base != "null" and index == "null":
                result["Mod"] = "01" if displacement_size == 8 else "10"
                result["RM"] = REGISTER_TABLE[base][0]
                if base in EXTENDED_REGISTERS:
                    result["Rex_Pre"] = "0100"
                    result["Rex_B"] = "1"
                result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)
            else:
                result["Mod"] = "01" if displacement_size == 8 else ("10" if displacement_size == 32 else "00")
                if base == "null":
                    result["Mod"] = "00"
                    displacement_size = 32
                result["RM"] = "100"
                result["Base"] = REGISTER_TABLE[base][0]
                if base in EXTENDED_REGISTERS:
                    result["Rex_Pre"] = "0100"
                    result["Rex_B"] = "1"
                if index == "null":
                    result["Scale"] = "00"
                    result["Index"] = "100"
                    result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)
                else:
                    result["Scale"] = SCALE_MAP[scale]
                    result["Index"] = REGISTER_TABLE[index][0]
                    if index in EXTENDED_REGISTERS:
                        result["Rex_Pre"] = "0100"
                        result["Rex_X"] = "1"
                    if displacement == "null":
                        result["Dis"] = normalize_hex_to_binary("0", displacement_size)
                    else:
                        result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)

    def handle_single_operand():
        nonlocal operand_size, address_size, displacement_size
        result["OpCode_D"] = "1"
        result["OpCode_W"] = "0" if operand_size == 8 else "1"
        if operand_size == 64:
            result["Rex_Pre"] = "0100"
            result["Rex_W"] = "1"

        target_operand = instruction[1][0]
        if target_operand[0] in REGISTER_TABLE:
            result["Mod"] = "11"
            result["RM"] = REGISTER_TABLE[target_operand[0]][0]
            if target_operand[0].startswith("r"):
                result["Rex_Pre"] = "0100"
                result["Rex_W"] = "1" if REGISTER_TABLE[target_operand[0]][1] == 64 else "0"
                if target_operand[0] in EXTENDED_REGISTERS:
                    result["Rex_B"] = "1"
        else:
            memory_spec = target_operand[2]
            base, index, scale, displacement = memory_spec[0], memory_spec[1], memory_spec[2], memory_spec[3]
            if index == "null" and displacement == "null":
                if base in ["rbp", "ebp", "bp", "ch"]:
                    result["Mod"] = "01"
                    result["RM"] = "101"
                    result["Dis"] = "00000000"
                else:
                    if base in EXTENDED_REGISTERS:
                        result["Rex_Pre"] = "0100"
                        result["Rex_B"] = "1"
                    result["Mod"] = "00"
                    result["RM"] = REGISTER_TABLE[base][0]
            elif base != "null" and index == "null":
                result["Mod"] = "01" if displacement_size == 8 else "10"
                result["RM"] = REGISTER_TABLE[base][0]
                if base in EXTENDED_REGISTERS:
                    result["Rex_Pre"] = "0100"
                    result["Rex_B"] = "1"
                result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)
            else:
                result["Mod"] = "01" if displacement_size == 8 else ("10" if displacement_size == 32 else "00")
                if base == "null":
                    result["Mod"] = "00"
                    displacement_size = 32
                result["RM"] = "100"
                result["Base"] = REGISTER_TABLE[base][0]
                if base in EXTENDED_REGISTERS:
                    result["Rex_Pre"] = "0100"
                    result["Rex_B"] = "1"
                if index == "null":
                    result["Scale"] = "00"
                    result["Index"] = "100"
                    result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)
                else:
                    result["Scale"] = SCALE_MAP[scale]
                    result["Index"] = REGISTER_TABLE[index][0]
                    if index in EXTENDED_REGISTERS:
                        result["Rex_Pre"] = "0100"
                        result["Rex_X"] = "1"
                    if displacement == "null":
                        result["Dis"] = normalize_hex_to_binary("0", displacement_size)
                    else:
                        result["Dis"] = normalize_hex_to_binary(displacement, displacement_size)

    # 3. Instruction Dispatch
    if mnemonic == "mov":
        if instruction[1][1][0] in REGISTER_TABLE:
            result["OpCode"] = "100010"
            handle_second_register()
        elif instruction[1][1][0] in SIZE_IDENTIFIERS:
            result["OpCode"] = "100010"
            instruction[1][0], instruction[1][1] = instruction[1][1], instruction[1][0]
            handle_second_register()
            result["OpCode_D"] = "1"
        else:
            # Immediate mov
            if instruction[1][0][0] in REGISTER_TABLE:
                result["OpCode"] = "1011"
                result["OpCode_W"] = "0" if operand_size == 8 else "1"
                result["Reg"] = REGISTER_TABLE[instruction[1][0][0]][0]
                result["Data"] = normalize_hex_to_binary(instruction[1][1][0], operand_size)
                if instruction[1][0][0].startswith("r"):
                    result["Rex_Pre"] = "0100"
                    result["Rex_W"] = "1" if REGISTER_TABLE[instruction[1][0][0]][1] == 64 else "0"
                    if instruction[1][0][0] in EXTENDED_REGISTERS:
                        result["Rex_B"] = "1"
            else:
                result["OpCode"] = "110001"
                result["Reg"] = "000"
                handle_second_immediate()

    elif mnemonic in ["add", "adc", "sub", "sbb", "and", "or", "xor", "cmp"]:
        opcode_map = {
            "add": ("000000", "000001", "000"),
            "adc": ("000100", "000101", "010"),
            "sub": ("001010", "001011", "101"),
            "sbb": ("000110", "000111", "011"),
            "and": ("001000", "001001", "100"),
            "or":  ("000010", "000011", "001"),
            "xor": ("001100", "001101", "110"),
            "cmp": ("001110", "001111", "111"),
        }
        std_op, acc_op, reg_ext = opcode_map[mnemonic]
        if instruction[1][1][0] in REGISTER_TABLE:
            result["OpCode"] = std_op
            handle_second_register()
        elif instruction[1][1][0] in SIZE_IDENTIFIERS:
            result["OpCode"] = std_op
            instruction[1][0], instruction[1][1] = instruction[1][1], instruction[1][0]
            handle_second_register()
            result["OpCode_D"] = "1"
        else:
            first_reg = instruction[1][0][0]
            imm_int = int(instruction[1][1][0], 16)
            if first_reg in ["rax", "eax", "ax", "al"] and imm_int > 127:
                if operand_size == 64:
                    result["Rex_Pre"] = "0100"
                    result["Rex_W"] = "1"
                result["OpCode"] = acc_op
                result["OpCode_D"] = "0"
                result["OpCode_W"] = "0" if operand_size == 8 else "1"
                result["Data"] = normalize_hex_to_binary(instruction[1][1][0], min(operand_size, 32))
            else:
                result["OpCode"] = "100000"
                result["Reg"] = reg_ext
                handle_second_immediate()

    elif mnemonic == "test":
        if instruction[1][1][0] in REGISTER_TABLE:
            result["OpCode"] = "100001"
            handle_second_register()
            result["OpCode_D"] = "0"
        elif instruction[1][1][0] in SIZE_IDENTIFIERS:
            result["OpCode"] = "100001"
            instruction[1][0], instruction[1][1] = instruction[1][1], instruction[1][0]
            handle_second_register()
        else:
            first_reg = instruction[1][0][0]
            if first_reg in ["rax", "eax", "ax", "al"]:
                if operand_size == 64:
                    result["Rex_Pre"] = "0100"
                    result["Rex_W"] = "1"
                result["OpCode"] = "101010"
                result["OpCode_D"] = "0"
                result["OpCode_W"] = "0" if operand_size == 8 else "1"
                result["Data"] = normalize_hex_to_binary(instruction[1][1][0], min(operand_size, 32))
            else:
                result["OpCode"] = "111101"
                result["Reg"] = "000"
                handle_second_immediate()

    elif mnemonic == "xchg":
        result["OpCode"] = "100001"
        handle_second_register()
        result["OpCode_D"] = "1"

    elif mnemonic == "xadd":
        result["OpCodeE"] = "00001111"
        result["OpCode"] = "110000"
        handle_second_register()
        result["OpCode_D"] = "1"

    elif mnemonic == "imul":
        result["OpCodeE"] = "00001111"
        result["OpCode"] = "101011"
        if instruction[1][0][0] in REGISTER_TABLE and instruction[1][1][0] in SIZE_IDENTIFIERS:
            handle_second_register()
        else:
            instruction[1][0], instruction[1][1] = instruction[1][1], instruction[1][0]
            handle_second_register()
        result["OpCode_D"] = "1"

    elif mnemonic == "idiv":
        result["OpCode"] = "111101"
        result["Reg"] = "111"
        handle_single_operand()

    elif mnemonic in ["bsf", "bsr"]:
        result["OpCodeE"] = "00001111"
        result["OpCode"] = "101111"
        if mnemonic == "bsf":
            result["OpCode_D"] = "0"
            result["OpCode_W"] = "0"
        else:
            result["OpCode_D"] = "0"
            result["OpCode_W"] = "1"
        if instruction[1][0][0] in REGISTER_TABLE and instruction[1][1][0] in SIZE_IDENTIFIERS:
            handle_second_register()
        else:
            instruction[1][0], instruction[1][1] = instruction[1][1], instruction[1][0]
            handle_second_register()
        result["OpCode_D"] = "1"
        result["OpCode_W"] = "1" if mnemonic == "bsr" else "0"

    elif mnemonic == "jmp":
        result["OpCode"] = "111111"
        handle_single_operand()
        result["OpCode_D"] = "1"
        result["OpCode_W"] = "1"
        result["Rex_W"] = "0"
        result["Reg"] = "100"

    elif mnemonic.startswith("j") and mnemonic[1:] in CONDITION_CODE_MAP:
        result["OpCodeE"] = "00001111"
        result["OpCode"] = "1000"
        result["Dis"] = normalize_hex_to_binary(instruction[1][0][0], 32)
        result["OpCode_D"] = CONDITION_CODE_MAP[mnemonic[1:]]

    elif mnemonic in ["shl", "shr"]:
        reg_code = "100" if mnemonic == "shl" else "101"
        if len(instruction[1]) == 1 or instruction[1][1][0] == "1":
            result["OpCode"] = "110100"
            result["Reg"] = reg_code
            handle_single_operand()
            result["OpCode_D"] = "0"
        elif instruction[1][1][0] == "cl":
            result["OpCode"] = "110100"
            result["Reg"] = reg_code
            handle_single_operand()
            result["OpCode_D"] = "1"
        else:
            result["OpCode"] = "110000"
            result["Reg"] = reg_code
            handle_single_operand()
            result["OpCode_D"] = "0"
            result["Data"] = normalize_hex_to_binary(instruction[1][1][0], 8)

    elif mnemonic in ["dec", "inc"]:
        result["OpCode"] = "111111"
        result["Reg"] = "001" if mnemonic == "dec" else "000"
        handle_single_operand()

    elif mnemonic in ["neg", "not"]:
        result["OpCode"] = "111101"
        result["Reg"] = "011" if mnemonic == "neg" else "010"
        handle_single_operand()
        result["OpCode_D"] = "1"

    elif mnemonic == "call":
        result["OpCode"] = "11101000"
        result["Dis"] = normalize_hex_to_binary(instruction[1][0][0], 32)

    elif mnemonic == "ret":
        if len(instruction) == 1:
            result["OpCode"] = "11000011"
        else:
            result["OpCode"] = "11000010"
            result["Dis"] = normalize_hex_to_binary(instruction[1][0][0], 16)

    elif mnemonic == "push":
        target = instruction[1][0][0]
        if target in REGISTER_TABLE:
            result["OpCode"] = "0101"
            result["OpCode_D"] = "0"
            result["OpCode_W"] = REGISTER_TABLE[target][0]
            if operand_size == 64:
                result["Rex_Pre"] = "0100"
                result["Rex_W"] = "1"
            if target in EXTENDED_REGISTERS:
                result["Rex_Pre"] = "0100"
                result["Rex_B"] = "1"
        elif target in SIZE_IDENTIFIERS:
            result["OpCode"] = "111111"
            result["Reg"] = "110"
            handle_single_operand()
            for key in ["Rex_Pre", "Rex_W", "Rex_R", "Rex_X", "Rex_B"]:
                result.pop(key, None)
            result["OpCode_D"] = "1"
            result["OpCode_W"] = "1"
        else:
            # Immediate push
            result["OpCode"] = "011010"
            result["OpCode_D"] = "0"
            result["OpCode_W"] = "0"
            imm_int = int(target, 16)
            if imm_int > 127:
                result["Data"] = normalize_hex_to_binary(target, 32)
            else:
                result["Data"] = normalize_hex_to_binary(target, 8)

    elif mnemonic == "pop":
        target = instruction[1][0][0]
        if target in REGISTER_TABLE:
            result["OpCode"] = "0101"
            result["OpCode_D"] = "1"
            result["OpCode_W"] = REGISTER_TABLE[target][0]
            if operand_size == 64:
                result["Rex_Pre"] = "0100"
                result["Rex_W"] = "1"
            if target in EXTENDED_REGISTERS:
                result["Rex_Pre"] = "0100"
                result["Rex_B"] = "1"
        else:
            result["OpCode"] = "100011"
            result["Reg"] = "000"
            handle_single_operand()
            for key in ["Rex_Pre", "Rex_W", "Rex_R", "Rex_X", "Rex_B"]:
                result.pop(key, None)
            result["OpCode_D"] = "1"
            result["OpCode_W"] = "1"

    # 4. Concatenate bit fields in architectural NASM order
    field_order = [
        "67", "66", "Rex_Pre", "Rex_W", "Rex_R", "Rex_X", "Rex_B",
        "OpCodeE", "OpCode", "OpCode_D", "OpCode_W",
        "Mod", "Reg", "RM", "Scale", "Index", "Base", "Dis", "Data",
    ]

    if "Rex_Pre" in result:
        result.setdefault("Rex_W", "0")
        result.setdefault("Rex_R", "0")
        result.setdefault("Rex_X", "0")
        result.setdefault("Rex_B", "0")

    bit_stream = ""
    for field in field_order:
        if field in result:
            bit_stream += result[field]

    bit_stream = pad_to_multiple_of_four(bit_stream)
    expected_hex_chars = len(bit_stream) // 4
    machine_code_hex = hex(int(bit_stream, 2))[2:].zfill(expected_hex_chars)
    return machine_code_hex


# ------------------------------------------------------------------------------
# Command-Line Entry Point
# ------------------------------------------------------------------------------

def main() -> None:
    """CLI runner supporting stdin pipe, arguments, or batch file execution."""
    if len(sys.argv) > 1 and sys.argv[1] not in ["-f", "--file"]:
        # Direct instruction string argument
        instruction_line = " ".join(sys.argv[1:])
        output_hex = assemble(instruction_line)
        print(output_hex)
    elif len(sys.argv) > 2 and sys.argv[1] in ["-f", "--file"]:
        # Process input file and write machine code to stdout or files
        input_path = sys.argv[2]
        with open(input_path, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if line and not line.startswith(";"):
                    print(assemble(line))
    else:
        # Standard input interactive / piped mode
        for line in sys.stdin:
            line = line.strip()
            if line:
                print(assemble(line))


if __name__ == "__main__":
    main()
