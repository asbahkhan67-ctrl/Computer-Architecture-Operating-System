; Lab Task 5 - Exercise 6: Independent work between load and use
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
values dd 125,25,10,5,2,1,0,0
fmt db "Exercise 6: Independent work between load and use => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, [values]
        mov ebx, [values+4]
        imul ebx, 2
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


