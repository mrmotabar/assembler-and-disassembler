"""Unit tests for the x86_64 NASM Disassembler."""

import unittest
from src.disassembler import disassemble


class TestDisassembler(unittest.TestCase):
    """Test suite for disassembling machine code into NASM syntax."""

    def test_solo_instructions(self):
        """Verify solo instruction disassembling."""
        self.assertEqual(disassemble("f9"), "stc")
        self.assertEqual(disassemble("f8"), "clc")
        self.assertEqual(disassemble("fd"), "std")
        self.assertEqual(disassemble("fc"), "cld")
        self.assertEqual(disassemble("0f05"), "syscall")
        self.assertEqual(disassemble("c3"), "ret")

    def test_return_immediate(self):
        """Verify return with stack pop immediate."""
        self.assertEqual(disassemble("c21000"), "ret 0x10")

    def test_register_mov(self):
        """Verify mov between registers."""
        self.assertEqual(disassemble("4889d8"), "mov rax,rbx")
        self.assertEqual(disassemble("89d8"), "mov eax,ebx")
        self.assertEqual(disassemble("6689d8"), "mov ax,bx")
        self.assertEqual(disassemble("88d8"), "mov al,bl")
        self.assertEqual(disassemble("4d89c8"), "mov r8,r9")
        self.assertEqual(disassemble("4589da"), "mov r10d,r11d")

    def test_arithmetic_and_logic(self):
        """Verify arithmetic instructions."""
        self.assertEqual(disassemble("01c8"), "add eax,ecx")
        self.assertEqual(disassemble("4d29c8"), "sub r8,r9")
        self.assertEqual(disassemble("31d2"), "xor edx,edx")
        self.assertEqual(disassemble("4885d2"), "test rdx,rdx")
        self.assertEqual(disassemble("4887d8"), "xchg rax,rbx")
        self.assertEqual(disassemble("83c005"), "add eax,0x5")
        self.assertEqual(disassemble("80f805"), "cmp al,0x5")

    def test_memory_addressing(self):
        """Verify memory operands and addressing modes."""
        self.assertEqual(disassemble("488b03"), "mov rax,QWORD PTR [rbx]")
        self.assertEqual(disassemble("488903"), "mov QWORD PTR [rbx],rax")
        self.assertEqual(disassemble("678b5310"), "mov edx,DWORD PTR [ebx+0x10]")
        self.assertEqual(
            disassemble("678b940b67543432"),
            "mov edx,DWORD PTR [ebx+ecx*1+0x32345467]",
        )
        self.assertEqual(disassemble("678b4500"), "mov eax,DWORD PTR [ebp+0x0]")

    def test_stack_operations(self):
        """Verify push and pop instructions."""
        self.assertEqual(disassemble("4850"), "push rax")
        self.assertEqual(disassemble("4859"), "pop rcx")
        self.assertEqual(disassemble("4954"), "push r12")
        self.assertEqual(disassemble("495f"), "pop r15")

    def test_unary_and_shifts(self):
        """Verify inc, dec, neg, not, idiv, imul, and shifts."""
        self.assertEqual(disassemble("48ffc0"), "inc rax")
        self.assertEqual(disassemble("ffcb"), "dec ebx")
        self.assertEqual(disassemble("48f7d8"), "neg rax")
        self.assertEqual(disassemble("48f7d3"), "not rbx")
        self.assertEqual(disassemble("f7fb"), "idiv ebx")
        self.assertEqual(disassemble("0fafc3"), "imul eax,ebx")
        self.assertEqual(disassemble("48d1e0"), "shl rax,1")
        self.assertEqual(disassemble("c1ea04"), "shr edx,0x4")

    def test_bit_scans(self):
        """Verify bit scan instructions."""
        self.assertEqual(disassemble("480fbec3"), "bsf rax,rbx")
        self.assertEqual(disassemble("480fbfca"), "bsr rcx,rdx")

    def test_jumps_and_calls(self):
        """Verify call, jmp, and conditional jumps."""
        self.assertEqual(disassemble("e878563412"), "call 0x12345678")
        self.assertEqual(disassemble("0f8478563412"), "je 0x12345678")


if __name__ == "__main__":
    unittest.main()
