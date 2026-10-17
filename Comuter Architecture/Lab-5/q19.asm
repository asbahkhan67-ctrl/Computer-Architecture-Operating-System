; Lab Task 5 - Exercise 19: Sequential and 64-byte stride buffer checksums
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 19: Sequential and 64-byte stride buffer checksums => result = %d",10,0
SECTION .data
buffer times 16384 dd 1
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov esi, buffer
        mov ecx, 16384
        xor eax, eax
    .seq:
        add eax, [esi]
        add esi, 4
        loop .seq
        mov ebx, eax
        mov esi, buffer
        mov ecx, 1024
        xor eax, eax
    .stride:
        add eax, [esi]
        add esi, 64
        loop .stride
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


