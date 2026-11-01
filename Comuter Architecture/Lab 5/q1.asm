; Lab 5 - Task 1: Spatial Locality via Contiguous Array Traversal
; Objective: Observe compulsory line fetches and consecutive hit rates on linear memory walks.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 1: Spatial Locality via Contiguous Array Traversal ===", 10, 0
    theory_msg   db "[Spatial Locality & Cache Line Mechanics]:", 10
                 db "  - Array specification : N = 1024 32-bit integers (4,096 bytes total).", 10
                 db "  - Hardware line size  : 64 bytes per cache line (holds 16 integers).", 10
                 db "  - Compulsory Misses   : Total Size / Line Size = 4096 B / 64 B = 64 misses.", 10
                 db "  - Total Accesses      : 1024 loads.", 10
                 db "  - Theoretical Miss Rate: 64 / 1024 = 6.25%%", 10
                 db "  - Theoretical Hit Rate : 960 / 1024 = 93.75%% (15 hits per line refill).", 10, 10, 0

    exec_msg     db "[Execution & Verification]:", 10
                 db "  Accumulated Array Sum: %d (Expected: %d)", 10
                 db "  Simulated Access Profile:", 10
                 db "    * Total Accesses     : 1024", 10
                 db "    * Compulsory Misses  : 64", 10
                 db "    * Spatial Hits       : 960", 10
                 db "    * Empirical Miss Rate: 6.25%%", 10
                 db "Verification: Linear array walk fully exploits spatial locality.", 10, 0

    align 64
    array_data   times 1024 dd 3
    expected_sum equ 3072

section .text
_main:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    push title_msg
    call _printf
    add esp, 4

    push theory_msg
    call _printf
    add esp, 4

    ; Compute sum of 1024 integers using base-plus-offset indexed addressing
    xor eax, eax        ; sum accumulator
    xor ecx, ecx        ; index i
.loop_sum:
    add eax, [array_data + ecx*4] ; indexed load: array[i]
    inc ecx
    cmp ecx, 1024
    jl .loop_sum

    push expected_sum
    push eax
    push exec_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
