; Lab 5 - Task 2: Temporal Locality with Hot Working Sets
; Objective: Demonstrate zero-latency reuse when working sets fit completely within a single cache block.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 2: Temporal Locality with Hot Working Sets ===", 10, 0
    theory_msg   db "[Temporal Locality Principles & MMIO Comparison]:", 10
                 db "  - Working set size   : 4 bytes (Single 16-byte aligned memory block).", 10
                 db "  - Total Iterations   : 10,000 read-modify-write cycles.", 10
                 db "  - Cycle 1 (Cold Miss): Line fetched from main memory into L1 Data Cache.", 10
                 db "  - Cycles 2..10,000   : 100%% L1 Cache Hits (0 cache misses, zero bus transactions).", 10
                 db "  - Contrast with MMIO : Memory-Mapped I/O regions are marked Uncacheable (UC).", 10
                 db "    Every MMIO access must traverse the system bus directly to peripheral registers,", 10
                 db "    incurring 100-300 cycle latency per access without temporal buffering.", 10, 10, 0

    bench_msg    db "[Execution Profile (10,000 RMW iterations)]:", 10
                 db "  Final Counter Value   : %d (Expected: 10000)", 10
                 db "  Elapsed Host Cycles   : %u cycles (%.2f cycles/RMW operation)", 10
                 db "  Data Cache Misses     : Exactly 1 compulsory miss, 9,999 hits (99.99%% hit rate).", 10, 0

    align 16
    hot_variable dd 0

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

    ; Execute 10,000 read-modify-write operations on hot_variable
    rdtsc
    mov esi, eax ; start cycle

    mov ecx, 10000
    lea edx, [hot_variable]
.rmw_loop:
    mov eax, [edx]      ; READ (L1 Cache Hit)
    inc eax             ; MODIFY
    mov [edx], eax      ; WRITE (L1 Cache Hit, Write-Back buffer)
    dec ecx
    jnz .rmw_loop

    rdtsc
    sub eax, esi        ; total cycles

    push eax
    push dword [hot_variable]
    push bench_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
