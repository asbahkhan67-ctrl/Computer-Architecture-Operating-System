; Lab Task 5 - Exercise 9: Adjacent vs separated dependency values
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 9: Adjacent vs separated dependency values => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, 9
        add eax, 4
        mov ebx, 9
        add ebx, 4
        mov ecx, 3
        add ebx, ecx
        add eax, 3
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


