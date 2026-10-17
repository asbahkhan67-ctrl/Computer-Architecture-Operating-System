; Lab Task 5 - Exercise 1: Memory loop load/store checksum
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 1: Memory loop load/store checksum => result = %d",10,0
SECTION .data
values dd 1,2,3,4,5,6,7,8
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov esi, values
        mov ecx, 8
        xor ebx, ebx
    .loop:
        mov eax, [esi]
        add ebx, eax
        mov [esi], eax
        add esi, 4
        loop .loop
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


