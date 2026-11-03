# x86_64 Instruction Formats and Encoding Reference

This document describes the x86_64 NASM instruction encoding scheme implemented in both the Python and Assembly engines, based on Appendix B of the Intel 64 and IA-32 Architectures Software Developer’s Manual.

---

## 1. General Machine Instruction Format

Each x86_64 machine instruction follows the generalized structure:

```
+------------------+-------------------+-----------------+------------------+-------------------+--------------------+------------------+
| Legacy Prefixes  |    REX Prefix     |     Opcode      |      ModR/M      |        SIB        |    Displacement    |    Immediate     |
|  (0-4 bytes)     |     (1 byte)      |   (1-3 bytes)   |  (0 or 1 byte)   |   (0 or 1 byte)   |    (0-4 bytes)     |   (0-4 bytes)    |
+------------------+-------------------+-----------------+------------------+-------------------+--------------------+------------------+
```

---

## 2. Prefixes

### 2.1 Legacy Prefixes
- **Operand-Size Override (`0x66` / `01100110b`)**:
  Switches the default 32-bit operand size to 16 bits (e.g., `mov ax, bx`).
- **Address-Size Override (`0x67` / `01100111b`)**:
  Switches 64-bit address generation to 32 bits (e.g., `mov eax, DWORD PTR [ebx+ecx*1]`).

### 2.2 REX Prefix (`0100WRXBb`)
In 64-bit mode, the `0100` prefix byte enables 64-bit operand sizes and access to extended registers (`r8`-`r15`):

| Bit | Name | Description |
|:---:|:----:|:------------|
| 7-4 | `0100` | Fixed REX identification nibble (`0x4`). |
| 3   | `W`    | **64-bit Operand Size**: `1` = 64-bit operand, `0` = default size. |
| 2   | `R`    | **Reg Extension**: 4th bit (MSB) extending the ModR/M `reg` field (`r8`-`r15`). |
| 1   | `X`    | **Index Extension**: 4th bit (MSB) extending the SIB `index` field (`r8`-`r15`). |
| 0   | `B`    | **Base / RM Extension**: 4th bit (MSB) extending the ModR/M `r/m` or SIB `base` field. |

---

## 3. Opcode Fields

Most standard arithmetic and data transfer opcodes utilize bit 1 and bit 0 for direction and width:
- **`d` (Direction bit)**:
  - `0`: Register is the *source* operand; `r/m` is the *destination*.
  - `1`: Register is the *destination* operand; `r/m` is the *source*.
- **`w` (Width bit)**:
  - `0`: 8-bit operand size (e.g., `al`, `bl`, `cl`).
  - `1`: Full operand size (16-bit, 32-bit, or 64-bit).
- **`s` (Sign-extension bit)**:
  - In `100000sw` immediate forms, `s=1` indicates that an 8-bit immediate is sign-extended to the destination operand size.

---

## 4. ModR/M Byte

The ModR/M byte specifies addressing modes and register operands:

```
 7   6   5   4   3   2   1   0
+-------+-----------+-----------+
|  mod  |  reg/op   |    r/m    |
+-------+-----------+-----------+
```

- **`mod` (2 bits)**:
  - `00`: Memory addressing with no displacement (except `r/m=101`, which indicates 32-bit displacement).
  - `01`: Memory addressing with 8-bit sign-extended displacement.
  - `10`: Memory addressing with 32-bit displacement.
  - `11`: Register-direct addressing (`r/m` represents a register).
- **`reg/op` (3 bits)**:
  - Specifies either a register operand or an opcode extension (e.g., in unary or immediate operations).
- **`r/m` (3 bits)**:
  - Specifies the direct register or memory base register.
  - When `r/m == 100b` (`rsp`/`esp` encoding), the **SIB byte** follows.

---

## 5. SIB (Scale-Index-Base) Byte

When complex memory addressing is used (`[base+index*scale+disp]`), the SIB byte defines the index and scale:

```
 7   6   5   4   3   2   1   0
+-------+-----------+-----------+
| scale |   index   |   base    |
+-------+-----------+-----------+
```

- **`scale` (2 bits)**:
  - `00`: Scale ×1
  - `01`: Scale ×2
  - `10`: Scale ×4
  - `11`: Scale ×8
- **`index` (3 bits)**: Index register code (`rax`-`rdi`, extended with REX.X).
- **`base` (3 bits)**: Base register code (`rax`-`rdi`, extended with REX.B).

---

## 6. Displacement and Immediate Data

- All displacement and immediate numeric constants are encoded in **little-endian** byte order (least significant byte first).
- Hexadecimal constants in NASM assembly syntax start with `0x` (e.g., `0x12345678` encodes as `78 56 34 12`).
