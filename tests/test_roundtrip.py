"""Roundtrip tests verifying that assembling and disassembling produces identical instructions."""

import re
import unittest
from src.assembler import assemble
from src.disassembler import disassemble


def normalize_instruction(instruction: str) -> str:
    """Normalize whitespace and casing for comparing assembly instructions."""
    instruction = instruction.strip().lower()
    # Normalize comma spacing
    instruction = re.sub(r"\s*,\s*", ",", instruction)
    # Normalize multiple spaces
    instruction = re.sub(r"\s+", " ", instruction)
    # Normalize pointer keyword to uppercase
    for size in ["byte", "word", "dword", "qword"]:
        instruction = instruction.replace(f"{size} ptr", f"{size.upper()} PTR")
    # Normalize displacement 0x0 vs 0x00
    instruction = re.sub(r"\+0x0+\]", "+0x0]", instruction)
    return instruction


class TestRoundtrip(unittest.TestCase):
    """End-to-end roundtrip test suite: Instruction -> Assembly -> Disassembly -> Instruction."""

    ROUNDTRIP_INSTRUCTIONS = [
        # Solo Instructions
        "stc",
        "clc",
        "std",
        "cld",
        "syscall",
        "ret",
        "ret 0x10",
        # 64-bit Register-to-Register
        "mov rax, rbx",
        "mov rcx, rdx",
        "mov r8, r9",
        "mov r14, r15",
        "add rax, rbx",
        "sub r8, r9",
        "xor edx, edx",
        "cmp rax, rbx",
        "test rdx, rdx",
        "xchg rax, rbx",
        # 32-bit Register-to-Register
        "mov eax, ebx",
        "add eax, ecx",
        "sub edx, esi",
        "xor edi, edi",
        "cmp eax, edx",
        # 16-bit Register-to-Register
        "mov ax, bx",
        "add cx, dx",
        "xor si, di",
        # 8-bit Register-to-Register
        "mov al, bl",
        "add cl, dl",
        # Immediate Instructions
        "add eax, 0x5",
        "add rbx, 0x10",
        "cmp al, 0x5",
        # Unary Instructions
        "inc rax",
        "dec ebx",
        "neg rax",
        "not rbx",
        "idiv ebx",
        "imul eax, ebx",
        # Shift Instructions
        "shl rax, 1",
        "shr edx, 0x4",
        # Bit Scans
        "bsf rax, rbx",
        "bsr rcx, rdx",
        # Stack Operations
        "push rax",
        "push r12",
        "pop rcx",
        "pop r15",
        # Control Flow
        "call 0x12345678",
        "je 0x12345678",
        # Memory Addressing
        "mov rax, QWORD PTR [rbx]",
        "mov QWORD PTR [rbx], rax",
        "mov edx, DWORD PTR [ebx+0x10]",
        "mov edx, DWORD PTR [ebx+ecx*1+0x32345467]",
    ]

    def test_all_roundtrip_instructions(self):
        """Ensure all instructions survive assemble -> disassemble roundtrip."""
        for original in self.ROUNDTRIP_INSTRUCTIONS:
            with self.subTest(instruction=original):
                machine_code = assemble(original)
                self.assertTrue(
                    len(machine_code) > 0,
                    f"Assembler produced empty machine code for '{original}'",
                )
                disassembled = disassemble(machine_code)
                self.assertTrue(
                    len(disassembled) > 0,
                    f"Disassembler failed for '{original}' (code: {machine_code})",
                )
                norm_original = normalize_instruction(original)
                norm_disassembled = normalize_instruction(disassembled)
                self.assertEqual(
                    norm_original,
                    norm_disassembled,
                    f"Mismatch for '{original}': got '{disassembled}' (machine code: {machine_code})",
                )


if __name__ == "__main__":
    unittest.main()
