"""Integration tests for Assembler and Disassembler CLI modes."""

import os
import subprocess
import sys
import tempfile
import unittest


class TestCommandLineInterface(unittest.TestCase):
    """Test CLI execution via arguments, stdin pipes, and file processing."""

    PYTHON_EXE = sys.executable

    def test_assembler_argument(self):
        """Test assembler with instruction passed as CLI argument."""
        result = subprocess.run(
            [self.PYTHON_EXE, "src/assembler.py", "mov rax, rbx"],
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual(result.stdout.strip(), "4889d8")

    def test_assembler_stdin_pipe(self):
        """Test assembler with instruction piped via stdin."""
        result = subprocess.run(
            [self.PYTHON_EXE, "src/assembler.py"],
            input="add eax, ecx\n",
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual(result.stdout.strip(), "01c8")

    def test_disassembler_argument(self):
        """Test disassembler with machine code passed as CLI argument."""
        result = subprocess.run(
            [self.PYTHON_EXE, "src/disassembler.py", "4889d8"],
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual(result.stdout.strip(), "mov rax,rbx")

    def test_disassembler_stdin_pipe(self):
        """Test disassembler with machine code piped via stdin."""
        result = subprocess.run(
            [self.PYTHON_EXE, "src/disassembler.py"],
            input="01c8\n",
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertEqual(result.stdout.strip(), "add eax,ecx")

    def test_assembler_file_mode(self):
        """Test batch file assembly."""
        with tempfile.NamedTemporaryFile("w+", delete=False) as temp_file:
            temp_file.write("stc\nclc\nret\n")
            temp_file_path = temp_file.name

        try:
            result = subprocess.run(
                [self.PYTHON_EXE, "src/assembler.py", "-f", temp_file_path],
                capture_output=True,
                text=True,
                check=True,
            )
            lines = result.stdout.strip().splitlines()
            self.assertEqual(lines, ["f9", "f8", "c3"])
        finally:
            if os.path.exists(temp_file_path):
                os.remove(temp_file_path)


if __name__ == "__main__":
    unittest.main()
