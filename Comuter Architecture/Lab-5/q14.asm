; Lab Task 5 - Exercise 14: Alternating and steady condition sequences
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 14: Alternating and steady condition sequences => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    xor eax, eax
        mov ecx, 1000
        xor ebx, ebx
    .alt:
        xor ebx, 1
        test ebx, ebx
        jz .skip1
        inc eax
    .skip1:
        loop .alt
        mov ecx, 1000
    .steady:
        test ecx, ecx
        jz .skip2
        inc eax
    .skip2:
        loop .steady
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


