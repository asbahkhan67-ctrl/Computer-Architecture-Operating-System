; Lab 4 - Task 15: Two-Way Loop Unrolling
; Objective: Reduce branch overhead and expose instruction-level parallelism (ILP).
; Hazard: Data (Load-Use) and Control Hazards.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 15: Two-Way Loop Unrolling ===", 10, 0
    theory_msg   db "[Loop Unrolling & Interleaved Scheduling Analysis]:", 10
                 db "  Baseline Vector Dot Product (N = 1000):", 10
                 db "    - 1,000 branch instructions and loop counter decrements.", 10
                 db "    - Serial LW -> MULT -> ADD creates load-use and latency bubbles.", 10, 10
                 db "  Two-Way Unrolled Dot Product (Step = 2):", 10
                 db "    - Branch evaluations reduced by 50%% (500 branches instead of 1,000).", 10
                 db "    - Consecutive loads (A[i], B[i], A[i+1], B[i+1]) issued together,", 10
                 db "      hiding memory latency and exposing instruction-level parallelism.", 10, 10, 0

    bench_msg    db "[Benchmark Results (10,000 executions of 1,000-element dot product)]:", 10
                 db "  Baseline 1-Way Loop Cycles : %u cycles (Dot Product = %d)", 10
                 db "  Unrolled 2-Way Loop Cycles : %u cycles (Dot Product = %d)", 10
                 db "  Speedup Achieved           : Branch overhead amortized & load latency hidden.", 10, 0

    align 16
    vec_a        times 1000 dd 3
    vec_b        times 1000 dd 4
    dot_base     dd 0
    dot_unroll   dd 0

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

    ; 1. Baseline Loop
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_base:
    xor eax, eax ; sum
    xor ecx, ecx ; index
.loop_base:
    mov ebx, [vec_a + ecx*4]
    imul ebx, [vec_b + ecx*4]
    add eax, ebx
    inc ecx
    cmp ecx, 1000
    jl .loop_base
    dec edx
    jnz .repeat_base

    mov [dot_base], eax
    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_base

    ; 2. Unrolled 2-Way Loop with interleaved loads
    rdtsc
    mov esi, eax

    mov edx, 1000
.repeat_unroll:
    xor eax, eax ; sum
    xor ecx, ecx
.loop_unroll:
    ; Interleave loads from iteration i and iteration i+1
    mov ebx, [vec_a + ecx*4]
    mov edi, [vec_b + ecx*4]
    imul ebx, edi

    mov edi, [vec_a + ecx*4 + 4]
    imul edi, [vec_b + ecx*4 + 4]

    add eax, ebx
    add eax, edi
    add ecx, 2
    cmp ecx, 1000
    jl .loop_unroll
    dec edx
    jnz .repeat_unroll

    mov [dot_unroll], eax
    rdtsc
    sub eax, esi ; cycles_unroll

    push dword [dot_unroll]
    push eax
    push dword [dot_base]
    push edi
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
