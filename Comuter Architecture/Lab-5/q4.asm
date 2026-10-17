; Lab Task 5 - Exercise 4: Dependent additions with spacing NOPs
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 4: Dependent additions with spacing NOPs => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, 10
        mov ebx, 20
        nop
        nop
        add eax, ebx
        nop
        nop
        add eax, 5
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


