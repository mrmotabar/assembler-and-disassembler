"""Unit tests for the x86_64 NASM Assembler."""

import unittest
from src.assembler import assemble


class TestAssembler(unittest.TestCase):
    """Test suite for instruction assembly across formats and addressing modes."""

    def test_solo_instructions(self):
        """Verify zero-operand standalone instructions."""
        self.assertEqual(assemble("stc"), "f9")
        self.assertEqual(assemble("clc"), "f8")
        self.assertEqual(assemble("std"), "fd")
        self.assertEqual(assemble("cld"), "fc")
        self.assertEqual(assemble("syscall"), "0f05")
        self.assertEqual(assemble("ret"), "c3")

    def test_return_with_immediate(self):
        """Verify ret with 16-bit stack pop immediate."""
        self.assertEqual(assemble("ret 0x10"), "c21000")
        self.assertEqual(assemble("ret 0x8"), "c20800")

    def test_register_to_register_mov(self):
        """Verify mov between general purpose and extended registers."""
        # 64-bit with REX.W prefix (0x48)
        self.assertEqual(assemble("mov rax, rbx"), "4889d8")
        self.assertEqual(assemble("mov rbx, rcx"), "4889cb")
        # 32-bit (no prefix)
        self.assertEqual(assemble("mov eax, ebx"), "89d8")
        # 16-bit with operand size override prefix (0x66)
        self.assertEqual(assemble("mov ax, bx"), "6689d8")
        # 8-bit (OpCode_W = 0)
        self.assertEqual(assemble("mov al, bl"), "88d8")
        # Extended registers (r8-r15) requiring REX.R or REX.B
        self.assertEqual(assemble("mov r8, r9"), "4d89c8")
        self.assertEqual(assemble("mov r10d, r11d"), "4589da")
        self.assertEqual(assemble("mov r12w, r13w"), "664589ec")
        self.assertEqual(assemble("mov r14b, r15b"), "4588fe")

    def test_two_operand_arithmetic_and_logic(self):
        """Verify add, adc, sub, sbb, and, or, xor, cmp, test."""
        self.assertEqual(assemble("add eax, ecx"), "01c8")
        self.assertEqual(assemble("adc edx, esi"), "11f2")
        self.assertEqual(assemble("sub r8, r9"), "4d29c8")
        self.assertEqual(assemble("sbb eax, ebx"), "19d8")
        self.assertEqual(assemble("and rcx, rdx"), "4821d1")
        self.assertEqual(assemble("or edi, esi"), "09f7")
        self.assertEqual(assemble("xor edx, edx"), "31d2")
        self.assertEqual(assemble("cmp rax, rbx"), "4839d8")
        self.assertEqual(assemble("test rdx, rdx"), "4885d2")
        self.assertEqual(assemble("xchg rax, rbx"), "4887d8")
        self.assertEqual(assemble("xadd r8d, r9d"), "450fc3c8")

    def test_immediate_operands(self):
        """Verify immediate operands and accumulator shortcuts."""
        # Immediate add with small value (<= 127, sign-extended 8-bit)
        self.assertEqual(assemble("add eax, 0x5"), "83c005")
        self.assertEqual(assemble("add rbx, 0x10"), "4883c310")
        # Accumulator shortcut with large immediate (> 127)
        self.assertEqual(assemble("add rax, 0x12345678"), "480578563412")
        self.assertEqual(assemble("cmp al, 0x5"), "80f805")

    def test_memory_addressing_modes(self):
        """Verify direct, displacement, SIB, and scale addressing modes."""
        # Simple base memory operand
        self.assertEqual(assemble("mov rax, QWORD PTR [rbx]"), "488b03")
        self.assertEqual(assemble("mov QWORD PTR [rbx], rax"), "488903")

        # Base + 8-bit displacement
        self.assertEqual(assemble("mov edx, DWORD PTR [ebx+0x10]"), "678b5310")

        # Base + 32-bit displacement
        self.assertEqual(assemble("mov rax, QWORD PTR [rbx+0x12345678]"), "488b8378563412")

        # SIB: Base + Index * Scale
        self.assertEqual(assemble("mov edx, DWORD PTR [ebx+ecx*1]"), "678b140b")
        self.assertEqual(assemble("mov eax, DWORD PTR [ebx+ecx*2]"), "678b044b")
        self.assertEqual(assemble("mov eax, DWORD PTR [ebx+ecx*4]"), "678b048b")
        self.assertEqual(assemble("mov eax, DWORD PTR [ebx+ecx*8]"), "678b04cb")

        # SIB + Displacement
        self.assertEqual(
            assemble("mov edx, DWORD PTR [ebx+ecx*1+0x32345467]"),
            "678b940b67543432",
        )

        # Special base registers: rbp / ebp
        self.assertEqual(assemble("mov eax, DWORD PTR [ebp]"), "678b4500")

    def test_stack_operations(self):
        """Verify push and pop operations."""
        self.assertEqual(assemble("push rax"), "4850")
        self.assertEqual(assemble("push rbx"), "4853")
        self.assertEqual(assemble("push r12"), "4954")
        self.assertEqual(assemble("pop rcx"), "4859")
        self.assertEqual(assemble("pop r15"), "495f")
        self.assertEqual(assemble("push 0x10"), "6810")
        self.assertEqual(assemble("push 0x12345678"), "6878563412")

    def test_shifts_and_rotates(self):
        """Verify shl and shr operations."""
        self.assertEqual(assemble("shl rax, 1"), "48d1e0")
        self.assertEqual(assemble("shr edx, 0x4"), "c1ea04")

    def test_unary_arithmetic(self):
        """Verify inc, dec, neg, not, idiv, imul."""
        self.assertEqual(assemble("inc rax"), "48ffc0")
        self.assertEqual(assemble("dec ebx"), "ffcb")
        self.assertEqual(assemble("neg rax"), "48f7d8")
        self.assertEqual(assemble("not rbx"), "48f7d3")
        self.assertEqual(assemble("idiv ebx"), "f7fb")
        self.assertEqual(assemble("imul eax, ebx"), "0fafc3")

    def test_bit_scans(self):
        """Verify bsf and bsr bit scanning instructions."""
        self.assertEqual(assemble("bsf rax, rbx"), "480fbec3")
        self.assertEqual(assemble("bsr rcx, rdx"), "480fbfca")

    def test_control_flow(self):
        """Verify call, jmp, and conditional jumps."""
        self.assertEqual(assemble("call 0x12345678"), "e878563412")
        self.assertEqual(assemble("je 0x12345678"), "0f8478563412")
        self.assertEqual(assemble("jne 0x10"), "0f8510000000")
        self.assertEqual(assemble("jl 0x20"), "0f8c20000000")
        self.assertEqual(assemble("jg 0x30"), "0f8f30000000")


if __name__ == "__main__":
    unittest.main()
