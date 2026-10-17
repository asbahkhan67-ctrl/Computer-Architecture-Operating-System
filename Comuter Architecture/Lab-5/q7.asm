; Lab Task 5 - Exercise 7: Two interleaved accumulators sum array
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 7: Two interleaved accumulators sum array => result = %d",10,0
SECTION .data
values dd 1,2,3,4,5,6,7,8
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov esi, values
        mov ecx, 4
        xor eax, eax
        xor ebx, ebx
    .loop:
        add eax, [esi]
        add ebx, [esi+4]
        add esi, 8
        loop .loop
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


