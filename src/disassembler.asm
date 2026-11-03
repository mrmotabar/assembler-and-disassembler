; ==============================================================================
; File: disassembler.asm
; Description: x86_64 NASM Disassembler implementation in x86_64 Assembly.
;              Reads binary bitstrings from an input file (e.g. first-file.txt),
;              decodes x86_64 NASM instructions, and writes human-readable
;              disassembly into the output file.
; Architecture: x86_64 (Linux ELF64 ABI)
; Author: MohammadReza Motabar
; ==============================================================================
%ifndef DISASSEMBLER_ASM
%define DISASSEMBLER_ASM

%include "system-constants.asm"
%include "console-io.asm"


section .data
    newline_char db 10, 0
    space_char db " ", 0
    comma_char db ",", 0
    plus_char db "+", 0
    asterisk_char db "*", 0
    one_char db "1", 0
    j_char db "j", 0

    map_bin_to_hex db "0123456789ABCDEF"
    one dq 1

    string_cl db "cl", 0

    d00 db "00 ", 0
    d01 db "01 ", 0
    d10 db "10 ", 0
    d11 db "11 ", 0

    d000 db "000 ", 0
    d001 db "001 ", 0
    d010 db "010 ", 0
    d011 db "011 ", 0
    d100 db "100 ", 0
    d101 db "101 ", 0
    d110 db "110 ", 0
    d111 db "111 ", 0

    d0000 dq "0000 ", 0
    d0100 db "0100 ", 0
    d1000 db "1000 ", 0
    d1011 db "1011 ", 0

    d01010 db "01010 ", 0
    d01011 db "01011 ", 0
    d10010 db "10010 ", 0

    d000000 db "000000 ", 0
    d000001 db "000001 ", 0
    d000010 db "000010 ", 0
    d000011 db "000011 ", 0
    d000100 db "000100 ", 0
    d000101 db "000101 ", 0
    d000110 db "000110 ", 0
    d000111 db "000111 ", 0
    d001000 db "001000 ", 0
    d001001 db "001001 ", 0
    d001010 db "001010 ", 0
    d001011 db "001011 ", 0
    d001100 db "001100 ", 0
    d001101 db "001101 ", 0
    d001110 db "001110 ", 0
    d001111 db "001111 ", 0
    d011010 db "011010 ", 0
    d100000 db "100000 ", 0
    d100001 db "100001 ", 0
    d100010 db "100010 ", 0
    d100011 db "100011 ", 0
    d101010 db "101010 ", 0
    d101011 db "101011 ", 0
    d101111 db "101111 ", 0
    d110000 db "110000 ", 0
    d110001 db "110001 ", 0
    d110100 db "110100 ", 0
    d111101 db "111101 ", 0
    d111111 db "111111 ", 0

    d00000000 db "00000000 ", 0
    d00001111 db "00001111 ", 0
    d11000010 db "11000010 ", 0
    d11101000 db "11101000 ", 0
    d11101001 db "11101001 ", 0
    d11101011 db "11101011 ", 0

    d00001111101011 db "00001111101011 ", 0
    d00001111101111 db "00001111101111 ", 0


    string_qword db "QWORD", 0
    string_dword db "DWORD", 0
    string_word db "WORD", 0
    string_byte db "BYTE", 0
    string_ptr db " PTR [", 0

    convertHelper db "0:0000 1:0001 2:0010 3:0011 4:0100 5:0101 6:0110 7:0111 8:1000 9:1001 "
                  db "a:1010 b:1011 c:1100 d:1101 e:1110 f:1111 ", 0

    solo_instruction_table db "11111001:stc 11111000:clc 11111101:std 11111100:cld 0000111100000101:syscall 11000011:ret ", 0
    solo_instruction_table_key db "11111001 11111000 11111101 11111100 0000111100000101 11000011 ", 0

    opcode_two_operand_table db "100010:mov 000000:add 000100:adc 001010:sub 000110:sbb 001000:and 000010:or 001100:xor "
                 db "001110:cmp 100001:n 1000010:test 1000011:xchg 00001111110000:xadd 00001111101011:imul "
                 db "000011111011110:bsf 000011111011111:bsr ", 0
    opcode_two_operand_table_key db "100010 000000 000100 001010 000110 001000 000010 001100 "
                    db "001110 100001 1000010 1000011 00001111110000 00001111101011 "
                    db "000011111011110 000011111011111 ", 0
    opcode_extended_table db "110000 101011 101111 ", 0

    register_table_64 db "0000:rax 0001:rcx 0010:rdx 0011:rbx 0100:rsp 0101:rbp 0110:rsi 0111:rdi 1000:r8 1001:r9 "
                     db "1010:r10 1011:r11 1100:r12 1101:r13 1110:r14 1111:r15 ", 0
    register_table_32 db "0000:eax 0001:ecx 0010:edx 0011:ebx 0100:esp 0101:ebp 0110:esi 0111:edi 1000:r8d 1001:r9d "
                     db "1010:r10d 1011:r11d 1100:r12d 1101:r13d 1110:r14d 1111:r15d ", 0
    register_table_16 db "0000:ax 0001:cx 0010:dx 0011:bx 0100:sp 0101:bp 0110:si 0111:di 1000:r8w 1001:r9w "
                     db "1010:r10w 1011:r11w 1100:r12w 1101:r13w 1110:r14w 1111:r15w ", 0
    register_table_8 db "0000:al 0001:cl 0010:dl 0011:bl 0100:ah 0101:ch 0110:dh 0111:bh 1000:r8b 1001:r9b "
                     db "1010:r10b 1011:r11b 1100:r12b 1101:r13b 1110:r14b 1111:r15b ", 0

    scale_map db "00:1 01:2 10:4 11:8 ", 0

    opcode_immediate_table_110001 db "000:mov ", 0
    opcode_immediate_table_100000 db "000:add 010:adc 101:sub 011:sbb 100:and 001:or 110:xor 111:cmp ", 0
    opcode_immediate_table_111101 db "000:test 101:imul 111:idiv 011:neg 010:not ", 0
    opcode_immediate_table_111111 db "001:dec 000:inc 100:jmp 110:push 010:call", 0
    opcode_immediate_table_110000 db "100:shl 101:shr ", 0
    opcode_immediate_table_110100 db "100:shl 101:shr ", 0
    opcode_immediate_table_100011 db "000:pop ", 0
    opcode_immediate_table_key db "110001 100000 111101 111111 110000 110100 100011 ", 0

    condition_code_table db "0000:o 0001:no 0010:b 0011:ae 0100:e 0101:ne 0110:be 0111:a 1000:s 1001:ns "
         db "1010:p 1011:np 1100:l 1101:ge 1110:le 1111:g ", 0
    
    accumulator_opcode_table db "0000010:add 0001010:adc 0010110:sub 0001110:sbb 0010010:and 0000110:or "
          db "0011010:xor 0011110:cmp 1010100:test ", 0
    accumulator_opcode_key_table db "0000010 0001010 0010110 0001110 0010010 0000110 "
             db "0011010 0011110 1010100 ", 0

    stack_jump_instructions db "jmp push pop call ", 0 

    prefix_66 db "01100110 ", 0
    prefix_67 db "01100111 ", 0

    operand_sizes dq 8, 16, 32, 64
    address_sizes dq 32, 64
    displacement_sizes dq 8, 32

    has_extended_opcode db 0

    is_immediate_operation db 0

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

    ;input db "", NL
    ;machine_code_bitstring db "111111110000110010011001", 0
    source_file_descriptor dq 0
    dest_file_descriptor dq 0
    dest_disassembly_filename db "first-file.txt", 0
section .bss
    token_buffer resb 100
    scratch_buffer_1 resb 100
    scratch_buffer_2 resb 100

    input resb 100
    machine_code_bitstring resb 100

    operand_0 resb 100
    operand_1 resb 100

    rex_w resb 1
    rex_r resb 1
    rex_x resb 1
    rex_b resb 1
    opcode resb 20
    opcode_direction resb 1
    opcode_width resb 1
    modrm_mod resb 10
    modrm_reg resb 10
    modrm_rm resb 10
    sib_scale resb 10
    sib_index resb 10
    sib_base resb 10

    source_filepath resb 100

section .text
    default rel
    global _start

; ==============================================================================
; Macro Definitions: Disassembler Engine
; ==============================================================================

; ------------------------------------------------------------------------------
; Macro: write_str_to_dest
; Description: Writes a null-terminated string to the destination disassembly
;              output file using the Linux sys_write system call.
; Arguments:
;   %1 - Pointer to null-terminated string to write.
; Clobbers:
;   Calculates string length via GetStrlen, invokes sys_write with [dest_file_descriptor].
; ------------------------------------------------------------------------------
%macro write_str_to_dest 1
    mov rdi, %1
    call GetStrlen
    mov rax, sys_write
    mov rdi, [dest_file_descriptor]
    mov rsi, %1
    syscall
%endmacro

; ------------------------------------------------------------------------------
; Macro: write_char_to_dest
; Description: Writes a single character byte from memory to the destination
;              disassembly output file using the Linux sys_write system call.
; Arguments:
;   %1 - Pointer to the 1-byte character buffer to write.
; ------------------------------------------------------------------------------
%macro write_char_to_dest 1
    mov rax, sys_write
    mov rdi, [dest_file_descriptor]
    mov rsi, %1
    mov rdx, 1
    syscall
%endmacro 

; ------------------------------------------------------------------------------
; Macro: debug
; Description: Prints a 64-bit integer value followed by a newline to standard
;              output for debugging purposes.
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
; Macro: find_first_nonzero_size
; Description: Scans an array of quadword operand sizes and retrieves the first
;              non-zero size into the destination register.
; Arguments:
;   %1 - Pointer to array of quadword sizes.
;   %2 - Destination register to receive first non-zero size.
; Preserves: R8
; ------------------------------------------------------------------------------
%macro find_first_nonzero_size 2
    mov %2, 0
    push r8
    mov r8, %1
%%L1:
    cmp qword[r8], 0
    jne %%found
    add r8, 8
    jmp %%L1
%%found:
    mov %2, qword[r8]
    pop r8
%endmacro

; ------------------------------------------------------------------------------
; Macro: select_register_table
; Description: Selects the appropriate register decoding lookup table based on the
;              current operand width in bits (64, 32, 16, or 8).
; Arguments:
;   %1 - Pointer to quadword operand size (64, 32, 16, 8).
;   %2 - Destination register to receive address of matching register_table_*.
; ------------------------------------------------------------------------------
%macro select_register_table 2
    cmp qword[%1], 64 
    je %%its64
    cmp qword[%1], 32
    je %%its32
    cmp qword[%1], 16 
    je %%its16
    cmp qword[%1], 8
    je %%its8
%%its64:
    mov %2, register_table_64
    jmp %%end
%%its32:
    mov %2, register_table_32
    jmp %%end
%%its16:
    mov %2, register_table_16
    jmp %%end
%%its8:
    mov %2, register_table_8
    jmp %%end
%%end:
%endmacro

; ------------------------------------------------------------------------------
; Macro: select_immediate_table
; Description: Maps an immediate/unary instruction opcode bitstring to its
;              corresponding ModR/M 'reg' field extension decoding dictionary.
; Arguments:
;   %1 - Pointer to 6-bit opcode bitstring.
;   %2 - Destination register to receive address of matching opcode_immediate_table_*.
; ------------------------------------------------------------------------------
%macro select_immediate_table 2
    check_member %1, d110001
    jc %%itis110001
    check_member %1, d100000
    jc %%itis100000
    check_member %1, d111101
    jc %%itis111101
    check_member %1, d111111
    jc %%itis111111
    check_member %1, d110000
    jc %%itis110000
    check_member %1, d110100
    jc %%itis110100
    check_member %1, d100011
    jc %%itis100011
%%itis110001:
    mov %2, opcode_immediate_table_110001
    jmp %%end
%%itis100000:
    mov %2, opcode_immediate_table_100000
    jmp %%end
%%itis111101:
    mov %2, opcode_immediate_table_111101
    jmp %%end
%%itis111111:
    mov %2, opcode_immediate_table_111111
    jmp %%end
%%itis110000:
    mov %2, opcode_immediate_table_110000
    jmp %%end
%%itis110100:
    mov %2, opcode_immediate_table_110100
    jmp %%end
%%itis100011:
    mov %2, opcode_immediate_table_100011
    jmp %%end
%%end:
%endmacro

; ------------------------------------------------------------------------------
; Macro: select_size_identifier
; Description: Selects the NASM memory size specifier keyword ('QWORD', 'DWORD',
;              'WORD', or 'BYTE') corresponding to the primary operand bit width.
; Arguments:
;   %1 - Destination register to receive address of string_qword, string_dword, etc.
; ------------------------------------------------------------------------------
%macro select_size_identifier 1
    cmp qword[operand_sizes], 64 
    je %%its64
    cmp qword[operand_sizes], 32
    je %%its32
    cmp qword[operand_sizes], 16 
    je %%its16
    cmp qword[operand_sizes], 8
    je %%its8
%%its64:
    mov %1, string_qword
    jmp %%end
%%its32:
    mov %1, string_dword
    jmp %%end
%%its16:
    mov %1, string_word
    jmp %%end
%%its8:
    mov %1, string_byte
    jmp %%end
%%end:
%endmacro

; ------------------------------------------------------------------------------
; Macro: zero_buffer
; Description: Clears a memory buffer with zeroes for a specified number of bytes.
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
; Macro: lookup_dict
; Description: Looks up a key in a space-separated 'key:value' dictionary table and
;              copies the value to destination (wrapper for lookup_dictionary_value).
; Arguments:
;   %1 - Pointer to search key string.
;   %2 - Pointer to dictionary string.
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

; ------------------------------------------------------------------------------
; Macro: extract_disp
; Description: Extracts little-endian displacement or immediate bits, reverses byte
;              order, and formats as '0x...' hex string (wrapper for extract_displacement_hex).
; Arguments:
;   %1 - Size in bits (8, 16, or 32).
;   %2 - Pointer to destination buffer.
; ------------------------------------------------------------------------------
%macro extract_disp 2
    push %1
    push %2
    call extract_displacement_hex
%endmacro

; ------------------------------------------------------------------------------
; Macro: slice_str
; Description: Extracts a bitstring substring slice from [start_index : end_index]
;              into a destination buffer (wrapper for extract_slice).
; Arguments:
;   %1 - 0-based start bit index (quadword).
;   %2 - End bit index (quadword).
;   %3 - Pointer to source bitstring.
;   %4 - Pointer to destination buffer.
; ------------------------------------------------------------------------------
%macro slice_str 4
    push %1
    push %2
    push %3
    push %4
    call extract_slice
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
;   [rbp + 24] - Pointer to key:value dictionary string
;   [rbp + 16] - Pointer to destination buffer for extracted value
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
;              list of valid words. (Emulates Python membership).
; Stack Inputs:
;   [rbp + 24] - Pointer to search token string
;   [rbp + 16] - Pointer to space-separated token list string
; Returns:
;   CF = 1 if token is found, CF = 0 if not found
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
;              null terminator, or closing bracket ']'.
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
; Description: Appends characters from source to destination without null terminator.
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
; Description: Copies string and ensures destination is null-terminated.
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
; Routine: extract_token_by_index
; Description: Extracts the N-th space-delimited token from a string.
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
; Routine: extract_slice
; Description: Extracts a substring from start offset [rbp+40] to end offset [rbp+32]
;              from source [rbp+24] into destination buffer [rbp+16].
; ------------------------------------------------------------------------------
extract_slice:
    enter 0, 0
    push rax
    push r8
    push r9
    push r10
    push r11
    mov r8, [rbp + 40]
    mov r9, [rbp + 32]
    mov r10, [rbp + 24]
    mov r11, [rbp + 16]
    add r9, r10
    add r10, r8
extract_slice_loop:
    cmp byte[r10], 0
    je extract_slice_done
    cmp r10, r9
    je extract_slice_done
    mov al, byte[r10]
    mov byte[r11], al
    inc r10
    inc r11
    jmp extract_slice_loop
extract_slice_done:
    mov byte[r11], 0
    pop r11
    pop r10
    pop r9
    pop r8
    pop rax
    leave
    ret 32
;
convert2bin:
    push r8
    push r9
    push rax
    mov r8, input
    mov r9, machine_code_bitstring
convert_hex_to_binary_loop:
    cmp byte[r8], NL
    je convert_hex_to_binary_done
    mov al, byte[r8]
    mov byte[token_buffer], al
    lookup_dict token_buffer, convertHelper, r9
    add r9, 4
    inc r8
    jmp convert_hex_to_binary_loop
convert_hex_to_binary_done:
    mov byte[r9], 0
    pop rax
    pop r9
    pop r8
    ret
; ------------------------------------------------------------------------------
; Routine: convert_binary_to_hex
; Description: Converts binary ASCII bitstring into hexadecimal ASCII string.
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
; Routine: extract_displacement_hex
; Description: Extracts displacement or immediate constant from the binary bitstream,
;              reverses byte order from x86 little-endian format to natural big-endian,
;              converts into a hexadecimal string with '0x' prefix, and advances
;              the bitstream pointer.
; Stack Inputs:
;   [rbp + 24] - Size of displacement/immediate in bits (8, 16, 32, or 64)
;   [rbp + 16] - Destination buffer for formatted hex string
; ------------------------------------------------------------------------------
; Description: Extracts little-endian displacement bitstring of requested size
;              and converts it into big-endian hex string.
; ------------------------------------------------------------------------------
extract_displacement_hex:
    enter 0, 0
    push r8
    push r9
    push r10
    push rax
    mov r8, [rbp + 24]
    mov r9, scratch_buffer_1
    add r8, rbx
    sub r8, 8
extract_displacement_loop:
    cmp r8, rbx
    jl extract_displacement_copy_done
    cmp byte[r8], 0
    je extract_displacement_continue
    slice_str qword 0, qword 8, r8, r9
    add r9, 8
    sub r8, 8
    jmp extract_displacement_loop
extract_displacement_continue:
    sub r8, 8
    jmp extract_displacement_loop
extract_displacement_copy_done:
    mov byte[r9], 0
    bin_to_hex scratch_buffer_1, scratch_buffer_2
    mov r8, [rbp + 16]
    mov byte[r8], "0"
    inc r8
    mov byte[r8], "x"
    inc r8
    mov r9, scratch_buffer_2
    mov r10, 0
extract_displacement_hex_loop:
    cmp byte[r9], 0
    je extract_displacement_done
    cmp byte[r9], "0"
    je extract_displacement_hex_zero
    mov r10, 1
    mov al, byte[r9]
    mov byte[r8], al
    inc r8
    inc r9
    jmp extract_displacement_hex_loop
extract_displacement_hex_zero:
    inc r9
    cmp r10, 1
    jne extract_displacement_hex_loop
    mov al, byte[r9 - 1]
    mov byte[r8], al
    inc r8
    jmp extract_displacement_hex_loop
extract_displacement_done:
    cmp byte[r8 - 1], "x"
    je extract_displacement_is_zero
    mov byte[r8], 0 
    mov r15, r8
    pop rax
    pop r10
    pop r9
    pop r8
    leave
    ret 16
extract_displacement_is_zero:
    mov byte[r8], "0"
    inc r8
    jmp extract_displacement_done
;
reset:
    mov rbx, machine_code_bitstring
    mov byte[rex_r], "0"
    mov byte[rex_x], "0"
    mov byte[rex_b], "0"
    mov qword[operand_sizes], 8
    mov qword[operand_sizes + 8], 16
    mov qword[operand_sizes + 16], 32
    mov qword[operand_sizes + 24], 64
    mov qword[address_sizes], 32
    mov qword[address_sizes + 8], 64
    mov qword[displacement_sizes], 8
    mov qword[displacement_sizes + 8], 32
    mov byte[has_extended_opcode], 0
    mov byte[is_immediate_operation], 0

    zero_buffer token_buffer, 100
    zero_buffer scratch_buffer_1, 100
    zero_buffer scratch_buffer_2, 100
    zero_buffer operand_0, 100
    zero_buffer operand_1, 100
    zero_buffer opcode, 22
    zero_buffer modrm_mod, 30
    zero_buffer sib_scale, 30
    ret
;

read_line_from_source_file:
    push rax
    push rdi
    push rsi
    push rdx
    push r8
    mov r8, machine_code_bitstring
read_line_loop:
    mov     rax, sys_read
    mov     rdi, [source_file_descriptor]
    mov     rsi, r8 
    mov     rdx, 1
    syscall
    cmp rax, 0
    je exit
    cmp byte[r8], NL
    je read_line_done
    inc r8
    jmp read_line_loop
read_line_done:
    mov byte[r8], 0
    pop r8
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
;
_start:
    call read_filepath_from_stdin
    mov rax, sys_open
    mov rdi, source_filepath
    mov rsi, O_RDWR
    syscall
    mov [source_file_descriptor], rax
    mov rax, sys_create
    mov rdi, dest_disassembly_filename
    mov rsi, sys_IRUSR | sys_IWUSR
    syscall
    mov [dest_file_descriptor], rax

; ------------------------------------------------------------------------------
; Routine: decode_next_instruction
; Description: Main disassembler decoding loop. Reads a line of binary machine code
;              bitstring, parses prefixes (0x67 address override, 0x66 operand override,
;              REX prefix), detects two-byte opcode escape (0x0F), and dispatches
;              to the appropriate decoder branch.
; ------------------------------------------------------------------------------
decode_next_instruction:
    call reset
    call read_line_from_source_file
    ;call convert_hex_to_binary
    check_member rbx, solo_instruction_table_key
    jc decode_solo_instruction
    slice_str qword 0, qword 8, rbx, token_buffer
    check_member token_buffer, prefix_67
    jnc decode_skip_67
    add rbx, 8
    jmp decode_check_66
decode_skip_67:
    mov qword[address_sizes], 0
decode_check_66:
    slice_str qword 0, qword 8, rbx, token_buffer

    check_member token_buffer, prefix_66
    jnc decode_skip_66
    mov qword[operand_sizes], 0
    add rbx, 8
    jmp decode_check_rex
decode_skip_66:
    mov qword[operand_sizes + 8], 0
decode_check_rex:
    slice_str qword 0, qword 4, rbx, token_buffer
    check_member token_buffer, d0100
    jnc decode_skip_rex
    add rbx, 4
    mov al, byte[rbx + 1]
    mov byte[rex_r], al
    mov al, byte[rbx + 2]
    mov byte[rex_x], al
    mov al, byte[rbx + 3]
    mov byte[rex_b], al
    add rbx, 4
    cmp byte[rbx - 4], "1"
    jne decode_check_opcode_escape
    mov qword[operand_sizes], 0
    mov qword[operand_sizes + 8], 0
    mov qword[operand_sizes + 16], 0
    jmp decode_check_opcode_escape
decode_skip_rex:
decode_check_opcode_escape:
    slice_str qword 0, qword 8, rbx, token_buffer
    check_member token_buffer, d00001111
    jnc decode_check_opcode
    add rbx, 8
    append_str d00001111, opcode
    mov byte[has_extended_opcode], 1
decode_check_opcode:
    find_first_nonzero_size operand_sizes, rax
    mov [operand_sizes], rax
    find_first_nonzero_size address_sizes, rax
    mov [address_sizes], rax
    
    slice_str qword 0, qword 8, rbx, token_buffer
    check_member token_buffer, d11101011
    jc decode_jmp
    check_member token_buffer, d11101001
    jc decode_jmp
    cmp byte[has_extended_opcode], 0
    je dispatch_not_jcc
    slice_str qword 0, qword 4, rbx, token_buffer
    check_member token_buffer, d1000
    jnc dispatch_not_jcc
    jmp decode_jcc
dispatch_not_jcc:
    slice_str qword 0, qword 8, rbx, token_buffer
    check_member token_buffer, d11101000
    jc decode_call
    check_member token_buffer, d11000010
    jc decode_ret
    slice_str qword 0, qword 5, rbx, token_buffer
    check_member token_buffer, d01010
    jc decode_push_reg
    slice_str qword 0, qword 6, rbx, token_buffer
    check_member token_buffer, d011010
    jnc dispatch_not_push_disp
    cmp byte[rbx + 7], "0"
    jne dispatch_not_push_disp
    jmp decode_push_disp
dispatch_not_push_disp:
    slice_str qword 0, qword 6, rbx, token_buffer
    check_member token_buffer, d011010
    jnc dispatch_not_imul
    cmp byte[rbx + 7], "1"
    jne dispatch_not_imul
    jmp decode_imul
dispatch_not_imul:
    slice_str qword 0, qword 5, rbx, token_buffer
    check_member token_buffer, d01011
    jc decode_pop
    slice_str qword 0, qword 4, rbx, token_buffer
    check_member token_buffer, d1011
    jnc dispatch_not_mov_accumulator
    cmp byte[opcode], 0
    jne dispatch_not_mov_accumulator
    jmp decode_mov_accumulator
dispatch_not_mov_accumulator:
    slice_str qword 0, qword 5, rbx, token_buffer
    check_member token_buffer, d10010
    jc decode_xchg_accumulator
    slice_str qword 0, qword 7, rbx, token_buffer
    check_member token_buffer, accumulator_opcode_key_table
    jc hAx

    slice_str qword 0, qword 6, rbx, token_buffer
    check_member token_buffer, opcode_two_operand_table_key
    jc decode_two_operand
    check_member token_buffer, opcode_extended_table
    jnc dispatch_not_two_operand
    cmp byte[opcode], 0
    je dispatch_not_two_operand
    jmp decode_two_operand
dispatch_not_two_operand:
    slice_str qword 0, qword 6, rbx, token_buffer
    check_member token_buffer, opcode_immediate_table_key
    jc decode_immediate_or_unary
exit:
    mov     rax, sys_close
    mov     rdi, [source_file_descriptor]
    syscall
    mov     rax, sys_close
    mov     rdi, [dest_file_descriptor]
    syscall
    mov     rax, sys_exit
    mov     rdi, 0
    syscall

decode_solo_instruction:
    lookup_dict machine_code_bitstring, solo_instruction_table, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
; ------------------------------------------------------------------------------
; Routine: handle_two_operand_instruction
; Description: Decodes two-operand x86 instructions using the ModR/M and optional
;              SIB byte. Handles register-to-register, memory-to-register, and
;              register-to-memory addressing modes. Respects the direction bit (D)
;              to format operands in standard NASM 'mnemonic dest, src' order.
; Inputs:
;   opcode, opcode_direction, opcode_width, modrm_mod, modrm_reg, modrm_rm
; ------------------------------------------------------------------------------
handle_two_operand_instruction:
    slice_str qword 0, qword 2, rbx, modrm_mod
    slice_str qword 2, qword 5, rbx, modrm_reg
    slice_str qword 5, qword 8, rbx, modrm_rm
    add rbx, 8
    lookup_dict opcode, opcode_two_operand_table, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest space_char
    mov al, byte[rex_r]
    mov byte[token_buffer], al
    copy_str modrm_reg, token_buffer + 1
    select_register_table operand_sizes, rax
    lookup_dict token_buffer, rax, operand_0
handle_two_operand_decode_mod:
    check_member modrm_mod, d11
    jnc handle_two_operand_mod_not_11
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    copy_str modrm_rm, token_buffer + 1
    select_register_table operand_sizes, rax
    lookup_dict token_buffer, rax, operand_1
    mov rdx, r15
    jmp handle_two_operand_write_operands
handle_two_operand_mod_not_11:
    check_member modrm_mod, d00
    jc handle_two_operand_mod_00
    mov qword[displacement_sizes], 8
    check_member modrm_mod, d10
    jnc handle_two_operand_mod_not_10
    mov qword[displacement_sizes], 32
handle_two_operand_mod_not_10:
    select_size_identifier rax
    copy_str rax, operand_1
    mov rdx, r15
    copy_null_str string_ptr, rdx
    mov rdx, r15
    check_member modrm_rm, d100
    jnc handle_two_operand_rm_not_sib
    slice_str qword 0, qword 2, rbx, sib_scale
    slice_str qword 2, qword 5, rbx, sib_index
    slice_str qword 5, qword 8, rbx, sib_base
    add rbx, 8
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    copy_str sib_base, token_buffer+ + 1
    select_register_table address_sizes, rax
    lookup_dict token_buffer, rax, rdx
    mov rdx, r15
    check_member sib_index, d100
    jnc handle_two_operand_has_index
    cmp byte[rex_x], "0"
    jne handle_two_operand_has_index
    check_member sib_scale, d00
    jnc handle_two_operand_has_index
    jmp handle_two_operand_first_done
handle_two_operand_has_index:
    mov byte[rdx], "+"
    inc rdx
    mov al, byte[rex_x]
    mov byte[token_buffer], al
    copy_str sib_index, token_buffer+ + 1
    select_register_table address_sizes, rax
    lookup_dict token_buffer, rax, rdx
    mov rdx, r15
    mov byte[rdx], "*"
    inc rdx
    lookup_dict sib_scale, scale_map, rdx
    mov rdx, r15
handle_two_operand_first_done:
    mov byte[rdx], "+"
    inc rdx
    extract_disp qword[displacement_sizes], rdx
    mov rdx, r15
    mov byte[rdx], "]"
    inc rdx
    jmp handle_two_operand_write_operands
handle_two_operand_rm_not_sib:
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    copy_str modrm_rm, token_buffer + 1
    select_register_table address_sizes, rax
    lookup_dict token_buffer, rax, rdx
    mov rdx, r15
    mov byte[rdx], "+"
    inc rdx
    extract_disp qword[displacement_sizes], rdx
    mov rdx, r15
    mov byte[rdx], "]"
    inc rdx
    jmp handle_two_operand_write_operands
handle_two_operand_mod_00:
    check_member modrm_rm, d100
    jnc handle_two_operand_mod_00_index_only
    slice_str qword 0, qword 2, rbx, sib_scale
    slice_str qword 2, qword 5, rbx, sib_index
    slice_str qword 5, qword 8, rbx, sib_base
    add rbx, 8
    check_member sib_base, d101
    jnc handle_two_operand_mod_00_standard_base
    mov qword[displacement_sizes], 32
    check_member sib_index, d100
    jc handle_two_operand_mod_00_index_100
    select_size_identifier rax
    copy_str rax, operand_1
    mov rdx, r15
    copy_null_str string_ptr, rdx
    mov rdx, r15
    mov al, byte[rex_x]
    mov byte[token_buffer], al
    copy_str sib_index, token_buffer + 1
    select_register_table address_sizes, rax
    lookup_dict token_buffer, rax, rdx
    mov rdx, r15
    mov byte[rdx], "*"
    inc rdx
    lookup_dict sib_scale, scale_map, rdx
    mov rdx, r15
    mov byte[rdx], "+"
    inc rdx
    extract_disp qword[displacement_sizes], rdx
    mov rdx, r15
    mov byte[rdx], "]"
    inc rdx
    jmp handle_two_operand_write_operands
handle_two_operand_mod_00_index_100:
    select_size_identifier rax
    copy_str rax, operand_1
    mov rdx, r15
    copy_null_str string_ptr, rdx
    mov rdx, r15
    extract_disp qword[displacement_sizes], rdx
    mov rdx, r15
    mov byte[rdx], "]"
    inc rdx
    jmp handle_two_operand_write_operands
handle_two_operand_mod_00_standard_base:
    select_size_identifier rax
    copy_str rax, operand_1
    mov rdx, r15
    copy_null_str string_ptr, rdx
    mov rdx, r15
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    copy_str sib_base, token_buffer + 1
    select_register_table address_sizes, rax
    lookup_dict token_buffer, rax, rdx
    mov rdx, r15
    mov byte[rdx], "+"
    inc rdx
    mov al, byte[rex_x]
    mov byte[token_buffer], al
    copy_str sib_index, token_buffer + 1
    select_register_table address_sizes, rax
    lookup_dict token_buffer, rax, rdx
    mov rdx, r15
    mov byte[rdx], "*"
    inc rdx
    lookup_dict sib_scale, scale_map, rdx
    mov rdx, r15
    mov byte[rdx], "]"
    inc rdx
    jmp handle_two_operand_write_operands
handle_two_operand_mod_00_index_only:
    check_member modrm_rm, d101
    jnc handle_two_operand_mod_00_base_index
    select_size_identifier rax
    copy_str rax, operand_1
    mov rdx, r15
    copy_null_str string_ptr, rdx
    mov rdx, r15
    extract_disp qword[displacement_sizes], rdx
    mov rdx, r15
    mov byte[rdx], "]"
    inc rdx
    jmp handle_two_operand_write_operands
handle_two_operand_mod_00_base_index:
    select_size_identifier rax
    copy_str rax, operand_1
    mov rdx, r15
    copy_null_str string_ptr, rdx
    mov rdx, r15
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    copy_str modrm_rm, token_buffer + 1
    select_register_table address_sizes, rax 
    lookup_dict token_buffer, rax, rdx
    mov rdx, r15
    mov byte[rdx], "]"
    inc rdx
    jmp handle_two_operand_write_operands
handle_two_operand_write_operands:
    cmp byte[is_immediate_operation], 1
    je handle_two_operand_done
    cmp byte[opcode_direction], "0"
    jne handle_two_operand_write_operands_reversed
    write_str_to_dest operand_1
    write_char_to_dest comma_char
    write_str_to_dest operand_0
    jmp handle_two_operand_done
handle_two_operand_write_operands_reversed:
    write_str_to_dest operand_0
    write_char_to_dest comma_char
    write_str_to_dest operand_1
    jmp handle_two_operand_done
handle_two_operand_done:
    ret
;
; ------------------------------------------------------------------------------
; Routine: handle_immediate_or_unary_instruction
; Description: Decodes instructions where the ModR/M 'reg' field acts as an opcode
;              extension (immediates like 'add [mem], imm' or unaries like 'inc reg').
;              Resolves mnemonic from opcode extension table, decodes target operand,
;              and appends immediate constant or shift count if applicable.
; ------------------------------------------------------------------------------
handle_immediate_or_unary_instruction:

    slice_str qword 0, qword 2, rbx, modrm_mod
    slice_str qword 2, qword 5, rbx, modrm_reg
    slice_str qword 5, qword 8, rbx, modrm_rm
    add rbx, 8
    
    select_immediate_table opcode, rax
    lookup_dict modrm_reg, rax, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest space_char
    check_member token_buffer, stack_jump_instructions
    jnc handle_imm_op_continue
    cmp qword[operand_sizes + 8], 0
    jne handle_imm_op_continue
    mov qword[operand_sizes], 64
handle_imm_op_continue:
    mov byte[is_immediate_operation], 1
    call handle_two_operand_decode_mod
    jmp handle_imm_op_write
handle_imm_op_write:
    cmp byte[rbx], 0
    je handle_imm_op_single_operand
    mov byte[rdx], ","
    inc rdx
    extract_disp qword 64, rdx
    mov rdx, r15
    write_str_to_dest operand_1
    ret

handle_imm_op_single_operand:
    check_member opcode, d110100
    jc handle_imm_op_shift
    write_str_to_dest operand_1
    ret
handle_imm_op_shift:
    write_str_to_dest operand_1
    write_char_to_dest comma_char
    cmp byte[opcode_direction], "1"
    jne handle_imm_op_shift_by_one
    write_str_to_dest string_cl
    ret
handle_imm_op_shift_by_one:
    write_char_to_dest one_char
    ret

;
decode_jmp:
    write_str_to_dest mnemonic_jmp
    add rbx, 8
    extract_disp qword 32, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_jcc:
    write_char_to_dest j_char
    slice_str qword 4, qword 8, rbx, token_buffer
    lookup_dict token_buffer, condition_code_table, scratch_buffer_1
    write_str_to_dest scratch_buffer_1
    write_char_to_dest space_char
    add rbx, 8
    extract_disp qword 32, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_call:
    write_str_to_dest mnemonic_call
    add rbx, 8
    extract_disp qword 32, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_ret:
    write_str_to_dest mnemonic_ret
    add rbx, 8
    extract_disp qword 32, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_push_reg:
    write_str_to_dest mnemonic_push
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    add rbx, 5
    copy_str rbx, token_buffer + 1
    select_register_table operand_sizes, rax
    lookup_dict token_buffer, rax, scratch_buffer_1
    write_str_to_dest scratch_buffer_1
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_push_disp:
    write_str_to_dest mnemonic_push
    add rbx, 8
    extract_disp qword 32, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_imul:
    mov qword[operand_sizes], 0
    find_first_nonzero_size operand_sizes, rax
    mov [operand_sizes], rax
    copy_str d00001111101011, opcode
    mov byte[opcode_direction], "1"
    mov byte[opcode_width], "1"
    add rbx, 8
    call handle_two_operand_instruction
    write_char_to_dest comma_char
    extract_disp qword 32, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_pop:
    write_str_to_dest mnemonic_pop
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    add rbx, 5
    copy_str rbx, token_buffer + 1
    select_register_table operand_sizes, rax
    lookup_dict token_buffer, rax, scratch_buffer_1
    write_str_to_dest scratch_buffer_1
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_mov_accumulator:
    write_str_to_dest mnemonic_mov
    mov al, byte[rbx + 4]
    mov byte[opcode_width], al
    slice_str qword 5, qword 8, rbx, modrm_reg
    add rbx, 8
    cmp byte[opcode_width], "0"
    jne decode_mov_acc_not_8bit
    mov qword[operand_sizes], 8
    jmp decode_mov_acc_continue
decode_mov_acc_not_8bit:
    mov qword[operand_sizes], 0
    find_first_nonzero_size operand_sizes, rax
    mov [operand_sizes], rax
decode_mov_acc_continue:
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    copy_str modrm_reg, token_buffer + 1
    select_register_table operand_sizes, rax
    lookup_dict token_buffer, rax, scratch_buffer_1
    write_str_to_dest scratch_buffer_1
    write_char_to_dest comma_char
    extract_disp qword[operand_sizes], token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_xchg_accumulator:
    write_str_to_dest mnemonic_xchg
    mov byte[opcode_width], "1"
    slice_str qword 5, qword 8, rbx, modrm_reg
    add rbx, 8
    cmp byte[opcode_width], "0"
    jne decode_xchg_acc_not_8bit
    mov qword[operand_sizes], 8
    jmp decode_xchg_acc_continue
decode_xchg_acc_not_8bit:
    mov qword[operand_sizes], 0
    find_first_nonzero_size operand_sizes, rax
    mov [operand_sizes], rax
decode_xchg_acc_continue:
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    copy_str modrm_reg, token_buffer + 1
    select_register_table operand_sizes, rax
    lookup_dict token_buffer, rax, scratch_buffer_1
    write_str_to_dest scratch_buffer_1
    write_char_to_dest comma_char
    select_register_table operand_sizes, rax
    lookup_dict d0000, rax, scratch_buffer_1
    write_str_to_dest scratch_buffer_1
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
hAx:
    slice_str qword 0, qword 7, rbx, token_buffer
    lookup_dict token_buffer, accumulator_opcode_table, scratch_buffer_1
    write_str_to_dest scratch_buffer_1
    write_char_to_dest space_char
    mov al, byte[rbx + 7]
    mov byte[opcode_width], al
    copy_str d000, modrm_reg
    add rbx, 8
    cmp byte[opcode_width], "0"
    jne handle_accumulator_op_not_8bit
    mov qword[operand_sizes], 8
    jmp handle_accumulator_continue
handle_accumulator_op_not_8bit:
    mov qword[operand_sizes], 0
    find_first_nonzero_size operand_sizes, rax
    mov [operand_sizes], rax
handle_accumulator_continue:
    mov al, byte[rex_b]
    mov byte[token_buffer], al
    copy_str modrm_reg, token_buffer + 1
    select_register_table operand_sizes, rax
    lookup_dict token_buffer, rax, scratch_buffer_1
    write_str_to_dest scratch_buffer_1
    write_char_to_dest comma_char
    extract_disp qword 32, token_buffer
    write_str_to_dest token_buffer
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_two_operand:
    mov rax, 0
    cmp byte[has_extended_opcode], 1
    jne decode_two_operand_no_escape
    slice_str qword 0, qword 6, rbx, token_buffer
    copy_str token_buffer, opcode + 8
    mov r13, r15
    jmp decode_two_operand_found
decode_two_operand_no_escape:
    slice_str qword 0, qword 6, rbx, token_buffer
    copy_str token_buffer, opcode
    mov r13, r15
decode_two_operand_found:
    mov al, byte[rbx + 6]
    mov byte[opcode_direction], al
    mov al, byte[rbx + 7]
    mov byte[opcode_width], al
    check_member opcode, d100001
    jnc decode_two_operand_not_test
    mov al, byte[opcode_direction]
    mov byte[r13], al
    inc r13
    mov byte[r13], 0
    mov byte[opcode_direction], "0"
decode_two_operand_not_test:
    check_member opcode, d00001111101111
    jnc decode_two_operand_not_bsf
    mov al, byte[opcode_width]
    mov byte[r13], al
    inc r13
    mov byte[r13], 0
    mov byte[opcode_direction], "1"
    mov byte[opcode_width], "1"
decode_two_operand_not_bsf:
    cmp byte[opcode_width], "0"
    jne decode_two_operand_not_8bit
    mov qword[operand_sizes], 8
    jmp decode_two_operand_continue
decode_two_operand_not_8bit:
    mov qword[operand_sizes], 0
    find_first_nonzero_size operand_sizes, rax
    mov [operand_sizes], rax
decode_two_operand_continue:
    add rbx, 8
    call handle_two_operand_instruction
    write_char_to_dest newline_char
    jmp decode_next_instruction
;
decode_immediate_or_unary:
    slice_str qword 0, qword 6, rbx, opcode
    mov al, byte[rbx + 6]
    mov byte[opcode_direction], al
    mov al, byte[rbx + 7]
    mov byte[opcode_width], al
    cmp byte[opcode_width], "0"
    jne decode_imm_unary_not_8bit
    mov qword[operand_sizes], 8
    jmp decode_imm_unary_continue
decode_imm_unary_not_8bit:
    mov qword[operand_sizes], 0
    find_first_nonzero_size operand_sizes, rax
    mov [operand_sizes], rax
decode_imm_unary_continue:
    add rbx, 8
    call handle_immediate_or_unary_instruction
    write_char_to_dest newline_char
    jmp decode_next_instruction
%endif ; DISASSEMBLER_ASM
