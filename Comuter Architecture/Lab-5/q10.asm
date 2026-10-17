; Lab Task 5 - Exercise 10: Branch loops with taken and not-taken cases
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 10: Branch loops with taken and not-taken cases => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    xor eax, eax
        mov ecx, 1000
    .taken:
        inc eax
        loop .taken
        mov ebx, 1000
        xor ecx, ecx
    .not_taken:
        inc ecx
        cmp ecx, ebx
        jne .not_taken
        add eax, ecx
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


