; Lab 4 - Task 7: Loop-Carried Accumulation Dependencies
; Objective: Eliminate dependency serializations across loop iterations.
; Hazard: Data Hazard (RAW / Loop-Carried Dependency).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 7: Loop-Carried Accumulation Dependencies ===", 10, 0
    theory_msg   db "[Loop-Carried Dependency Analysis]:", 10
                 db "  Method 1 (Single Accumulator):", 10
                 db "    sum = sum + array[i] -> Every iteration depends on the previous iteration's sum.", 10
                 db "    Strict RAW dependency chain limits throughput to ALU latency.", 10, 10
                 db "  Method 2 (Dual Interleaved Accumulators):", 10
                 db "    acc0 = acc0 + array[i]", 10
                 db "    acc1 = acc1 + array[i+1]", 10
                 db "    Two independent dependency chains enable instruction-level parallelism (ILP).", 10, 10, 0

    bench_msg    db "[Benchmark on 1000 Elements across 10,000 runs]:", 10
                 db "  Single Accumulator Cycles : %u cycles (Sum = %d)", 10
                 db "  Dual Accumulator Cycles   : %u cycles (Sum = %d)", 10
                 db "  Latency Reduction Achieved: Parallel execution hides loop-carried stalls.", 10, 0

    align 16
    array_data   times 1000 dd 2
    sum_single   dd 0
    sum_dual     dd 0

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

    ; Method 1: Single Accumulator
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_single:
    xor eax, eax
    xor ecx, ecx
.loop_single:
    add eax, [array_data + ecx*4] ; RAW dependency on eax each cycle
    inc ecx
    cmp ecx, 1000
    jl .loop_single
    dec edx
    jnz .repeat_single

    mov [sum_single], eax
    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_single

    ; Method 2: Dual Accumulator
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_dual:
    xor eax, eax ; acc0
    xor ebx, ebx ; acc1
    xor ecx, ecx
.loop_dual:
    add eax, [array_data + ecx*4]     ; acc0 independent of acc1
    add ebx, [array_data + ecx*4 + 4] ; acc1 independent of acc0
    add ecx, 2
    cmp ecx, 1000
    jl .loop_dual
    add eax, ebx
    dec edx
    jnz .repeat_dual

    mov [sum_dual], eax
    rdtsc
    sub eax, esi ; cycles_dual

    push dword [sum_dual]
    push eax
    push dword [sum_single]
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
