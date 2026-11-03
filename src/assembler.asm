; ==============================================================================
; File: assembler.asm
; Description: x86_64 NASM Assembler implementation in x86_64 Assembly.
;              Reads NASM x86 assembly instructions from an input file,
;              encodes them into binary bitstrings (first-file.txt)
;              and hexadecimal machine code (second-file.txt).
; Architecture: x86_64 (Linux ELF64 ABI)
; Author: MohammadReza Motabar
; ==============================================================================
%ifndef ASSEMBLER_ASM
%define ASSEMBLER_ASM

%include "system-constants.asm"
%include "console-io.asm"


section .data
    map_bin_to_hex db "0123456789ABCDEF"
    one dq 1
    four dq 4
    ten dq 10
    sixteen dq 16
    space db " "
    newline_char db 10

    d00 db "00", 0
    d01 db "01", 0
    d10 db "10", 0
    d11 db "11", 0

    d000 db "000", 0
    d001 db "001", 0
    d010 db "010", 0
    d011 db "011", 0
    d100 db "100", 0
    d101 db "101", 0
    d110 db "110", 0
    d111 db "111", 0

    d0000 dq "0000", 0
    d0100 db "0100", 0
    d1000 db "1000", 0
    d1011 db "1011", 0

    d01010 db "01010", 0
    d01011 db "01011", 0

    d000000 db "000000", 0
    d000001 db "000001", 0
    d000010 db "000010", 0
    d000011 db "000011", 0
    d000100 db "000100", 0
    d000101 db "000101", 0
    d000110 db "000110", 0
    d000111 db "000111", 0
    d001000 db "001000", 0
    d001001 db "001001", 0
    d001010 db "001010", 0
    d001011 db "001011", 0
    d001100 db "001100", 0
    d001101 db "001101", 0
    d001110 db "001110", 0
    d001111 db "001111", 0
    d011010 db "011010", 0
    d100000 db "100000", 0
    d100001 db "100001", 0
    d100010 db "100010", 0
    d100011 db "100011", 0
    d101010 db "101010", 0
    d101011 db "101011", 0
    d101111 db "101111", 0
    d110000 db "110000", 0
    d110001 db "110001", 0
    d110100 db "110100", 0
    d111101 db "111101", 0
    d111111 db "111111", 0

    d00000000 db "00000000", 0
    d00001111 db "00001111", 0
    d11000010 db "11000010", 0
    d11101000 db "11101000", 0
    
    number_of_operands dq 0

    solo_instruction_table db "stc:11111001 clc:11111000 std:11111101 cld:11111100 syscall:0000111100000101 ret:11000011 ", 0

    register_table db "r10b:010 r11b:011 r12b:100 r13b:101 r14b:110 r15b:111 r10w:010 r11w:011 r12w:100 r13w:101 r14w:110 r15w:111 "
                   db "r10d:010 r11d:011 r12d:100 r13d:101 r14d:110 r15d:111 "
                   db "r10:010 r11:011 r12:100 r13:101 r14:110 r15:111 "
                   db "r8b:000 r9b:001 "
                   db "r8w:000 r9w:001 "
                   db "r8d:000 r9d:001 "
                   db "rax:000 rcx:001 rdx:010 rbx:011 rsp:100 rbp:101 rsi:110 rdi:111 "
                   db "eax:000 ecx:001 edx:010 ebx:011 esp:100 ebp:101 esi:110 edi:111 "
                   db "ax:000 cx:001 dx:010 bx:011 sp:100 bp:101 si:110 di:111 "
                   db "al:000 cl:001 dl:010 bl:011 ah:100 ch:101 dh:110 bh:111 "
                   db "r8:000 r9:001 null_indicator:101 ", 0
    scale_map db "1:00 2:01 4:10 8:11 ", 0
    condition_code_table db "o:0000 no:0001 b:0010 nae:0010 nb:0011 ae:0011 e:0100 z:0100 ne:0101 nz:0101 "
         db "be:0110 na:0110 nbe:0111 a:0111 s:1000 ns:1001 p:1010 pe:1010 np:1011 po:1011 "
         db "l:1100 nge:1100 nl:1101 ge:1101 le:1110 ng:1110 nle:1111 g:1111 ", 0

    registers_64 db "rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15 ", 0
    registers_32 db "eax ecx edx ebx esp ebp esi edi r8d r9d r10d r11d r12d r13d r14d r15d ", 0
    registers_16 db "ax cx dx bx sp bp si di r8w r9w r10w r11w r12w r13w r14w r15w ", 0
    registers_8 db "al cl dl bl ah ch dh bh r8b r9b r10b r11b r12b r13b r14b r15b ", 0 

    extended_registers db "r8 r8d r8w r8b r9 r9d r9w r9b r10 r10d r10w r10b r11 r11d r11w r11b "
                 db "r12 r12d r12w r12b r13 r13d r13w r13b r14 r14d r14w r14b r15 r15d r15w r15b ", 0

    base_registers_exception db "rbp ebp bp ch", 0
    accumulator_registers db "rax eax ax al", 0

    null_indicator db "null_indicator ", 0

    operand_size dq 0
    address_size dq 0
    displacement_size dq 0
    displacement_value dq 0
    immediate_size dq 0
    immediate_value dq 0

    prefix_66 db "01100110", 0
    prefix_67 db "01100111", 0

    has_address_override db 0
    has_operand_override db 0
    has_rex_prefix db 0
    has_extended_opcode db 0

    mnemonic_mov db "mov ", 0
    mnemonic_add db "add ", 0
    mnemonic_adc db "adc ", 0
    mnemonic_sub db "sub ", 0
    mnemonic_sbb db "sbb ", 0
    mnemonic_and db "and ", 0
    mnemonic_or db "or ", 0
    mnemonic_xor db "xor ", 0
    mnemonic_dec db "dec ", 0
    mnemonic_inc db "inc ", 0
    mnemonic_cmp db "cmp ", 0
    mnemonic_test db "test ", 0
    mnemonic_xchg db "xchg ", 0
    mnemonic_xadd db "xadd ", 0
    mnemonic_imul db "imul ", 0
    mnemonic_idiv db "idiv ", 0
    mnemonic_bsf db "bsf ", 0
    mnemonic_bsr db "bsr ", 0
    mnemonic_jmp db "jmp ", 0
    mnemonic_shl db "shl ", 0
    mnemonic_shr db "shr ", 0
    mnemonic_neg db "neg ", 0
    mnemonic_not db "not ", 0
    mnemonic_call db "call ", 0
    mnemonic_ret db "ret ", 0
    mnemonic_push db "push ", 0
    mnemonic_pop  db "pop ", 0

    line_length dq 0

    source_file_descriptor dq 0
    dest_binary_file_descriptor dq 0
    dest_hex_file_descriptor dq 0
    dest_binary_filename db "first-file.txt", 0
    dest_hex_filename db "second-file.txt", 0
section .bss
    line resb 100
    token_buffer resb 50
    scratch_buffer_1 resb 50
    scratch_buffer_2 resb 50
    instruction resb 10
    result resb 100

    operand resb 50
    operand_0 resb 50
    operand_1 resb 50

    rex_pre resb 4
    rex_w resb 1
    rex_r resb 1
    rex_x resb 1
    rex_b resb 1
    rex_end resb 1
    extended_opcode resb 8
    extended_opcode_end resb 1
    opcode resb 6
    opcode_direction resb 1
    opcode_width resb 1
    opcode_end resb 1
    modrm_mod resb 2
    modrm_reg resb 3
    modrm_rm resb 3
    modrm_end resb 1
    sib_scale resb 2
    sib_index resb 3
    sib_base resb 3
    sib_end resb 1
    displacement_field resb 32
    displacement_field_end resb 1
    data_field resb 64
    data_field_end resb 1

    source_filepath resb 100

section .text
    default rel
    global _start

; ==============================================================================
; Macro Definitions: Assembler Engine
; ==============================================================================

; ------------------------------------------------------------------------------
; Macro: debug
; Description: Prints a 64-bit integer value followed by a newline to standard
;              output. Useful for debugging register states.
; Arguments:
;   %1 - 64-bit integer, register, or memory operand to print.
; Preserves: RAX
; ------------------------------------------------------------------------------
%macro debug 1
    push rax
    mov rax, %1
    call writeNum
    call newLine
    pop rax
%endmacro

; ------------------------------------------------------------------------------
; Macro: write_char
; Description: Stores a single ASCII character byte into a destination memory
;              buffer and automatically increments the destination pointer register.
; Arguments:
;   %1 - Register pointing to the destination buffer (incremented by 1).
;   %2 - Character literal or byte register to write.
; ------------------------------------------------------------------------------
%macro write_char 2
    mov byte[%1], %2
    inc %1
%endmacro

; ------------------------------------------------------------------------------
; Macro: find_char
; Description: Scans a null-terminated string for the first occurrence of a specific
;              character byte.
; Arguments:
;   %1 - Pointer to the null-terminated search string.
;   %2 - Character byte literal or register containing the character to search for.
; Returns:
;   RAX - Pointer to the matching character in the string, or -1 if not found.
; Preserves: R8, R9
; ------------------------------------------------------------------------------
%macro find_char 2
    push r8
    push r9
    mov r8, %1
    mov r9b, %2
%%L1:
    cmp byte[r8], 0
    je %%notFound
    cmp byte[r8], r9b
    je %%Found
    inc r8
    jmp %%L1
%%notFound:
    mov rax, -1
    jmp %%end
%%Found:
    mov rax, r8
    jmp %%end
%%end:
    pop r9
    pop r8
%endmacro

; ------------------------------------------------------------------------------
; Macro: replace_char
; Description: Traverses a null-terminated string, replaces all occurrences of a
;              target character with a new replacement character, and counts replacements.
; Arguments:
;   %1 - Pointer to null-terminated string.
;   %2 - Old character byte to replace.
;   %3 - New replacement character byte.
;   %4 - Destination register to receive the total number of replacements performed.
; Preserves: R8
; ------------------------------------------------------------------------------
%macro replace_char 4
    push r8
    mov r8, %1
    mov %4, 0
%%L1:
    cmp byte[r8], 0
    je %%end
    cmp byte[r8], %2
    je %%changeIt
    inc r8
    jmp %%L1
%%changeIt:
    inc %4
    mov byte[r8], %3
    inc r8
    jmp %%L1
%%end:
    pop r8
%endmacro

; ------------------------------------------------------------------------------
; Macro: zero_buffer
; Description: Fills a memory buffer with zeroes for a specified number of bytes.
; Arguments:
;   %1 - Pointer to the destination buffer.
;   %2 - Number of bytes to zero out.
; Preserves: R8, R9
; ------------------------------------------------------------------------------
%macro zero_buffer 2
    push r8
    push r9
    mov r8, %1
    mov r9, 0
%%L1:
    cmp r9, %2
    je %%L1F
    mov byte[r8], 0
    inc r8
    inc r9
    jmp %%L1
%%L1F:
    pop r9
    pop r8
%endmacro

; ------------------------------------------------------------------------------
; Macro: get_register_size
; Description: Determines the width in bits (64, 32, 16, or 8) of a given register
;              mnemonic by checking membership against register class tables.
; Arguments:
;   %1 - Pointer to register mnemonic string (e.g. 'rax', 'ecx', 'al').
;   %2 - Destination register to receive bit size (64, 32, 16, 8).
; Preserves: R8, R9, R10, R11
; ------------------------------------------------------------------------------
%macro get_register_size 2
    push r8
    push r9
    push r10
    push r11

    mov r8, 64
    mov r9, 32
    mov r10, 16
    mov r11, 8
    push %1
    push registers_64
    call check_token_membership
    cmovc %2, r8
    jc %%end
    push %1
    push registers_32
    call check_token_membership
    cmovc %2, r9
    jc %%end
    push %1
    push registers_16
    call check_token_membership
    cmovc %2, r10
    jc %%end
    push %1
    push registers_8
    call check_token_membership
    cmovc %2, r11
%%end:
    pop r11
    pop r10
    pop r9
    pop r8
%endmacro

; ------------------------------------------------------------------------------
; Macro: check_address_size
; Description: Analyzes a parsed memory operand to determine:
;              1. Address bus width (32 or 64 bits) based on base/index registers.
;              2. Displacement magnitude and required size (8 or 32 bits).
; Arguments:
;   %1 - Pointer to parsed memory operand token buffer.
; Outputs:
;   Updates global variables: [address_size], [displacement_size], [displacement_value].
; ------------------------------------------------------------------------------
%macro check_address_size 1
    cmp byte[%1], "Q"
    je %%itIsMem
    cmp byte[%1], "D"
    je %%itIsMem 
    cmp byte[%1], "W"
    je %%itIsMem 
    cmp byte[%1], "B"
    je %%itIsMem 
    jmp %%end
%%itIsMem:
    mov r12, 0
    push qword 2
    push %1
    push token_buffer
    call extract_token_by_index
    cmp byte[token_buffer], "n"
    je %%tryIndex
    get_register_size token_buffer, r12
%%tryIndex:
    push qword 3
    push %1
    push token_buffer
    call extract_token_by_index
    cmp byte[token_buffer], "n"
    je %%endAdSz
    get_register_size token_buffer, r12
%%endAdSz:
    mov [address_size], r12
    push qword 5
    push %1
    push token_buffer
    call extract_token_by_index
    cmp byte[token_buffer], "n"
    je %%end
    mov r12, 0
    push r13
    push r14
    push rax
    mov rax, 0
    mov r14, 0
    mov r13, token_buffer
%%L1:
    cmp byte[r13], " "
    je %%L1F
    cmp byte[r13], 0
    je %%L1F
    mov r14b, byte[r13]
    cmp r14b, 65
    jge %%itsLetter
    sub r14b, "0"
%%L1_continue:
    mul qword[sixteen]
    add rax, r14
    inc r13
    jmp %%L1
%%itsLetter:
    sub r14b, "A"
    add r14b, 10
    jmp %%L1_continue
%%L1F:
    mov [displacement_value], rax
    cmp rax, 127
    jg %%disIs32
    mov qword[displacement_size], 8
    pop rax
    pop r14
    pop r13
    jmp %%end
%%disIs32:
    mov qword[displacement_size], 32
    pop rax
    pop r14
    pop r13
    jmp %%end

%%end:
%endmacro

; ------------------------------------------------------------------------------
; Macro: lookup_dict
; Description: Looks up a key in a space-separated 'key:value' table and copies
;              the corresponding value into the destination buffer (wrapper for
;              lookup_dictionary_value).
; Arguments:
;   %1 - Pointer to search key string.
;   %2 - Pointer to key:value dictionary string ("k1:v1 k2:v2 ...").
;   %3 - Pointer to destination buffer for extracted value.
; ------------------------------------------------------------------------------
%macro lookup_dict 3
    push %1
    push %2
    push %3
    call lookup_dictionary_value
%endmacro

; ------------------------------------------------------------------------------
; Macro: check_member
; Description: Tests whether a token exists in a space-delimited list of valid
;              tokens (wrapper for check_token_membership).
; Arguments:
;   %1 - Pointer to search token string.
;   %2 - Pointer to space-separated token list.
; Returns:
;   Carry Flag (CF) = 1 if token is found, 0 if not found.
; ------------------------------------------------------------------------------
%macro check_member 2
    push %1
    push %2
    call check_token_membership
%endmacro

; ------------------------------------------------------------------------------
; Macro: copy_str
; Description: Copies characters from source to destination until space, null,
;              or ']' delimiter is encountered (wrapper for copy_string_until_delimiter).
; Arguments:
;   %1 - Pointer to source string.
;   %2 - Pointer to destination buffer.
; ------------------------------------------------------------------------------
%macro copy_str 2
    push %1
    push %2
    call copy_string_until_delimiter
%endmacro

; ------------------------------------------------------------------------------
; Macro: append_str
; Description: Appends characters from source to destination without adding a
;              null terminator (wrapper for append_string_characters).
; Arguments:
;   %1 - Pointer to source string.
;   %2 - Pointer to destination buffer.
; ------------------------------------------------------------------------------
%macro append_str 2
    push %1
    push %2
    call append_string_characters
%endmacro

; ------------------------------------------------------------------------------
; Macro: copy_null_str
; Description: Copies string until null terminator and guarantees destination buffer
;              is null-terminated (wrapper for copy_string_with_null).
; Arguments:
;   %1 - Pointer to source string.
;   %2 - Pointer to destination buffer.
; ------------------------------------------------------------------------------
%macro copy_null_str 2
    push %1
    push %2
    call copy_string_with_null
%endmacro

; ------------------------------------------------------------------------------
; Macro: get_token
; Description: Extracts the N-th space-delimited token from a string into a
;              destination buffer (wrapper for extract_token_by_index).
; Arguments:
;   %1 - 0-based token index (quadword integer).
;   %2 - Pointer to source string.
;   %3 - Pointer to destination buffer.
; ------------------------------------------------------------------------------
%macro get_token 3
    push %1
    push %2
    push %3
    call extract_token_by_index
%endmacro

; ------------------------------------------------------------------------------
; Macro: normalize_bin
; Description: Formats an integer or hexadecimal value into a little-endian binary
;              bitstring of specified bit size (wrapper for normalize_value_to_binary).
; Arguments:
;   %1 - Numeric value (quadword).
;   %2 - Target bit width (8, 16, or 32).
;   %3 - Pointer to destination buffer.
; ------------------------------------------------------------------------------
%macro normalize_bin 3
    push %1
    push %2
    push %3
    call normalize_value_to_binary
%endmacro

; ------------------------------------------------------------------------------
; Macro: bin_to_hex
; Description: Converts an ASCII binary bitstring into an ASCII hexadecimal string,
;              processing 4 bits per hex character (wrapper for convert_binary_to_hex).
; Arguments:
;   %1 - Pointer to binary bitstring.
;   %2 - Pointer to destination buffer for hexadecimal output.
; ------------------------------------------------------------------------------
%macro bin_to_hex 2
    push %1
    push %2
    call convert_binary_to_hex
%endmacro
;
read_filepath_from_stdin:
    push    r8
    push    rax
    mov     r8, source_filepath
read_filepath_loop:
    call    getc
    cmp     al, NL
    je      read_filepath_done
    mov     [r8], al
    inc     r8
    jmp     read_filepath_loop
read_filepath_done:
    mov     byte[r8], 0
    pop     rax
    pop     r8
    ret
; ------------------------------------------------------------------------------
; Routine: lookup_dictionary_value
; Description: Looks up a key in a space-separated key:value lookup table
;              and extracts the corresponding value into the destination buffer.
;              (Emulates Python dictionary lookup: value = table[key]).
; Stack Inputs:
;   [rbp + 32] - Pointer to search key string
;   [rbp + 24] - Pointer to key:value dictionary string (e.g. "k1:v1 k2:v2")
;   [rbp + 16] - Pointer to destination buffer for extracted value
; Outputs:
;   Extracted value written to [rbp + 16] (null-terminated)
;   R15 - Pointer to end of written value
; Preserves: R8, R9, R10, R11
; ------------------------------------------------------------------------------
lookup_dictionary_value:
    enter 0, 0
    push r8
    push r9
    push r10
    push r11

    mov r8, [rbp + 32]
    mov r9, [rbp + 24]
    mov r10, [rbp + 16]

lookup_find_key:
    cmp byte[r9], ":"
    je lookup_check_key_match
    mov r11b, [r9]
    cmp r11b, [r8]
    jne lookup_skip_entry
    inc r8
    inc r9
    jmp lookup_find_key
lookup_check_key_match:
    cmp byte[r8], " "
    je lookup_copy_value
    cmp byte[r8], 0
    je lookup_copy_value
    jmp lookup_skip_entry
lookup_skip_entry:
    inc r9
    mov r11b, [r9 - 1]
    cmp r11b, " "
    mov r8, [rbp + 32]
    je lookup_find_key
    jmp lookup_skip_entry

lookup_copy_value:
    inc r9
    cmp byte[r9], 0
    je lookup_done
    cmp byte[r9], " "
    je lookup_done
    mov r11b, byte[r9]
    mov byte[r10], r11b
    inc r10
    jmp lookup_copy_value

lookup_done:
    mov byte[r10], 0
    mov r15, r10
    pop r11
    pop r10
    pop r9
    pop r8
    leave 
    ret 24

; ------------------------------------------------------------------------------
; Routine: check_token_membership
; Description: Checks whether a given word/token exists in a space-separated
;              list of valid words. (Emulates Python membership: token in table).
; Stack Inputs:
;   [rbp + 24] - Pointer to search token string
;   [rbp + 16] - Pointer to space-separated token list string
; Returns:
;   CF = 1 (Carry Flag set) if token is found
;   CF = 0 (Carry Flag cleared) if token is not found
; Preserves: R8, R9, R10
; ------------------------------------------------------------------------------
check_token_membership: 
    enter 0, 0
    push r8
    push r9
    push r10

    mov r8, [rbp + 24]
    mov r9, [rbp + 16]
    clc
membership_search_loop:
    cmp byte[r9], " "
    je membership_check_token_match
    cmp byte[r9], 0
    je membership_done
    mov r10b, [r9]
    cmp [r8], r10b
    jne membership_skip_token
    inc r9
    inc r8
    jmp membership_search_loop
membership_skip_token:
    inc r9
    mov r10b, [r9 - 1]
    cmp r10b, " "
    mov r8, [rbp + 24]
    je membership_search_loop
    jmp membership_skip_token
membership_check_token_match:
    cmp byte[r8], " "
    je membership_token_found
    cmp byte[r8], 0
    je membership_token_found
    inc r9
    mov r8, [rbp + 24]
    jmp membership_search_loop
membership_token_found:
    stc
membership_done:
    pop r10
    pop r9
    pop r8
    leave
    ret 16


; ------------------------------------------------------------------------------
; Routine: copy_string_until_delimiter
; Description: Copies a string from source to destination up to the first space,
;              null terminator, or closing bracket ']', then appends a null terminator.
; Stack Inputs:
;   [rbp + 24] - Pointer to source string
;   [rbp + 16] - Pointer to destination buffer
; Outputs:
;   Null-terminated string copied to destination buffer
;   R14 - Pointer to end of source string
;   R15 - Pointer to end of destination string
; Preserves: R8, R9, R10
; ------------------------------------------------------------------------------
copy_string_until_delimiter:
    enter 0, 0
    push r8
    push r9
    push r10

    mov r8, [rbp + 24]
    mov r9, [rbp + 16]
copy_delimited_loop:
    mov r10b, [r8]
    cmp r10b, 0
    je copy_delimited_done
    cmp r10b, " "
    je copy_delimited_done
    cmp r10b, "]"
    je copy_delimited_done
    mov [r9], r10b
    inc r8
    inc r9
    jmp copy_delimited_loop

copy_delimited_done:
    mov byte[r9], 0
    mov r14, r8
    mov r15, r9
    pop r10
    pop r9
    pop r8
    leave
    ret 16
; ------------------------------------------------------------------------------
; Routine: append_string_characters
; Description: Appends characters from source to destination without adding a
;              null terminator. Used for concatenating binary bit fields.
; Stack Inputs:
;   [rbp + 24] - Pointer to source string
;   [rbp + 16] - Pointer to destination buffer
; Outputs:
;   Characters copied to destination buffer (no trailing zero)
;   R14 - Pointer to end of source string
;   R15 - Pointer to end of destination string
; Preserves: R8, R9, R10
; ------------------------------------------------------------------------------
append_string_characters:
    enter 0, 0
    push r8
    push r9
    push r10

    mov r8, [rbp + 24]
    mov r9, [rbp + 16]
append_characters_loop:
    mov r10b, [r8]
    cmp r10b, 0
    je append_characters_done
    cmp r10b, " "
    je append_characters_done
    cmp r10b, "]"
    je append_characters_done
    mov [r9], r10b
    inc r8
    inc r9
    jmp append_characters_loop

append_characters_done:
    mov r14, r8
    mov r15, r9
    pop r10
    pop r9
    pop r8
    leave
    ret 16
; ------------------------------------------------------------------------------
; Routine: copy_string_with_null
; Description: Copies a string until null terminator and ensures destination
;              is null-terminated.
; Stack Inputs:
;   [rbp + 24] - Pointer to source string
;   [rbp + 16] - Pointer to destination buffer
; Preserves: R8, R9, R10
; ------------------------------------------------------------------------------
copy_string_with_null:
    enter 0, 0
    push r8
    push r9
    push r10

    mov r8, [rbp + 24]
    mov r9, [rbp + 16]
copy_null_terminated_loop:
    mov r10b, [r8]
    cmp r10b, 0
    je copy_null_terminated_done
    mov [r9], r10b
    inc r8
    inc r9
    jmp copy_null_terminated_loop

copy_null_terminated_done:
    mov byte[r9], 0
    mov r14, r8
    mov r15, r9
    pop r10
    pop r9
    pop r8
    leave
    ret 16
; ------------------------------------------------------------------------------
; Routine: convert_binary_to_hex
; Description: Converts a binary ASCII bitstring (e.g. "01001000") into a
;              hexadecimal ASCII string (e.g. "48"). Processes 4 bits per hex digit.
; Stack Inputs:
;   [rbp + 24] - Pointer to null-terminated binary bitstring
;   [rbp + 16] - Pointer to destination buffer for hexadecimal output
; Outputs:
;   Null-terminated hexadecimal string written to destination
; Preserves: RAX, RBX, R8, R9, R10
; ------------------------------------------------------------------------------
convert_binary_to_hex: 
    enter 0, 0
    push rax
    push rbx
    push r8
    push r9
    push r10

    mov r8, [rbp + 24]
    mov r9, [rbp + 16]
    mov r10, 2
convert_bin_to_hex_loop:
    cmp byte[r8], 0
    je convert_bin_to_hex_done
    mov rax, 0
    mul r10
    mov rbx,0
    cmp byte[r8], "1"
    cmove rbx, qword [one]
    add rax, rbx
    inc r8
    mul r10
    mov rbx,0
    cmp byte[r8], "1"
    cmove rbx, qword [one]
    add rax, rbx
    inc r8
    mul r10
    mov rbx,0
    cmp byte[r8], "1"
    cmove rbx, qword [one]
    add rax, rbx
    inc r8
    mul r10
    mov rbx,0
    cmp byte[r8], "1"
    cmove rbx, qword [one]
    add rax, rbx
    inc r8
    add rax, map_bin_to_hex
    mov bl, [rax]
    mov [r9], bl
    inc r9
    jmp convert_bin_to_hex_loop
convert_bin_to_hex_done:
    mov byte[r9], 0
    pop r10
    pop r9
    pop r8
    pop rbx
    pop rax
    leave
    ret 16


; ------------------------------------------------------------------------------
; Routine: extract_token_by_index
; Description: Extracts the N-th space-delimited token from a string.
;              (Emulates Python string split and sib_index: token = string.split()[N]).
; Stack Inputs:
;   [rbp + 32] - 0-based token sib_index N
;   [rbp + 24] - Pointer to input string
;   [rbp + 16] - Pointer to destination buffer for extracted token
; Outputs:
;   Extracted token copied into destination buffer (null-terminated)
; Preserves: R8, R9, R10
; ------------------------------------------------------------------------------
extract_token_by_index:
    enter 0, 0
    push r8
    push r9
    push r10

    mov r8, [rbp + 32]
    mov r9, [rbp + 24]
    mov r10, [rbp + 16]

extract_token_loop:
    cmp r8, 0
    je extract_token_copy
extract_token_find_space:
    cmp byte[r9], " "
    je extract_token_next
    inc r9
    jmp extract_token_find_space
extract_token_next:
    dec r8
    inc r9
    jmp extract_token_loop
extract_token_copy:
    copy_str r9, r10
    pop r10
    pop r9
    pop r8
    leave
    ret 24
; ------------------------------------------------------------------------------
; Routine: parse_operand
; Description: Parses an operand token string into components:
;              identifies memory specifiers (size, sib_base, sib_index, sib_scale, displacement),
;              registers, or numeric immediate constants.
; Stack Inputs:
;   [rbp + 16] - Pointer to destination buffer for parsed operand
; ------------------------------------------------------------------------------
parse_operand:
    enter 0, 0
    push r8
    mov r8, [rbp + 16]
    cmp byte[operand], "Q"
    je parse_operand_memory
    cmp byte[operand], "D"
    je parse_operand_memory
    cmp byte[operand], "W"
    je parse_operand_memory
    cmp byte[operand], "B"
    je parse_operand_memory
    cmp byte[operand], "0"
    jl parse_operand_register
    cmp byte[operand], "9"
    jg parse_operand_register
parse_operand_immediate:
    push rax
    push r9
    push r10
    mov rax, 0
    mov r9, 0
    mov r10, operand
    cmp byte[r10], "0"
    jne parse_op_imm_decimal_loop
    cmp byte[r10 + 1], "x"
    je parse_op_imm_hex
    cmp byte[r10 + 1], "X"
    je parse_op_imm_hex
    jmp parse_op_imm_decimal_loop

parse_op_imm_hex:
    add r10, 2
parse_op_imm_hex_loop:
    cmp byte[r10], 0
    je parse_operand_immediate_done
    cmp byte[r10], " "
    je parse_operand_immediate_done
    mov r9b, byte[r10]
    cmp r9b, "0"
    jl parse_operand_immediate_done
    cmp r9b, "9"
    jle parse_op_imm_hex_digit
    cmp r9b, "a"
    jl parse_op_imm_check_upper
    cmp r9b, "f"
    jg parse_operand_immediate_done
    sub r9b, "a"
    add r9b, 10
    jmp parse_op_imm_accumulate_hex
parse_op_imm_check_upper:
    cmp r9b, "A"
    jl parse_operand_immediate_done
    cmp r9b, "F"
    jg parse_operand_immediate_done
    sub r9b, "A"
    add r9b, 10
    jmp parse_op_imm_accumulate_hex
parse_op_imm_hex_digit:
    sub r9b, "0"
parse_op_imm_accumulate_hex:
    mul qword[sixteen]
    add rax, r9
    inc r10
    jmp parse_op_imm_hex_loop

parse_op_imm_decimal_loop:
    cmp byte[r10], 0
    je parse_operand_immediate_done
    cmp byte[r10], " "
    je parse_operand_immediate_done
    mov r9b, byte[r10]
    sub r9b, "0"
    mul qword[ten]
    add rax, r9 
    inc r10
    jmp parse_op_imm_decimal_loop
parse_operand_immediate_done:
    mov qword[immediate_value], rax
    pop r10
    pop r9
    pop rax
    jmp parse_operand_done
parse_operand_register:
    copy_str operand, r8
    jmp parse_operand_done
parse_operand_memory:
    copy_str operand, r8
    mov byte[r15], " "
    inc r14
    inc r15
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    find_char r14, "*"
    mov rbx, rax
    find_char r14, "+"
    inc r14

    cmp rax, -1
    jne parse_operand_base_displacement
    cmp rbx, -1
    jne parse_operand_index_scale_only
    cmp byte[r14], "0"
    jne parse_operand_base_only
    ;just displacement_value
    write_char r15, "n"
    write_char r15, " "
    write_char r15, "n"
    write_char r15, " "
    write_char r15, "n"
    write_char r15, " "

    inc r14
    inc r14
    copy_str r14, r15
    write_char r15, " "
    write_char r15, 0
    jmp parse_operand_done
parse_operand_base_only:
    copy_str r14, r15
    write_char r15, " "
    write_char r15, "n"
    write_char r15, " "
    write_char r15, "n"
    write_char r15, " "
    write_char r15, "n"
    write_char r15, " "
    write_char r15, 0
    jmp parse_operand_done
parse_operand_index_scale_only:
    mov byte[rbx], " "
    write_char r15, "n"
    write_char r15, " "
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    copy_str r14, r15
    write_char r15, " "
    write_char r15, "n"
    write_char r15, " "
    write_char r15, 0
    jmp parse_operand_done
parse_operand_base_displacement:
    cmp rbx, -1
    jne parse_operand_complex_memory
    ;baseDis
    mov byte[rax], " "
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    write_char r15, "n"
    write_char r15, " "
    write_char r15, "n"
    write_char r15, " "
    inc r14
    inc r14
    copy_str r14, r15
    write_char r15, " "
    write_char r15, 0
    jmp parse_operand_done
parse_operand_complex_memory:
    replace_char r14, "*", " ", r10
    replace_char r14, "+", " ", r10
    cmp rax, rbx
    jg parse_operand_index_scale_displacement
    cmp r10, 2
    jne parse_operand_base_index_scale
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    inc r14
    inc r14
    copy_str r14, r15
    write_char r15, " "
    write_char r15, 0
    jmp parse_operand_done
parse_operand_base_index_scale:
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    copy_str r14, r15
    write_char r15, " "
    write_char r15, "n"
    write_char r15, " "
    write_char r15, 0   
    jmp parse_operand_done
parse_operand_index_scale_displacement:
    write_char r15, "n"
    write_char r15, " "
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    copy_str r14, r15
    mov byte[r15], " "
    inc r14
    inc r15
    inc r14
    inc r14
    copy_str r14, r15
    write_char r15, " "
    write_char r15, 0
    jmp parse_operand_done
parse_operand_done:
    pop r8
    leave
    ret 8
; ------------------------------------------------------------------------------
; Routine: parse_line
; Description: Tokenizes the instruction line into mnemonic and operands,
;              delegating operand parsing to parse_operand.
; ------------------------------------------------------------------------------
parse_line:
    mov r8, line
    mov r9, instruction
parse_line_find_mnemonic:
    cmp byte [r8], NL
    je parse_line_solo_instruction
    cmp byte [r8], " "
    je parse_line_has_operands
    mov al, [r8]
    mov [r9], al
    inc r8
    inc r9
    jmp parse_line_find_mnemonic
parse_line_solo_instruction:
    mov byte[r9], 0
    lookup_dict instruction, solo_instruction_table, opcode
    jmp write_instruction_results
parse_line_has_operands:
    mov byte[r9], 0
    mov r9, operand
    inc r8
parse_line_first_operand_loop:
    cmp byte[r8], NL
    je parse_line_one_operand
    cmp byte[r8], ","
    je parse_line_two_operands
    mov al, [r8]
    mov [r9], al
    inc r8
    inc r9
    jmp parse_line_first_operand_loop
parse_line_one_operand:
    mov qword[number_of_operands], 1
    mov byte[r9], 0
    push operand_0
    call parse_operand
    jmp parse_line_done
    
parse_line_two_operands:
    mov qword[number_of_operands], 2
    mov byte[r9], 0
    push operand_0
    call parse_operand
    zero_buffer operand, 50
    mov r9, operand
    inc r8
parse_line_skip_space_after_comma:
    cmp byte[r8], " "
    jne parse_line_second_operand_loop
    inc r8
    jmp parse_line_skip_space_after_comma
parse_line_second_operand_loop:
    cmp byte[r8], NL
    je parse_line_second_operand_done
    mov al, [r8]
    mov [r9], al
    inc r8
    inc r9
    jmp parse_line_second_operand_loop
parse_line_second_operand_done:
    push operand_1
    call parse_operand
    jmp parse_line_done
parse_line_done:
    ret

; ------------------------------------------------------------------------------
; Routine: prepare_operand_and_address_sizes
; Description: Inspects the parsed operands to determine:
;              1. Operand size in bits (8, 16, 32, or 64) from register names
;                 or explicit memory size directives (BYTE, WORD, DWORD, QWORD).
;              2. Address size (32 or 64 bits) from base/index registers.
;              3. Displacement size (8 or 32 bits) based on numeric magnitude.
;              4. Immediate data size (8 or 32 bits) based on 128-byte boundary.
; Inputs:
;   operand_0, operand_1, number_of_operands
; Outputs:
;   operand_size, address_size, displacement_size, immediate_size
; Preserves: R8, R9, R10, R11, R12
; ------------------------------------------------------------------------------
prepare_operand_and_address_sizes:
    push r8
    push r9
    push r10
    push r11
    push r12

    mov r8, 64
    mov r9, 32
    mov r10, 16
    mov r11, 8
    mov r12, 0
prepare_sizes_operand_size:
    cmp byte[operand_0], "Q"
    cmove r12, r8
    je prepare_sizes_operand_size_done
    cmp byte[operand_0], "D"
    cmove r12, r9
    je prepare_sizes_operand_size_done
    cmp byte[operand_0], "W"
    cmove r12, r10
    je prepare_sizes_operand_size_done
    cmp byte[operand_0], "B"
    cmove r12, r11
    je prepare_sizes_operand_size_done
    get_token qword 0, operand_0, token_buffer
    get_register_size token_buffer, r12
prepare_sizes_operand_size_done:
    mov [operand_size], r12
    mov r12, 0
prepare_sizes_address_size:
    check_address_size operand_0
    cmp qword[number_of_operands], 1
    je prepare_sizes_skip_second_operand
    check_address_size operand_1
prepare_sizes_skip_second_operand:
prepare_sizes_done:
    cmp qword[immediate_value], 128
    jl prepare_sizes_data_8bit
    mov qword[immediate_size], 32
    jmp prepare_sizes_data_size_found
prepare_sizes_data_8bit:
    mov qword[immediate_size], 8
    jmp prepare_sizes_data_size_found
prepare_sizes_data_size_found:
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    ret

; ------------------------------------------------------------------------------
; Routine: handle_second_register
; Description: Encodes instructions where the second operand is a register
;              (e.g., 'mov [mem], reg' or 'mov reg1, reg2').
;              Configures:
;              - Direction bit D = 0 (reg field is source operand)
;              - Width bit W (0 for 8-bit, 1 for 16/32/64-bit)
;              - ModR/M byte (Mod, Reg, R/M)
;              - SIB byte (Scale, Index, Base) if memory operand requires it
;              - REX prefix extension bits (W, R, X, B) for x86_64 registers
; Inputs:
;   operand_0 (destination: register or memory)
;   operand_1 (source: register)
; ------------------------------------------------------------------------------
handle_second_register:
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je handle_second_reg_keep_width
    mov byte[opcode_width], "1"
handle_second_reg_keep_width:
    get_token qword 0, operand_1, token_buffer
    lookup_dict token_buffer, register_table, modrm_reg
    cmp byte[operand_1], "r"
    jne handle_second_reg_legacy
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "0"
    check_member token_buffer, registers_64
    jnc handle_second_reg_not_64bit
    mov byte[rex_w], "1"
handle_second_reg_not_64bit:
    check_member token_buffer, extended_registers
    jnc handle_second_reg_not_extended
    mov byte[rex_r], "1"
handle_second_reg_not_extended:
handle_second_reg_legacy:
    cmp byte[operand_0], "Q"
    je handle_second_reg_first_is_memory
    cmp byte[operand_0], "D"
    je handle_second_reg_first_is_memory
    cmp byte[operand_0], "W"
    je handle_second_reg_first_is_memory
    cmp byte[operand_0], "B"
    je handle_second_reg_first_is_memory
    append_str d11, modrm_mod
    get_token qword 0, operand_0, token_buffer
    lookup_dict token_buffer, register_table, modrm_rm
    check_member token_buffer, extended_registers
    jnc handle_second_reg_done
    mov byte[has_rex_prefix], 1
    mov byte[rex_b], "1"
    jmp handle_second_reg_done
handle_second_reg_first_is_memory: ;so first is mem
    get_token qword 3, operand_0, token_buffer
    cmp byte[token_buffer], "n"
    jne handle_second_reg_complex_memory
    get_token qword 5, operand_0, token_buffer
    cmp byte[token_buffer], "n"
    jne handle_second_reg_complex_memory
    get_token qword 2, operand_0, token_buffer
    check_member token_buffer, base_registers_exception
    jnc handle_second_reg_not_base_exception
    append_str d01, modrm_mod
    append_str d101, modrm_rm
    append_str d00000000, displacement_field
    jmp handle_second_reg_done
handle_second_reg_not_base_exception:
    check_member token_buffer, extended_registers
    jnc handle_second_reg_base_not_extended
    mov byte[has_rex_prefix], 1
    mov byte[rex_b], "1"

handle_second_reg_base_not_extended:
    append_str d00, modrm_mod
    lookup_dict token_buffer, register_table, modrm_rm
    jmp handle_second_reg_done

handle_second_reg_complex_memory:
    get_token qword 2, operand_0, token_buffer
    cmp byte[token_buffer], "n"
    je handle_second_reg_sib
    get_token qword 3, operand_0, token_buffer
    cmp byte[token_buffer], "n"
    jne handle_second_reg_sib
    cmp qword[displacement_size], 8
    jne handle_second_reg_disp_not_8bit
    append_str d01, modrm_mod
    jmp handle_second_reg_disp_encoded
handle_second_reg_disp_not_8bit:
    cmp qword[displacement_size], 32
    jne handle_second_reg_disp_encoded
    append_str d10, modrm_mod
handle_second_reg_disp_encoded:
    get_token qword 2, operand_0, token_buffer
    lookup_dict token_buffer, register_table, modrm_rm
    normalize_bin qword[displacement_value], qword[displacement_size], displacement_field
    check_member token_buffer, extended_registers
    jnc handle_second_reg_done
    mov byte[has_rex_prefix], 1
    mov byte[rex_b], "1"
    jmp handle_second_reg_done
handle_second_reg_sib:
    append_str d00, modrm_mod
    cmp qword[displacement_size], 8
    jne handle_second_reg_sib_disp_not_8bit
    append_str d01, modrm_mod
    jmp handle_second_reg_sib_disp_encoded
handle_second_reg_sib_disp_not_8bit:
    cmp qword[displacement_size], 32
    jne handle_second_reg_sib_disp_encoded
    append_str d10, modrm_mod
handle_second_reg_sib_disp_encoded:
    get_token qword 2, operand_0, token_buffer
    cmp byte[token_buffer], "n"
    jne handle_second_reg_sib_has_base
    append_str d00, modrm_mod
    mov qword[displacement_size], 32
handle_second_reg_sib_has_base:
    append_str d100, modrm_rm
    get_token qword 2, operand_0, token_buffer
    lookup_dict token_buffer, register_table, sib_base
    check_member token_buffer, extended_registers
    jnc handle_second_reg_sib_no_index
    mov byte[has_rex_prefix], 1
    mov byte[rex_b], "1"
handle_second_reg_sib_no_index:
    get_token qword 3, operand_0, token_buffer
    cmp byte[token_buffer], "n"
    jne handle_second_reg_sib_has_index
    append_str d00, sib_scale
    append_str d100, sib_index
    normalize_bin qword[displacement_value], qword[displacement_size], displacement_field
    jmp handle_second_reg_done
handle_second_reg_sib_has_index:
    get_token qword 4, operand_0, token_buffer
    lookup_dict token_buffer, scale_map, sib_scale
    get_token qword 3, operand_0, token_buffer
    lookup_dict token_buffer, register_table, scratch_buffer_1
    append_str scratch_buffer_1, sib_index
    check_member token_buffer, extended_registers
    jnc handle_second_reg_sib_no_disp
    mov byte[has_rex_prefix], 1
    mov byte[rex_x], "1"
handle_second_reg_sib_no_disp:
    get_token qword 5, operand_0, token_buffer
    cmp byte[token_buffer], "n"
    jne handle_second_reg_sib_has_disp
    normalize_bin qword 0, qword[displacement_size], displacement_field
    jmp handle_second_reg_done
handle_second_reg_sib_has_disp:
    normalize_bin qword[displacement_value], qword[displacement_size], displacement_field
    jmp handle_second_reg_done
handle_second_reg_done:
    ret
; ------------------------------------------------------------------------------
; Routine: normalize_value_to_binary
; Description: Formats an integer or hex value into a little-endian binary bitstring
;              of the specified bit size (8, 16, or 32 bits).
; Stack Inputs:
;   [rbp + 32] - Immediate or displacement numeric value
;   [rbp + 24] - Target bit width (8, 16, 32)
;   [rbp + 16] - Pointer to destination buffer for binary bitstring
; ------------------------------------------------------------------------------
normalize_value_to_binary:
    enter 0, 0
    push r8
    push r9
    push r10
    push r11
    push rax
    push rdx
    mov rax, [rbp + 32]
    mov r9, [rbp + 24]
    mov r10, [rbp + 16]
    mov r11, 2
    add r10, r9
    mov byte[r10], 0
    mov r10, [rbp + 16]
    sub r10, 9
normalize_digits_loop:
    cmp r9, 0
    je normalize_done
    add r10, 16
    mov r8, 8
normalize_bits_loop:
    cmp r8, 0
    je normalize_digits_loop
    xor rdx, rdx
    div r11
    add rdx, "0"
    mov byte[r10], dl
    dec r10
    dec r8
    dec r9
    jmp normalize_bits_loop
normalize_done:
    pop rdx
    pop rax
    pop r11
    pop r10
    pop r9
    pop r8
    leave
    ret 24
; ------------------------------------------------------------------------------
; Routine: handle_second_immediate
; Description: Encodes instructions where the second operand is an immediate value
;              (e.g., 'add eax, 0x10' or 'mov dword ptr [rbx], 0x5').
;              Configures:
;              - Sign-extension bit D (1 if imm8 fits in sign-extended 8 bits, else 0)
;              - Width bit W (0 for 8-bit, 1 for 16/32/64-bit)
;              - Immediate data field in little-endian binary format
;              - ModR/M and SIB encoding for destination operand
; Inputs:
;   operand_0 (destination: register or memory)
;   immediate_value, immediate_size, operand_size
; ------------------------------------------------------------------------------
handle_second_immediate:
    mov byte[opcode_direction], "1"
    cmp qword[immediate_value], 127
    jg handle_second_imm_set_direction_1
    cmp qword[operand_size], 8
    je handle_second_imm_set_direction_1
    jmp handle_second_imm_set_direction_0
handle_second_imm_set_direction_1:
    mov byte[opcode_direction], "0"
handle_second_imm_set_direction_0:
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je handle_second_imm_set_width_1
    mov byte[opcode_width], "1"
handle_second_imm_set_width_1:
    normalize_bin qword[immediate_value], qword[immediate_size], data_field
    cmp qword[operand_size], 64
    jne handle_second_imm_op_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
handle_second_imm_op_not_64bit:
    get_token qword 0, operand_0, token_buffer
    cmp byte[token_buffer], "Q"
    je handle_second_imm_first_is_memory
    cmp byte[token_buffer], "D"
    je handle_second_imm_first_is_memory
    cmp byte[token_buffer], "W"
    je handle_second_imm_first_is_memory
    cmp byte[token_buffer], "B"
    je handle_second_imm_first_is_memory
    append_str d11, modrm_mod
    lookup_dict token_buffer, register_table, modrm_rm
    cmp byte[token_buffer], "r"
    jne handle_second_reg_done
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "0"
    cmp qword[operand_size], 64
    jne handle_second_imm_first_not_64bit
    mov byte[rex_w], "1"
handle_second_imm_first_not_64bit:
    check_member token_buffer, extended_registers
    jnc handle_second_reg_done
    mov byte[rex_b], "1"
    jmp handle_second_reg_done
handle_second_imm_first_is_memory:
    jmp handle_second_reg_first_is_memory
; ------------------------------------------------------------------------------
; Routine: handle_single_operand
; Description: Encodes unary single-operand instructions (e.g. inc, dec, neg, not, idiv)
;              where the single operand is specified in ModR/M r/m and the opcode
;              extension is encoded in the ModR/M reg field.
; Inputs:
;   operand_0 (target: register or memory)
;   operand_size
; ------------------------------------------------------------------------------
handle_single_operand:
    mov byte[opcode_direction], "1"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je handle_single_op_size_is_8bit
    mov byte[opcode_width], "1"
handle_single_op_size_is_8bit:
    cmp qword[operand_size], 64
    jne handle_single_op_size_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
handle_single_op_size_not_64bit:
    jmp handle_second_imm_op_not_64bit
; ------------------------------------------------------------------------------
; Routine: reset
; Description: Resets all intermediate assembly state buffers, override flags,
;              and size variables between assembling consecutive instructions.
; ------------------------------------------------------------------------------
reset:
    mov qword[number_of_operands], 0
    mov byte[has_address_override], 0
    mov byte[has_operand_override], 0
    mov byte[has_rex_prefix], 0
    mov byte[has_extended_opcode], 0
    mov qword[operand_size], 0
    mov qword[address_size], 0
    mov qword[displacement_size], 0
    mov qword[displacement_value], 0
    mov qword[immediate_size], 0
    mov qword[immediate_value], 0
    append_str d0000, rex_w
    append_str d00000000, opcode
    zero_buffer token_buffer, 50
    zero_buffer scratch_buffer_1, 50
    zero_buffer scratch_buffer_2, 50
    zero_buffer instruction, 10
    zero_buffer result, 100
    zero_buffer operand, 50
    zero_buffer operand_0, 50
    zero_buffer operand_1, 50
    zero_buffer extended_opcode, 8
    zero_buffer opcode, 8
    zero_buffer modrm_mod, 8
    zero_buffer sib_scale, 8
    zero_buffer displacement_field, 32
    zero_buffer data_field, 64
    zero_buffer source_filepath, 100
    ret
; ------------------------------------------------------------------------------
; Routine: read_line_from_source_file
; Description: Reads a single newline-terminated line (up to 100 bytes) from
;              the open source assembly file into the line buffer.
; Outputs:
;   line - Null/newline terminated instruction string
;   line_length - Number of characters read
; ------------------------------------------------------------------------------
read_line_from_source_file:
    push rax
    push rdi
    push rsi
    push rdx
    push r8
    mov qword[line_length], 0
    mov r8, line
read_line_loop:
    mov     rax, sys_read
    mov     rdi, [source_file_descriptor]
    mov     rsi, r8 
    mov     rdx, 1
    syscall
    cmp rax, 0
    je exit

    inc qword[line_length]

    cmp byte[r8], NL
    je read_line_done
    inc r8
    jmp read_line_loop
read_line_done:
    pop r8
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
; ------------------------------------------------------------------------------
; Routine: write_instruction_results
; Description: Concatenates all assembled instruction components in architectural
;              x86_64 order:
;              [0x67 prefix] [0x66 prefix] [REX prefix] [Opcode Escape 0x0F]
;              [Opcode] [ModR/M] [SIB] [Displacement] [Immediate Data]
;              Writes:
;              1. Binary bitstring to first-file.txt followed by newline.
;              2. Hexadecimal machine code and source assembly line to second-file.txt.
; ------------------------------------------------------------------------------
write_instruction_results:
    mov r9, 0
    mov r8, result
    cmp byte[has_address_override], 1
    jne write_results_skip_67
    append_str prefix_67, r8
    add r9, 8
    mov r8, r15
write_results_skip_67:
    cmp byte[has_operand_override], 1
    jne write_results_skip_66
    append_str prefix_66, r8
    add r9, 8
    mov r8, r15
write_results_skip_66:
    cmp byte[has_rex_prefix], 1
    jne write_results_skip_rex
    append_str rex_pre, r8
    add r9, 8
    mov r8, r15
write_results_skip_rex:
    cmp byte[has_extended_opcode], 1
    jne write_results_skip_extended_opcode
    append_str extended_opcode, r8
    add r9, 8
    mov r8, r15
write_results_skip_extended_opcode:
    append_str opcode, r8
    add r9, 8
    mov r8, r15
    cmp byte[modrm_mod], 0
    je write_results_skip_modrm
    append_str modrm_mod, r8
    add r9, 8
    mov r8, r15
write_results_skip_modrm:
    cmp byte[sib_scale], 0
    je write_results_skip_sib
    append_str sib_scale, r8
    add r9, 8
    mov r8, r15
write_results_skip_sib:
    cmp byte[displacement_field], 0
    je write_results_skip_displacement
    append_str displacement_field, r8
    add r9, [displacement_size]
    mov r8, r15
write_results_skip_displacement:
    cmp byte[data_field], 0
    je write_results_skip_data
    append_str data_field, r8
    add r9, [immediate_size]
    mov r8, r15
write_results_skip_data:
    mov byte[r8], 0
    mov rax, sys_write
    mov rdi, [dest_binary_file_descriptor]
    mov rsi, result
    mov rdx, r9
    syscall
    mov rax, sys_write
    mov rdi, [dest_binary_file_descriptor]
    mov rsi, newline_char
    mov rdx, 1
    syscall
    bin_to_hex result, token_buffer
    mov rax, r9
    div qword[four]
    mov r9, rax
    mov rax, sys_write
    mov rdi, [dest_hex_file_descriptor]
    mov rsi, token_buffer
    mov rdx, r9
    syscall
    mov rax, sys_write
    mov rdi, [dest_hex_file_descriptor]
    mov rsi, space
    mov rdx, 1
    syscall
    mov rax, sys_write
    mov rdi, [dest_hex_file_descriptor]
    mov rsi, line
    mov rdx, [line_length]
    syscall
    jmp process_next_instruction
; ------------------------------------------------------------------------------
; Program Entry Point: _start
; Description: Initializes prefix constants, reads source filepath from stdin,
;              opens input file, creates output files ('first-file.txt' for binary
;              and 'second-file.txt' for hex/source listings), and starts assembly loop.
; ------------------------------------------------------------------------------
_start:

    append_str d0100, rex_pre
    mov byte[rex_end], 0
    mov byte[extended_opcode_end], 0
    mov byte[opcode_end], 0
    mov byte[modrm_end], 0
    mov byte[sib_end], 0
    mov byte[displacement_field_end], 0
    mov byte[data_field_end], 0
    
    call read_filepath_from_stdin
    mov rax, sys_open
    mov rdi, source_filepath
    mov rsi, O_RDWR
    syscall
    mov [source_file_descriptor], rax
    mov rax, sys_create
    mov rdi, dest_binary_filename
    mov rsi, sys_IRUSR | sys_IWUSR
    syscall
    mov [dest_binary_file_descriptor], rax
    mov rax, sys_create
    mov rdi, dest_hex_filename
    mov rsi, sys_IRUSR | sys_IWUSR
    syscall
    mov [dest_hex_file_descriptor], rax
; ------------------------------------------------------------------------------
; Routine: process_next_instruction
; Description: Main assembler loop. Reads the next instruction line, checks for
;              operand/address size overrides (0x66/0x67), parses tokens, and
;              dispatches to the corresponding mnemonic handler.
; ------------------------------------------------------------------------------
process_next_instruction:
    call read_line_from_source_file

    call reset
    call parse_line
    
    ; mov rsi, instruction
    ; call printString
    ; call newLine
    ; mov rsi, operand_0
    ; call printString
    ; call newLine
    ; mov rsi, operand_1
    ; call printString
    ; call newLine


    call prepare_operand_and_address_sizes


    ; debug [operand_size]
    ; debug [address_size]
    ; debug [displacement_size]
    ; debug [displacement_value]
    ; debug [immediate_size]
    ; debug [immediate_value]

    cmp qword[operand_size], 16
    jne process_instruction_skip_66
    mov byte[has_operand_override], 1
process_instruction_skip_66:
    cmp qword[address_size], 32
    jne process_instruction_skip_67
    mov byte[has_address_override], 1
process_instruction_skip_67:
    check_member instruction, mnemonic_mov
    jc handle_instruction_mov
    check_member instruction, mnemonic_add
    jc handle_instruction_add
    check_member instruction, mnemonic_adc
    jc handle_instruction_adc
    check_member instruction, mnemonic_sub
    jc handle_instruction_sub
    check_member instruction, mnemonic_sbb
    jc handle_instruction_sbb
    check_member instruction,mnemonic_and
    jc handle_instruction_and
    check_member instruction, mnemonic_or
    jc handle_instruction_or
    check_member instruction, mnemonic_xor
    jc handle_instruction_xor
    check_member instruction, mnemonic_dec
    jc handle_instruction_dec
    check_member instruction, mnemonic_inc
    jc handle_instruction_inc
    check_member instruction, mnemonic_cmp
    jc handle_instruction_cmp
    check_member instruction, mnemonic_test
    jc handle_instruction_test
    check_member instruction, mnemonic_xchg
    jc handle_instruction_xchg
    check_member instruction, mnemonic_xadd
    jc handle_instruction_xadd
    check_member instruction, mnemonic_imul
    jc handle_instruction_imul
    check_member instruction, mnemonic_idiv
    jc handle_instruction_idiv
    check_member instruction, mnemonic_bsf
    jc handle_instruction_bsf
    check_member instruction, mnemonic_bsr
    jc handle_instruction_bsr
    check_member instruction, mnemonic_jmp
    jc handle_instruction_jmp
    cmp byte[instruction], "j"
    je handle_instruction_jcc
    check_member instruction, mnemonic_shl
    jc handle_instruction_shl
    check_member instruction, mnemonic_shr
    jc handle_instruction_shr
    check_member instruction, mnemonic_neg
    jc handle_instruction_neg
    check_member instruction, mnemonic_not
    jc handle_instruction_not
    check_member instruction, mnemonic_call
    jc handle_instruction_call
    check_member instruction, mnemonic_ret
    jc handle_instruction_ret
    check_member instruction, mnemonic_push
    jc handle_instruction_push
    check_member instruction, mnemonic_pop
    jc handle_instruction_pop
exit:
    mov     rax, sys_close
    mov     rdi, [source_file_descriptor]
    syscall
    mov     rax, sys_close
    mov     rdi, [dest_binary_file_descriptor]
    syscall
    mov     rax, sys_close
    mov     rdi, [dest_hex_file_descriptor]
    syscall
    mov     rax, sys_exit
    mov     rdi, 0
    syscall

handle_instruction_mov:
    cmp byte[operand_1], "Q"
    je mov_source_is_memory
    cmp byte[operand_1], "D"
    je mov_source_is_memory
    cmp byte[operand_1], "W"
    je mov_source_is_memory
    cmp byte[operand_1], "B"
    je mov_source_is_memory
    cmp byte[operand_1], 0
    je mov_immediate_operand
    append_str d100010, opcode
    call handle_second_register
    jmp write_instruction_results
mov_source_is_memory:
    append_str d100010, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
mov_immediate_operand:
    mov qword[immediate_size], 32 
    cmp byte[operand_0], "Q"
    je mov_imm_check_64bit
    cmp byte[operand_0], "D"
    je mov_imm_check_64bit
    cmp byte[operand_0], "W"
    je mov_imm_check_64bit
    cmp byte[operand_0], "B"
    je mov_imm_check_64bit
    jmp mov_imm_memory_dest
mov_imm_check_64bit:
    cmp qword[operand_size], 64
    je mov_imm_memory_dest
    cmp byte[operand_0], "r"
    jne mov_imm_legacy_reg
    mov byte[has_rex_prefix], 1
    mov byte[rex_b], "1"
mov_imm_legacy_reg:
    append_str d1011, token_buffer
    mov byte[token_buffer + 4], "0"
    cmp qword[operand_size], 8
    je mov_imm_width_0
    mov byte[token_buffer + 4], "1"
mov_imm_width_0:
    lookup_dict operand_0, register_table, scratch_buffer_1
    append_str scratch_buffer_1, token_buffer + 5
    copy_null_str token_buffer, opcode
    normalize_bin qword[immediate_value], qword[immediate_size], data_field
    jmp write_instruction_results
mov_imm_memory_dest:
    append_str d110001, opcode
    append_str d000, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_add:
    cmp byte[operand_1], "Q"
    je add_source_is_memory
    cmp byte[operand_1], "D"
    je add_source_is_memory
    cmp byte[operand_1], "W"
    je add_source_is_memory
    cmp byte[operand_1], "B"
    je add_source_is_memory
    cmp byte[operand_1], 0
    je add_immediate_operand
    append_str d000000, opcode
    call handle_second_register
    jmp write_instruction_results
add_source_is_memory: 
    append_str d000000, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
add_immediate_operand:
    cmp byte[operand_0], "Q"
    je add_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je add_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je add_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je add_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc add_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng add_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne add_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
add_imm_not_64bit:
    append_str d000001, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je add_imm_set_width_0
    mov byte[opcode_width], "1"
add_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32, data_field
    jmp write_instruction_results
add_imm_dest_is_memory:
    append_str d100000, opcode
    append_str d000, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_adc:
    cmp byte[operand_1], "Q"
    je adc_source_is_memory
    cmp byte[operand_1], "D"
    je adc_source_is_memory
    cmp byte[operand_1], "W"
    je adc_source_is_memory
    cmp byte[operand_1], "B"
    je adc_source_is_memory
    cmp byte[operand_1], 0
    je adc_immediate_operand
    append_str d000100, opcode
    call handle_second_register
    jmp write_instruction_results
adc_source_is_memory:
    append_str d000100, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
adc_immediate_operand:
    cmp byte[operand_0], "Q"
    je adc_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je adc_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je adc_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je adc_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc adc_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng adc_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne adc_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
adc_imm_not_64bit:
    append_str d000101, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je adc_imm_set_width_0
    mov byte[opcode_width], "1"
adc_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32,data_field
    jmp write_instruction_results
adc_imm_dest_is_memory:
    append_str d100000, opcode 
    append_str d010, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_sub:
    cmp byte[operand_1], "Q"
    je sub_source_is_memory
    cmp byte[operand_1], "D"
    je sub_source_is_memory
    cmp byte[operand_1], "W"
    je sub_source_is_memory
    cmp byte[operand_1], "B"
    je sub_source_is_memory
    cmp byte[operand_1], 0
    je sub_immediate_operand
    append_str d001010, opcode
    call handle_second_register
    jmp write_instruction_results
sub_source_is_memory:
    append_str d001010, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
sub_immediate_operand:
    cmp byte[operand_0], "Q"
    je sub_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je sub_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je sub_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je sub_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc sub_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng sub_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne sub_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
sub_imm_not_64bit:
    append_str d001011, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je sub_imm_set_width_0
    mov byte[opcode_width], "1"
sub_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32, data_field
    jmp write_instruction_results
sub_imm_dest_is_memory:
    append_str d100000, opcode
    append_str d101, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_sbb:
    cmp byte[operand_1], "Q"
    je sbb_source_is_memory
    cmp byte[operand_1], "D"
    je sbb_source_is_memory
    cmp byte[operand_1], "W"
    je sbb_source_is_memory
    cmp byte[operand_1], "B"
    je sbb_source_is_memory
    cmp byte[operand_1], 0
    je sbb_immediate_operand
    append_str d000110, opcode
    call handle_second_register
    jmp write_instruction_results
sbb_source_is_memory:
    append_str d000110, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
sbb_immediate_operand:
    cmp byte[operand_0], "Q"
    je sbb_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je sbb_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je sbb_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je sbb_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc sbb_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng sbb_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne sbb_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
sbb_imm_not_64bit:
    append_str d000111, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je sbb_imm_set_width_0
    mov byte[opcode_width], "1"
sbb_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32, data_field
    jmp write_instruction_results
sbb_imm_dest_is_memory:
    append_str d100000, opcode
    append_str d011, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_and:
    cmp byte[operand_1], "Q"
    je and_source_is_memory
    cmp byte[operand_1], "D"
    je and_source_is_memory
    cmp byte[operand_1], "W"
    je and_source_is_memory
    cmp byte[operand_1], "B"
    je and_source_is_memory
    cmp byte[operand_1], 0
    je and_immediate_operand
    call append_str d001000, opcode
    call handle_second_register
    jmp write_instruction_results
and_source_is_memory:
    append_str d001000, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
and_immediate_operand:
    cmp byte[operand_0], "Q"
    je and_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je and_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je and_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je and_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc and_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng and_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne and_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
and_imm_not_64bit:
    append_str d001001, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je and_imm_set_width_0
    mov byte[opcode_width], "1"
and_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32, data_field
    jmp write_instruction_results
and_imm_dest_is_memory:
    append_str d100000, opcode
    append_str d100, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_or:
    cmp byte[operand_1], "Q"
    je or_source_is_memory
    cmp byte[operand_1], "D"
    je or_source_is_memory
    cmp byte[operand_1], "W"
    je or_source_is_memory
    cmp byte[operand_1], "B"
    je or_source_is_memory
    cmp byte[operand_1], 0
    je or_immediate_operand
    append_str d000010, opcode
    call handle_second_register
    jmp write_instruction_results
or_source_is_memory:
    append_str d000010, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
or_immediate_operand:
    cmp byte[operand_0], "Q"
    je or_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je or_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je or_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je or_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc or_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng or_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne or_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
or_imm_not_64bit:
    append_str d000011, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je or_imm_set_width_0
    mov byte[opcode_width], "1"
or_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32, data_field
    jmp write_instruction_results
or_imm_dest_is_memory:
    append_str d100000, opcode
    append_str d001, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_xor:
    cmp byte[operand_1], "Q"
    je xor_source_is_memory
    cmp byte[operand_1], "D"
    je xor_source_is_memory
    cmp byte[operand_1], "W"
    je xor_source_is_memory
    cmp byte[operand_1], "B"
    je xor_source_is_memory
    cmp byte[operand_1], 0
    je xor_immediate_operand
    append_str d001100, opcode
    call handle_second_register
    jmp write_instruction_results
xor_source_is_memory:
    append_str d001100, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
xor_immediate_operand:
    cmp byte[operand_0], "Q"
    je xor_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je xor_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je xor_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je xor_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc xor_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng xor_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne xor_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
xor_imm_not_64bit:
    append_str d001101, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je xor_imm_set_width_0
    mov byte[opcode_width], "1"
xor_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32, data_field
    jmp write_instruction_results
xor_imm_dest_is_memory:
    append_str d100000, opcode
    append_str d110, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_dec:
    append_str d111111, opcode
    append_str d001, modrm_reg
    call handle_single_operand
    jmp write_instruction_results
;
handle_instruction_inc:
    append_str d111111, opcode 
    append_str d000, modrm_reg
    call handle_single_operand
    jmp write_instruction_results
;
handle_instruction_cmp:
    cmp byte[operand_1], "Q"
    je cmp_source_is_memory
    cmp byte[operand_1], "D"
    je cmp_source_is_memory
    cmp byte[operand_1], "W"
    je cmp_source_is_memory
    cmp byte[operand_1], "B"
    je cmp_source_is_memory
    cmp byte[operand_1], 0
    je cmp_immediate_operand
    append_str d001110, opcode
    call handle_second_register
    jmp write_instruction_results
cmp_source_is_memory:
    append_str d001110, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
cmp_immediate_operand:
    cmp byte[operand_0], "Q"
    je cmp_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je cmp_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je cmp_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je cmp_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc cmp_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng cmp_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne cmp_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
cmp_imm_not_64bit:
    append_str d001111, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je cmp_imm_set_width_0
    mov byte[opcode_width], "1"
cmp_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32, data_field
    jmp write_instruction_results
cmp_imm_dest_is_memory:
    append_str d100000, opcode
    append_str d111, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_test:
    cmp byte[operand_1], "Q"
    je test_source_is_memory
    cmp byte[operand_1], "D"
    je test_source_is_memory
    cmp byte[operand_1], "W"
    je test_source_is_memory
    cmp byte[operand_1], "B"
    je test_source_is_memory
    cmp byte[operand_1], 0
    je test_immediate_operand
    append_str d100001, opcode
    call handle_second_register
    jmp write_instruction_results
test_source_is_memory:
    append_str d100001, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
test_immediate_operand:
    cmp byte[operand_0], "Q"
    je test_imm_dest_is_memory
    cmp byte[operand_0], "D"
    je test_imm_dest_is_memory
    cmp byte[operand_0], "W"
    je test_imm_dest_is_memory
    cmp byte[operand_0], "B"
    je test_imm_dest_is_memory
    check_member operand_0, accumulator_registers
    jnc test_imm_dest_is_memory
    cmp qword[immediate_value], 127
    jng test_imm_dest_is_memory
    cmp qword[operand_size], 64
    jne test_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
test_imm_not_64bit:
    append_str d101010, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    cmp qword[operand_size], 8
    je test_imm_set_width_0
    mov byte[opcode_width], "1"
test_imm_set_width_0:
    normalize_bin qword[immediate_value], qword 32, data_field
    jmp write_instruction_results
test_imm_dest_is_memory:
    append_str d111101, opcode
    append_str d000, modrm_reg
    call handle_second_immediate
    jmp write_instruction_results
;
handle_instruction_xchg:
    append_str d100001, opcode
    cmp byte[operand_1], "Q"
    je xchg_swap_operands
    cmp byte[operand_1], "D"
    je xchg_swap_operands
    cmp byte[operand_1], "W"
    je xchg_swap_operands
    cmp byte[operand_1], "B"
    je xchg_swap_operands
    jmp xchg_operands_ordered
xchg_swap_operands:
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
xchg_operands_ordered:
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
;
handle_instruction_xadd:
    mov byte[has_extended_opcode], 1
    append_str d00001111, extended_opcode
    append_str d110000, opcode
    call handle_second_register
    mov byte[opcode_direction], "0"
    jmp write_instruction_results
;
handle_instruction_imul:
    cmp qword[number_of_operands], 2
    jne imul_single_operand
    cmp byte[operand_1], "Q"
    je imul_second_is_memory
    cmp byte[operand_1], "D"
    je imul_second_is_memory
    cmp byte[operand_1], "W"
    je imul_second_is_memory
    cmp byte[operand_1], "B"
    je imul_second_is_memory
    mov byte[has_extended_opcode], 1
    append_str d00001111, extended_opcode
    append_str d101011, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    mov byte[opcode_width], "1"
    jmp write_instruction_results
imul_second_is_memory:
    mov byte[has_extended_opcode], 1
    append_str d00001111, extended_opcode
    append_str d101011, opcode
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
    call handle_second_register
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
imul_single_operand:
    append_str d111101, opcode
    call handle_single_operand
    mov byte[opcode_direction], "1"
    append_str d101, modrm_reg
    jmp write_instruction_results
;
handle_instruction_idiv:
    append_str d111101, opcode
    append_str d111, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
;
handle_instruction_bsf:
    cmp byte[operand_0], "Q"
    je bsf_first_is_memory
    cmp byte[operand_0], "D"
    je bsf_first_is_memory
    cmp byte[operand_0], "W"
    je bsf_first_is_memory
    cmp byte[operand_0], "B"
    je bsf_first_is_memory
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
bsf_first_is_memory:
    mov byte[has_extended_opcode], 1
    append_str d00001111, extended_opcode
    append_str d101111, opcode
    call handle_second_register
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    jmp write_instruction_results
;
handle_instruction_bsr:
    cmp byte[operand_0], "Q"
    je bsr_first_is_memory
    cmp byte[operand_0], "D"
    je bsr_first_is_memory
    cmp byte[operand_0], "W"
    je bsr_first_is_memory
    cmp byte[operand_0], "B"
    je bsr_first_is_memory
    copy_null_str operand_0, token_buffer
    copy_null_str operand_1, operand_0
    copy_null_str token_buffer, operand_1
bsr_first_is_memory:
    mov byte[has_extended_opcode], 1
    append_str d00001111, extended_opcode
    append_str d101111, opcode
    call handle_second_register
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "1"
    jmp write_instruction_results
;
handle_instruction_jmp:
    append_str d111111, opcode
    call handle_single_operand
    mov byte[opcode_direction], "1"
    mov byte[opcode_width], "1"
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "0"
    append_str d100, modrm_reg
    jmp write_instruction_results
;
handle_instruction_jcc:
    mov byte[has_extended_opcode], 1
    append_str d00001111, extended_opcode
    append_str d1000, token_buffer
    normalize_bin qword[immediate_value], qword 32, displacement_field
    lookup_dict instruction + 1, condition_code_table, scratch_buffer_1
    append_str scratch_buffer_1, token_buffer + 4
    jmp write_instruction_results
;
handle_instruction_shl:
    cmp qword[number_of_operands], 1
    jne shl_count_is_one
    cmp qword[immediate_value], 1
    je shl_count_is_one
    jmp shl_count_is_cl
shl_count_is_one:
    append_str d110100, opcode
    append_str d100, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "0"
    jmp write_instruction_results
shl_count_is_cl:
    cmp qword[number_of_operands], 2
    jne shl_count_is_immediate
    cmp byte[operand_1], "c"
    jne shl_count_is_immediate
    append_str d110100, opcode
    append_str d100, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
shl_count_is_immediate:
    append_str d110000, opcode
    append_str d100, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "0"
    normalize_bin qword[immediate_value], qword 8, data_field
    jmp write_instruction_results
;
handle_instruction_shr:
    cmp qword[number_of_operands], 1
    jne shr_count_is_one
    cmp qword[immediate_value], 1
    je shr_count_is_one
    jmp shr_count_is_cl
shr_count_is_one:
    append_str d110100, opcode
    append_str d101, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "0"
    jmp write_instruction_results
shr_count_is_cl:
    cmp qword[number_of_operands], 2
    jne shr_count_is_immediate
    cmp byte[operand_1], "c"
    jne shr_count_is_immediate
    append_str d110100, opcode
    append_str d101, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
shr_count_is_immediate:
    append_str d110000, opcode 
    append_str d101, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "0"
    normalize_bin qword[immediate_value], qword 8, data_field
    jmp write_instruction_results
;
handle_instruction_neg:
    append_str d111101, opcode
    append_str d011, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
;
handle_instruction_not:
    append_str d111101, opcode
    append_str d010, modrm_reg
    call handle_single_operand
    mov byte[opcode_direction], "1"
    jmp write_instruction_results
;
handle_instruction_call:
    append_str d11101000, opcode
    normalize_bin qword[immediate_value], qword 32, displacement_field
    jmp write_instruction_results
;
handle_instruction_ret:
    append_str d11000010, opcode
    normalize_bin qword[immediate_value], 16, displacement_field
    jmp write_instruction_results
;
handle_instruction_push:
    cmp byte[operand_0], "Q"
    je push_memory_operand
    cmp byte[operand_0], "D"
    je push_memory_operand
    cmp byte[operand_0], "W"
    je push_memory_operand
    cmp byte[operand_0], "B"
    je push_memory_operand
    cmp byte[operand_0], 0
    je push_immediate_operand
    append_str d01010, token_buffer
    lookup_dict operand_0, register_table, token_buffer + 5
    cmp qword[operand_size], 64
    jne push_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
push_imm_not_64bit:
    check_member operand_0, extended_registers
    jnc write_instruction_results
    mov byte[has_rex_prefix], 1
    mov byte[rex_b], "1"
    jmp write_instruction_results
push_memory_operand:
    append_str d111111, opcode
    append_str d110, modrm_reg
    call handle_single_operand
    mov byte[has_rex_prefix], 0
    mov byte[opcode_direction], "1"
    mov byte[opcode_width], "1"
    jmp write_instruction_results
push_immediate_operand:
    append_str d011010, opcode
    mov byte[opcode_direction], "0"
    mov byte[opcode_width], "0"
    normalize_bin qword[immediate_value], qword[immediate_size], data_field
    jmp write_instruction_results
;
handle_instruction_pop:
    cmp byte[operand_0], "Q"
    je pop_memory_operand
    cmp byte[operand_0], "D"
    je pop_memory_operand
    cmp byte[operand_0], "W"
    je pop_memory_operand
    cmp byte[operand_0], "B"
    je pop_memory_operand
    cmp byte[operand_0], 0
    je pop_memory_operand
    append_str d01011, token_buffer
    lookup_dict operand_0, register_table, token_buffer + 5
    cmp qword[operand_size], 64
    jne pop_imm_not_64bit
    mov byte[has_rex_prefix], 1
    mov byte[rex_w], "1"
pop_imm_not_64bit:
    check_member operand_0, extended_registers
    jnc write_instruction_results
    mov byte[has_rex_prefix], 1
    mov byte[rex_b], "1"
    jmp write_instruction_results
pop_memory_operand:
    append_str d100011, opcode
    append_str d000, modrm_reg
    call handle_single_operand
    mov byte[has_rex_prefix], 0
    mov byte[opcode_direction], "1"
    mov byte[opcode_width], "1"
    jmp write_instruction_results
%endif ; ASSEMBLER_ASM
