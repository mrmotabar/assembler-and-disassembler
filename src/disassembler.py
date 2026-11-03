"""x86_64 NASM Disassembler Implementation.

This module implements an x86_64 NASM disassembler that decodes raw hexadecimal
machine code into human-readable NASM assembly instructions.
"""

import sys
from typing import Dict, List, Optional, Tuple, Union

# ------------------------------------------------------------------------------
# Lookup Tables and Mappings
# ------------------------------------------------------------------------------

SINGLE_OPCODE_TABLE: Dict[str, str] = {
    "11111001": "stc",
    "11111000": "clc",
    "11111101": "std",
    "11111100": "cld",
    "0000111100000101": "syscall",
    "11000011": "ret",
}

# Registers mapped by bit width (8, 16, 32, 64) and 4-bit key (Extension bit + 3-bit code)
REGISTER_TABLE: Dict[int, Dict[str, str]] = {
    64: {
        "0000": "rax", "0001": "rcx", "0010": "rdx", "0011": "rbx",
        "0100": "rsp", "0101": "rbp", "0110": "rsi", "0111": "rdi",
        "1000": "r8",  "1001": "r9",  "1010": "r10", "1011": "r11",
        "1100": "r12", "1101": "r13", "1110": "r14", "1111": "r15",
    },
    32: {
        "0000": "eax",  "0001": "ecx",  "0010": "edx",  "0011": "ebx",
        "0100": "esp",  "0101": "ebp",  "0110": "esi",  "0111": "edi",
        "1000": "r8d",  "1001": "r9d",  "1010": "r10d", "1011": "r11d",
        "1100": "r12d", "1101": "r13d", "1110": "r14d", "1111": "r15d",
    },
    16: {
        "0000": "ax",   "0001": "cx",   "0010": "dx",   "0011": "bx",
        "0100": "sp",   "0101": "bp",   "0110": "si",   "0111": "di",
        "1000": "r8w",  "1001": "r9w",  "1010": "r10w", "1011": "r11w",
        "1100": "r12w", "1101": "r13w", "1110": "r14w", "1111": "r15w",
    },
    8: {
        "0000": "al",   "0001": "cl",   "0010": "dl",   "0011": "bl",
        "0100": "ah",   "0101": "ch",   "0110": "dh",   "0111": "bh",
        "1000": "r8b",  "1001": "r9b",  "1010": "r10b", "1011": "r11b",
        "1100": "r12b", "1101": "r13b", "1110": "r14b", "1111": "r15b",
    },
}

OPCODE_TWO_OPERAND_TABLE: Dict[str, str] = {
    "100010": "mov",
    "000000": "add",
    "000100": "adc",
    "001010": "sub",
    "000110": "sbb",
    "001000": "and",
    "000010": "or",
    "001100": "xor",
    "001110": "cmp",
    "1000010": "test",
    "1000011": "xchg",
    "00001111110000": "xadd",
    "00001111101011": "imul",
    "000011111011110": "bsf",
    "000011111011111": "bsr",
}

EXTENDED_TWO_OPERAND_PREFIXES: List[str] = ["110000", "101011", "101111"]

OPCODE_IMMEDIATE_TABLE: Dict[str, Dict[str, str]] = {
    "110001": {"000": "mov"},
    "100000": {
        "000": "add",
        "001": "or",
        "010": "adc",
        "011": "sbb",
        "100": "and",
        "101": "sub",
        "110": "xor",
        "111": "cmp",
    },
    "111101": {
        "000": "test",
        "010": "not",
        "011": "neg",
        "111": "idiv",
    },
    "111111": {
        "000": "inc",
        "001": "dec",
        "100": "jmp",
        "110": "push",
    },
    "110000": {
        "100": "shl",
        "101": "shr",
    },
    "110100": {
        "100": "shl",
        "101": "shr",
    },
    "100011": {
        "000": "pop",
    },
}

ACCUMULATOR_OPCODE_TABLE: Dict[str, str] = {
    "0000010": "add",
    "0001010": "adc",
    "0010110": "sub",
    "0001110": "sbb",
    "0010010": "and",
    "0000110": "or",
    "0011010": "xor",
    "0011110": "cmp",
    "1010100": "test",
}

SIZE_IDENTIFIERS: Dict[int, str] = {
    64: "QWORD",
    32: "DWORD",
    16: "WORD",
    8: "BYTE",
}

SCALE_MAP: Dict[str, str] = {
    "00": "1",
    "01": "2",
    "10": "4",
    "11": "8",
}

CONDITION_CODE_MAP: Dict[str, str] = {
    "0000": "o",
    "0001": "no",
    "0010": "b",
    "0011": "ae",
    "0100": "e",
    "0101": "ne",
    "0110": "be",
    "0111": "a",
    "1000": "s",
    "1001": "ns",
    "1010": "p",
    "1011": "np",
    "1100": "l",
    "1101": "ge",
    "1110": "le",
    "1111": "g",
}


# ------------------------------------------------------------------------------
# Disassembler Engine
# ------------------------------------------------------------------------------

def hex_to_binary_bitstring(hex_string: str) -> str:
    """Convert hexadecimal machine code string to padded binary bitstring."""
    hex_string = hex_string.strip()
    if hex_string.startswith("0x") or hex_string.startswith("0X"):
        hex_string = hex_string[2:]

    # Each hex character represents exactly 4 bits
    binary_parts = []
    for character in hex_string:
        binary_nibble = bin(int(character, 16))[2:].zfill(4)
        binary_parts.append(binary_nibble)
    return "".join(binary_parts)


def disassemble(hex_machine_code: str) -> str:
    """Disassemble an x86_64 hexadecimal machine code string into NASM assembly.

    Args:
        hex_machine_code: Hexadecimal string (e.g. '4889d8').

    Returns:
        Disassembled NASM instruction (e.g. 'mov rax, rbx').
    """
    hex_machine_code = hex_machine_code.strip()
    if not hex_machine_code:
        return ""

    binary_code = hex_to_binary_bitstring(hex_machine_code)

    # Fast path for single opcode lookup
    if binary_code in SINGLE_OPCODE_TABLE:
        return SINGLE_OPCODE_TABLE[binary_code]

    # Parsing state
    operand_sizes = [8, 16, 32, 64]
    address_sizes = [32, 64]
    displacement_sizes = [8, 32]
    decoded_fields: Dict[str, str] = {
        "Rex_R": "0",
        "Rex_X": "0",
        "Rex_B": "0",
        "OpCode": "",
    }

    def extract_displacement(target_bit_size: int) -> str:
        nonlocal binary_code
        little_endian_binary = ""
        for index in range(target_bit_size - 8, -1, -8):
            if index > len(binary_code) - 1:
                continue
            little_endian_binary += binary_code[index : index + 8]
        binary_code = binary_code[target_bit_size:]
        if not little_endian_binary:
            return "0x0"
        return hex(int(little_endian_binary, 2))

    # 1. Address Size Override Prefix (0x67)
    if binary_code.startswith("01100111"):
        address_sizes = [32]
        binary_code = binary_code[8:]
    else:
        if 32 in address_sizes:
            address_sizes.remove(32)

    # 2. Operand Size Override Prefix (0x66)
    if binary_code.startswith("01100110"):
        operand_sizes = [16]
        binary_code = binary_code[8:]
    else:
        if 16 in operand_sizes:
            operand_sizes.remove(16)

    # 3. REX Prefix (0100WRXB)
    if binary_code.startswith("0100"):
        binary_code = binary_code[4:]
        if binary_code[0] == "1":
            operand_sizes = [64]
        decoded_fields["Rex_R"] = binary_code[1]
        decoded_fields["Rex_X"] = binary_code[2]
        decoded_fields["Rex_B"] = binary_code[3]
        binary_code = binary_code[4:]
    else:
        if 64 in operand_sizes:
            operand_sizes.remove(64)

    # 4. Two-Byte Opcode Escape (0x0F)
    if binary_code.startswith("00001111"):
        binary_code = binary_code[8:]
        decoded_fields["OpCode"] = "00001111"

    # 5. Direct and Relative Jumps
    if binary_code.startswith("11101011") or binary_code.startswith("11101001"):
        target_disp_size = 8 if binary_code.startswith("11101011") else 32
        binary_code = binary_code[8:]
        return "jmp " + extract_displacement(target_disp_size)

    # 6. Conditional Jumps (Jcc)
    if binary_code.startswith("0111") or (
        decoded_fields["OpCode"] == "00001111" and binary_code.startswith("1000")
    ):
        target_disp_size = 8 if binary_code.startswith("0111") else 32
        condition_code = binary_code[4:8]
        binary_code = binary_code[8:]
        return "j" + CONDITION_CODE_MAP[condition_code] + " " + extract_displacement(target_disp_size)

    # 7. Call with relative displacement
    if binary_code.startswith("11101000"):
        binary_code = binary_code[8:]
        return "call " + extract_displacement(32)

    # 8. Return with immediate pop
    if binary_code.startswith("11000010"):
        binary_code = binary_code[8:]
        return "ret " + extract_displacement(16)

    # 9. Push / Pop Single Register
    if binary_code.startswith("0101"):
        direction_bit = binary_code[4]
        reg_code = binary_code[5:8]
        binary_code = binary_code[8:]
        operation_mnemonic = "push" if direction_bit == "0" else "pop"
        selected_size = 16 if 16 in operand_sizes else 64
        register_name = REGISTER_TABLE[selected_size][decoded_fields["Rex_B"] + reg_code]
        return f"{operation_mnemonic} {register_name}"

    # 10. Mov Register, Immediate (B0+r - BF)
    if binary_code.startswith("1011") and decoded_fields["OpCode"] == "":
        width_bit = binary_code[4]
        reg_code = binary_code[5:8]
        binary_code = binary_code[8:]
        if width_bit == "0":
            operand_sizes = [8]
        else:
            if 8 in operand_sizes:
                operand_sizes.remove(8)
        destination_register = REGISTER_TABLE[operand_sizes[0]][decoded_fields["Rex_B"] + reg_code]
        immediate_value = extract_displacement(operand_sizes[0])
        return f"mov {destination_register},{immediate_value}"

    # 11. Xchg with Accumulator (90+r)
    if binary_code.startswith("10010"):
        reg_code = binary_code[5:8]
        binary_code = binary_code[8:]
        if 8 in operand_sizes:
            operand_sizes.remove(8)
        first_register = REGISTER_TABLE[operand_sizes[0]][decoded_fields["Rex_B"] + reg_code]
        accumulator_register = REGISTER_TABLE[operand_sizes[0]]["0000"]
        return f"xchg {first_register},{accumulator_register}"

    # 12. Accumulator with Immediate
    if binary_code[:7] in ACCUMULATOR_OPCODE_TABLE:
        mnemonic = ACCUMULATOR_OPCODE_TABLE[binary_code[:7]]
        width_bit = binary_code[7]
        binary_code = binary_code[8:]
        if width_bit == "0":
            operand_sizes = [8]
        else:
            if 8 in operand_sizes:
                operand_sizes.remove(8)
        accumulator_register = REGISTER_TABLE[operand_sizes[0]]["0000"]
        immediate_value = extract_displacement(operand_sizes[0])
        return f"{mnemonic} {accumulator_register},{immediate_value}"

    # Helper for decoding memory operands via ModR/M and SIB
    def decode_memory_or_register_operand(is_rm_operand: bool = True) -> str:
        nonlocal binary_code, displacement_sizes
        mod = decoded_fields["Mod"]
        rm = decoded_fields["RM"]

        if mod == "11":
            return REGISTER_TABLE[operand_sizes[0]][decoded_fields["Rex_B"] + rm]

        # Memory operand
        if mod == "01":
            displacement_sizes = [8]
        elif mod == "10":
            displacement_sizes = [32]

        size_label = SIZE_IDENTIFIERS[operand_sizes[0]] + " PTR ["
        if rm == "100":
            # SIB byte present
            scale = binary_code[0:2]
            index = binary_code[2:5]
            base = binary_code[5:8]
            binary_code = binary_code[8:]

            if mod in ["01", "10"]:
                base_register = REGISTER_TABLE[address_sizes[0]][decoded_fields["Rex_B"] + base]
                size_label += base_register
                if not (index == "100" and decoded_fields["Rex_X"] == "0" and scale == "00"):
                    index_register = REGISTER_TABLE[address_sizes[0]][decoded_fields["Rex_X"] + index]
                    size_label += f"+{index_register}*{SCALE_MAP[scale]}"
                displacement_string = extract_displacement(displacement_sizes[0])
                size_label += f"+{displacement_string}]"
            else:
                # Mod == 00
                if base == "101":
                    displacement_sizes = [32]
                    if index != "100":
                        index_register = REGISTER_TABLE[address_sizes[0]][decoded_fields["Rex_X"] + index]
                        size_label += f"{index_register}*{SCALE_MAP[scale]}+{extract_displacement(32)}]"
                    else:
                        size_label += f"{extract_displacement(32)}]"
                else:
                    base_register = REGISTER_TABLE[address_sizes[0]][decoded_fields["Rex_B"] + base]
                    index_register = REGISTER_TABLE[address_sizes[0]][decoded_fields["Rex_X"] + index]
                    size_label += f"{base_register}+{index_register}*{SCALE_MAP[scale]}]"
            return size_label

        elif mod == "00" and rm == "101":
            # Pure displacement [disp32]
            return SIZE_IDENTIFIERS[operand_sizes[0]] + " PTR [" + extract_displacement(32) + "]"
        else:
            base_register = REGISTER_TABLE[address_sizes[0]][decoded_fields["Rex_B"] + rm]
            if mod in ["01", "10"]:
                displacement_string = extract_displacement(displacement_sizes[0])
                return f"{size_label}{base_register}+{displacement_string}]"
            return f"{size_label}{base_register}]"

    # 13. Two-Operand Instructions (ModR/M)
    is_two_op_std = binary_code[:6] in OPCODE_TWO_OPERAND_TABLE or binary_code[:6] == "100001"
    is_two_op_ext = (
        decoded_fields["OpCode"] == "00001111"
        and binary_code[:6] in EXTENDED_TWO_OPERAND_PREFIXES
    )

    if is_two_op_std or is_two_op_ext:
        decoded_fields["OpCode"] += binary_code[:6]
        decoded_fields["OpCode_D"] = binary_code[6]
        decoded_fields["OpCode_W"] = binary_code[7]

        if decoded_fields["OpCode"] == "100001":
            decoded_fields["OpCode"] += decoded_fields["OpCode_D"]
            decoded_fields["OpCode_D"] = "0"
        if decoded_fields["OpCode"] == "00001111101111":
            decoded_fields["OpCode"] += decoded_fields["OpCode_W"]
            decoded_fields["OpCode_W"] = "1"
            decoded_fields["OpCode_D"] = "1"

        if decoded_fields["OpCode_W"] == "0":
            operand_sizes = [8]
        else:
            if 8 in operand_sizes:
                operand_sizes.remove(8)

        binary_code = binary_code[8:]
        decoded_fields["Mod"] = binary_code[0:2]
        decoded_fields["Reg"] = binary_code[2:5]
        decoded_fields["RM"] = binary_code[5:8]
        binary_code = binary_code[8:]

        lookup_key = decoded_fields["OpCode"]
        mnemonic = OPCODE_TWO_OPERAND_TABLE[lookup_key]

        reg_operand = REGISTER_TABLE[operand_sizes[0]][decoded_fields["Rex_R"] + decoded_fields["Reg"]]
        rm_operand = decode_memory_or_register_operand()

        if decoded_fields["OpCode_D"] == "0":
            return f"{mnemonic} {rm_operand},{reg_operand}"
        return f"{mnemonic} {reg_operand},{rm_operand}"

    # 14. Immediate / Unary Instructions (ModR/M reg field as opcode extension)
    if binary_code[:6] in OPCODE_IMMEDIATE_TABLE:
        decoded_fields["OpCode"] = binary_code[:6]
        decoded_fields["OpCode_D"] = binary_code[6]
        decoded_fields["OpCode_W"] = binary_code[7]

        if decoded_fields["OpCode_W"] == "0":
            operand_sizes = [8]
        else:
            if 8 in operand_sizes:
                operand_sizes.remove(8)

        binary_code = binary_code[8:]
        decoded_fields["Mod"] = binary_code[0:2]
        decoded_fields["Reg"] = binary_code[2:5]
        decoded_fields["RM"] = binary_code[5:8]
        binary_code = binary_code[8:]

        mnemonic = OPCODE_IMMEDIATE_TABLE[decoded_fields["OpCode"]][decoded_fields["Reg"]]
        if mnemonic in ["jmp", "push", "pop", "call"]:
            if 16 not in operand_sizes:
                operand_sizes = [64]

        rm_operand = decode_memory_or_register_operand()

        # Immediate value or second operand formatting
        if len(binary_code) > 0:
            immediate_bit_size = 8 if (decoded_fields["OpCode_D"] == "1" and operand_sizes[0] != 8) else operand_sizes[0]
            immediate_string = extract_displacement(immediate_bit_size)
            return f"{mnemonic} {rm_operand},{immediate_string}"
        elif decoded_fields["OpCode"] == "110100":
            shift_count = "cl" if decoded_fields["OpCode_D"] == "1" else "1"
            return f"{mnemonic} {rm_operand},{shift_count}"
        return f"{mnemonic} {rm_operand}"

    return ""


# ------------------------------------------------------------------------------
# Command-Line Entry Point
# ------------------------------------------------------------------------------

def main() -> None:
    """CLI runner supporting stdin pipe, arguments, or batch file execution."""
    if len(sys.argv) > 1 and sys.argv[1] not in ["-f", "--file"]:
        # Direct machine code argument
        hex_code = sys.argv[1]
        print(disassemble(hex_code))
    elif len(sys.argv) > 2 and sys.argv[1] in ["-f", "--file"]:
        # Process input file with machine codes
        input_path = sys.argv[2]
        with open(input_path, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if line and not line.startswith(";"):
                    print(disassemble(line))
    else:
        # Standard input interactive / piped mode
        for line in sys.stdin:
            line = line.strip()
            if line:
                print(disassemble(line))


if __name__ == "__main__":
    main()
