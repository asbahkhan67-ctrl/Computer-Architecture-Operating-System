; Lab Task 5 - Exercise 11: Useful arithmetic around conditional branch
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 11: Useful arithmetic around conditional branch => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, 14
        mov ebx, 28
        add ebx, 2
        cmp eax, 0
        jne .nonzero
        add ebx, 100
    .nonzero:
        add eax, ebx
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


