; Lab 5 - Task 18: Cache Flushing and Cold-Start Latency Quantification
; Objective: Measure exact clock cycle penalties of cache misses using hardware timing instructions.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 18: Cache Flushing & Cold-Start Latency Quantification ===", 10, 0
    theory_msg   db "[Hardware Timing & Cache Miss Quantification (RDTSC + CLFLUSH)]:", 10
                 db "  - CLFLUSH [m] flushes the cache line containing the target address from all cache levels (L1, L2, L3).", 10
                 db "  - Subsequent memory access forces a complete hardware DRAM line refill.", 10
                 db "  - L1 Data Cache Hit Latency : ~4-5 clock cycles.", 10
                 db "  - Main Memory (DRAM) Latency: ~150-250 clock cycles (Memory Wall penalty).", 10, 10, 0

    bench_msg    db "[Measured Hardware Execution Results]:", 10
                 db "  1. Hot L1 Cache Hit Latency     : %u cycles", 10
                 db "  2. Cold Miss (after CLFLUSH)    : %u cycles", 10
                 db "  DRAM Cold-Miss to L1 Hit Ratio  : %u : 1 (~%ux latency penalty)", 10
                 db "Conclusion: Cache hits are orders of magnitude faster than DRAM fetches.", 10, 0

    align 64
    target_cache_line dd 42
    times 15 dd 0

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

    ; Warm up target_cache_line in L1
    mov eax, [target_cache_line]

    ; 1. Measure Hot L1 Hit Latency
    rdtsc
    mov esi, eax ; t0
    mov ebx, [target_cache_line]
    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_l1_hit

    ; 2. Measure Cold Miss Latency using CLFLUSH
    clflush [target_cache_line]
    mfence              ; Serialize memory pipeline

    rdtsc
    mov esi, eax ; t0
    mov ebx, [target_cache_line] ; DRAM fetch
    rdtsc
    sub eax, esi
    mov ebx, eax ; cycles_dram_miss

    ; Compute ratio = cycles_dram_miss / max(cycles_l1_hit, 1)
    mov eax, ebx
    xor edx, edx
    mov ecx, edi
    cmp ecx, 0
    jne .div_ok
    mov ecx, 1
.div_ok:
    div ecx             ; eax = ratio

    push eax            ; ratio
    push eax            ; ratio
    push ebx            ; dram miss cycles
    push edi            ; l1 hit cycles
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
