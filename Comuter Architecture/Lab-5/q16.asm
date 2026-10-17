; Lab Task 5 - Exercise 16: Four-way unrolled dot product with partial sums
; 32-bit x86 NASM / MinGW GCC. Prints a computed workload result.
; x86 output is not a MIPS pipeline cycle count.
BITS 32
GLOBAL _main
EXTERN _printf
SECTION .data
fmt db "Exercise 16: Four-way unrolled dot product with partial sums => result = %d",10,0
SECTION .data
vec_a dd 1,2,3,4,5,6,7,8
vec_b dd 2,3,4,5,6,7,8,9
sum0 dd 0
sum1 dd 0
sum2 dd 0
sum3 dd 0
SECTION .text
_main:
    push ebx
    push esi
    push edi
    push ebp
    mov esi, vec_a
        mov edi, vec_b
        mov ecx, 2
        xor eax, eax
        xor ebx, ebx
        xor edx, edx
        xor ebp, ebp
    .loop:
        mov eax, eax
        mov ebx, ebx
        mov edx, edx
        mov ebp, ebp
        mov eax, eax
        mov ebx, ebx
        mov edx, edx
        mov ebp, ebp
        ; Accumulate four products using scratch registers below
        mov eax, [esi]
        imul eax, [edi]
        add [sum0], eax
        mov eax, [esi+4]
        imul eax, [edi+4]
        add [sum1], eax
        mov eax, [esi+8]
        imul eax, [edi+8]
        add [sum2], eax
        mov eax, [esi+12]
        imul eax, [edi+12]
        add [sum3], eax
        add esi, 16
        add edi, 16
        loop .loop
        mov eax, [sum0]
        add eax, [sum1]
        add eax, [sum2]
        add eax, [sum3]
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


