; Lab Task 5 - Exercise 15: Two-way unrolled dot product
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 15: Two-way unrolled dot product => result = %d",10,0
SECTION .data
vec_a dd 1,2,3,4,5,6,7,8
vec_b dd 2,3,4,5,6,7,8,9
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov esi, vec_a
        mov edi, vec_b
        mov ecx, 4
        xor eax, eax
    .loop:
        mov ebx, [esi]
        imul ebx, [edi]
        add eax, ebx
        mov ebx, [esi+4]
        imul ebx, [edi+4]
        add eax, ebx
        add esi, 8
        add edi, 8
        loop .loop
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


