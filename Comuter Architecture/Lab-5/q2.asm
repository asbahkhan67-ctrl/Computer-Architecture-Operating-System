; Lab Task 5 - Exercise 2: Integer division plus independent work
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 2: Integer division plus independent work => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, 1000
        xor edx, edx
        mov ecx, 7
        div ecx
        mov ebx, eax
        mov eax, 11
        imul eax, 13
        add ebx, eax
        mov eax, ebx
    push eax
    push fmt
    call _printf
    add esp, 8
    xor eax, eax
    pop ebp
    pop edi
    pop esi
    pop ebx
    ret


