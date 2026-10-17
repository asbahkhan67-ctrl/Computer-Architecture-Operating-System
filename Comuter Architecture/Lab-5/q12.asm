; Lab Task 5 - Exercise 12: Branch and branchless absolute value
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 12: Branch and branchless absolute value => result = %d",10,0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov eax, -37
        test eax, eax
        jns .positive
        neg eax
    .positive:
        mov ebx, -22
        mov ecx, ebx
        sar ecx, 31
        xor ebx, ecx
        sub ebx, ecx
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


