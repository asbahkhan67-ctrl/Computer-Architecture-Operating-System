; Lab Task 5 - Exercise 18: Function call sum and equivalent inline sum
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 18: Function call sum and equivalent inline sum => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    push dword 1
        call add_one
        add esp, 4
        mov ebx, eax
        add ebx, 2
        add ebx, 3
        add ebx, 4
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

add_one:
    mov eax, [esp+4]
    inc eax
    ret


