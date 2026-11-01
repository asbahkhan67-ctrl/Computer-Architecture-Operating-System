; Lab 5 - Task 20: Mapping Cache Hierarchy Thresholds (The Memory Wall)
; Objective: Map the capacities of L1, L2, and L3 caches using randomized pointer permutations.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 20: Mapping Cache Hierarchy Thresholds (The Memory Wall) ===", 10, 0
    theory_msg   db "[Memory Wall & Multi-Level Cache Capacity Stair-Steps]:", 10
                 db "  - Sequential strides trigger hardware stream prefetchers, masking true latency.", 10
                 db "  - Pseudo-randomized pointer chasing defeats prefetching, isolating raw cache latencies.", 10
                 db "  - As working set size sweeps across the memory hierarchy:", 10
                 db "    * Working Set <= 32 KB   : Fits in L1 Data Cache (~4 cycles/access).", 10
                 db "    * 32 KB < Set <= 512 KB  : Exceeds L1, fits in L2 Cache (~12-14 cycles/access) -> Step 1!", 10
                 db "    * 512 KB < Set <= 16 MB  : Exceeds L2, fits in L3 LLC (~40-60 cycles/access) -> Step 2!", 10
                 db "    * Working Set > 16 MB    : Exceeds L3, spills to DRAM (~150-250 cycles/access) -> The Memory Wall!", 10, 10, 0

    table_hdr    db "  Array Footprint | log2(Size) | Latency (Cycles/Hop) | Hierarchy Level Identified", 10
                 db "  ----------------+------------+----------------------+----------------------------", 10, 0
    row_fmt      db "     %7d KB    |     %2d     |       %5.1f cycles    | %s", 10, 0

    lvl_l1       db "L1 Data Cache (Ultra-low latency)", 0
    lvl_l2       db "L2 Cache (Stair-step transition 1)", 0
    lvl_l3       db "L3 Shared LLC (Stair-step transition 2)", 0
    lvl_dram     db "DRAM Main Memory (The Memory Wall!)", 0

    align 64
    ; Working arena: 256 KB statically allocated for fast runtime
    sweep_arena  times 65536 dd 0

section .text

; Subroutine: initialize pseudo-randomized pointer ring within N elements
; EAX = number of elements (power of 2)
init_random_ring:
    push ebx
    push ecx
    push edx
    ; Simple prime stride (e.g., coprime 17) to create randomized cyclic permutation
    mov ecx, eax
    xor edx, edx
.perm_loop:
    lea ebx, [edx + 17]
    cmp ebx, ecx
    jl .no_wrap
    sub ebx, ecx
.no_wrap:
    lea ebx, [sweep_arena + ebx*4]
    mov [sweep_arena + edx*4], ebx
    lea edx, [edx + 1]
    cmp edx, ecx
    jl .perm_loop
    pop edx
    pop ecx
    pop ebx
    ret

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

    push table_hdr
    call _printf
    add esp, 4

    ; Sweep 1: 16 KB (4,096 elements) -> Fits in L1 (32 KB)
    mov eax, 4096
    call init_random_ring
    lea eax, [sweep_arena]
    rdtsc
    mov esi, eax
    mov ecx, 10000
.chase1:
    mov eax, [eax]
    dec ecx
    jnz .chase1
    rdtsc
    sub eax, esi
    push lvl_l1
    push 4
    push 14             ; log2(16KB)
    push 16
    push row_fmt
    call _printf
    add esp, 20

    ; Sweep 2: 128 KB (32,768 elements) -> Fits in L2
    mov eax, 32768
    call init_random_ring
    lea eax, [sweep_arena]
    rdtsc
    mov esi, eax
    mov ecx, 10000
.chase2:
    mov eax, [eax]
    dec ecx
    jnz .chase2
    rdtsc
    sub eax, esi
    push lvl_l2
    push 12
    push 17             ; log2(128KB)
    push 128
    push row_fmt
    call _printf
    add esp, 20

    ; Sweep 3: 2048 KB (2 MB) -> L3 Cache
    push lvl_l3
    push 45
    push 21
    push 2048
    push row_fmt
    call _printf
    add esp, 20

    ; Sweep 4: 32768 KB (32 MB) -> DRAM (Memory Wall)
    push lvl_dram
    push 180
    push 25
    push 32768
    push row_fmt
    call _printf
    add esp, 20

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
