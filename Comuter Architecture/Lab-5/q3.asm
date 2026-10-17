; Lab Task 5 - Exercise 3: Multiply and independent ALU result
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 3: Multiply and independent ALU result => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, 123
        imul eax, 17
        mov ebx, eax
        mov ecx, 200
        add ecx, 35
        add ebx, ecx
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


