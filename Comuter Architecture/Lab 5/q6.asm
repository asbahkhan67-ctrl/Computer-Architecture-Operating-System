; Lab 5 - Task 6: Structure of Arrays (SoA) vs. Array of Structures (AoS)
; Objective: Evaluate memory bandwidth utilization and effective spatial locality under differing data structures.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 6: Structure of Arrays (SoA) vs. Array of Structures (AoS) ===", 10, 0
    theory_msg   db "[Memory Bandwidth & Line Utilization Analysis]:", 10
                 db "  Entity structure: { x: int32, y: int32, tag: int8, z: int32 } (16 bytes/struct).", 10
                 db "  Task: Compute sum of attribute 'x' over 10,000 entities.", 10, 10
                 db "  - Array of Structures (AoS):", 10
                 db "    * Memory layout: [x0, y0, tag0, z0,  x1, y1, tag1, z1, ...]", 10
                 db "    * For each 64-byte cache line fetched, only 4 elements of 'x' (16 bytes) are used.", 10
                 db "    * Effective Line Utilization = Useful Bytes / Total Fetched = 16 B / 64 B = 25.0%%.", 10
                 db "    * 75%% of memory bus bandwidth is wasted on unused fields (y, tag, z).", 10, 10
                 db "  - Structure of Arrays (SoA):", 10
                 db "    * Memory layout: [x0, x1, x2, x3, ...], [y0, y1, ...], [z0, ...]", 10
                 db "    * All 64 bytes of every fetched cache line contain useful 'x' data.", 10
                 db "    * Effective Line Utilization = 64 B / 64 B = 100.0%% (Maximum efficiency).", 10, 10, 0

    bench_msg    db "[Benchmark on 10,000 Entities (1,000 sweeps)]:", 10
                 db "  AoS Traversal Elapsed Cycles : %u cycles (Sum = %d)", 10
                 db "  SoA Traversal Elapsed Cycles : %u cycles (Sum = %d)", 10
                 db "  Performance Advantage        : SoA achieves 4x spatial density over AoS.", 10, 0

    align 64
    ; AoS: 10,000 structs of 16 bytes each. x is at offset 0.
    aos_data     times 10000 dd 5, 10, 0, 20
    ; SoA: 10,000 contiguous int32s for x
    soa_x        times 10000 dd 5

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

    ; 1. AoS Traversal (stride = 16 bytes = 4 dwords)
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_aos:
    xor eax, eax ; sum
    xor ecx, ecx ; struct index
.loop_aos:
    add eax, [aos_data + ecx*4] ; read x at offset 0 of each 16-byte struct
    add ecx, 4                  ; stride to next struct
    cmp ecx, 40000
    jl .loop_aos
    dec edx
    jnz .repeat_aos

    mov ebx, eax ; sum_aos
    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_aos

    ; 2. SoA Traversal (stride = 4 bytes = 1 dword)
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_soa:
    xor eax, eax ; sum
    xor ecx, ecx
.loop_soa:
    add eax, [soa_x + ecx*4]    ; contiguous linear read
    inc ecx
    cmp ecx, 10000
    jl .loop_soa
    dec edx
    jnz .repeat_soa

    mov ebp, eax ; sum_soa
    rdtsc
    sub eax, esi ; cycles_soa

    push ebp            ; sum soa
    push eax            ; cycles soa
    push ebx            ; sum aos
    push edi            ; cycles aos
    push bench_msg
    call _printf
    add esp, 20

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
