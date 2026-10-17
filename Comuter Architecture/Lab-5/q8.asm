; Lab Task 5 - Exercise 8: Store then load same memory address
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 8: Store then load same memory address => result = %d",10,0
SECTION .data
scratch dd 0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov dword [scratch], 314
        mov eax, [scratch]
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


