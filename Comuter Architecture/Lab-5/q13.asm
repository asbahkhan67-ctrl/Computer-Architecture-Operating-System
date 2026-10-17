; Lab Task 5 - Exercise 13: Forward and backward array traversal sums
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 13: Forward and backward array traversal sums => result = %d",10,0
SECTION .data
values dd 1,2,3,4,5,6,7,8
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov esi, values
        xor eax, eax
        xor ebx, ebx
        mov ecx, 8
    .forward:
        add eax, [esi]
        add esi, 4
        loop .forward
        mov esi, values+28
        mov ecx, 8
    .backward:
        add ebx, [esi]
        sub esi, 4
        loop .backward
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


