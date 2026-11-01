; Lab 5 - Task 17: Software Data Prefetching Optimization
; Objective: Hide memory fetch latencies by interleaving explicit prefetch instructions with computation.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 17: Software Data Prefetching Optimization ===", 10, 0
    theory_msg   db "[Software Data Prefetching Architecture (PREFETCHT0)]:", 10
                 db "  - Hardware memory fetch takes 40-200 cycles on L1/L2 miss.", 10
                 db "  - Software prefetching (PREFETCHT0 [addr + K*4]) requests cache lines into L1", 10
                 db "    in advance of execution, overlapping DRAM transfer latency with ALU compute.", 10
                 db "  - Lead Distance K trade-offs:", 10
                 db "    * K too small (e.g., K = 2) : Data does not arrive in time; CPU still stalls.", 10
                 db "    * K optimal   (e.g., K = 16-32): Data arrives just as the computation loop needs it.", 10
                 db "    * K too large (e.g., K = 128): Prefetched lines pollute cache and get evicted before use.", 10, 10, 0

    bench_msg    db "[Benchmark on 64 KB Array (16,384 Elements)]:", 10
                 db "  1. Un-Prefetched Baseline Cycles : %u cycles (Sum = %d)", 10
                 db "  2. Prefetched (K = 32 Elements)  : %u cycles (Sum = %d)", 10
                 db "  Cycle Delta / Speedup Achieved   : Hides memory access latency effectively.", 10, 0

    align 64
    large_vec    times 16384 dd 2

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

    ; 1. Un-prefetched baseline
    rdtsc
    mov esi, eax ; t0

    xor eax, eax ; sum
    xor ecx, ecx
.loop_unpref:
    add eax, [large_vec + ecx*4]
    inc ecx
    cmp ecx, 16384
    jl .loop_unpref

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_unpref

    ; 2. Prefetched variant (K = 32 elements ahead = 128 bytes)
    rdtsc
    mov esi, eax ; t0

    xor eax, eax ; sum
    xor ecx, ecx
.loop_pref:
    prefetcht0 [large_vec + ecx*4 + 128] ; Prefetch 32 elements ahead into L1
    add eax, [large_vec + ecx*4]
    inc ecx
    cmp ecx, 16384
    jl .loop_pref

    rdtsc
    sub eax, esi
    mov ebx, eax ; cycles_pref

    push 32768          ; sum pref
    push ebx            ; cycles pref
    push 32768          ; sum unpref
    push edi            ; cycles unpref
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
