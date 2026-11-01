; Lab 4 - Task 10: Quantifying Taken vs. Not-Taken Branch Penalties
; Objective: Measure pipeline flushing costs on taken vs. fall-through branches.
; Hazard: Control Hazard (pipeline flush penalties).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 10: Quantifying Taken vs. Not-Taken Branch Penalties ===", 10, 0
    theory_msg   db "[Static Hardware Branch Prediction Mechanics]:", 10
                 db "  Static branch predictors assume fall-through (Predict Not-Taken) for forward branches.", 10
                 db "  - When branch is NOT TAKEN: Prediction is correct -> 0 pipeline flush penalty.", 10
                 db "  - When branch is TAKEN: Pipeline must flush instructions in IF/ID stages -> 2-3 stall cycles.", 10, 10, 0

    bench_msg    db "[Benchmark Results (1,000 iterations each)]:", 10
                 db "  Branch TAKEN 95%% of the time     : %u cycles", 10
                 db "  Branch NOT-TAKEN 95%% of the time : %u cycles", 10
                 db "  Cycle Difference                 : %d cycles", 10
                 db "Conclusion: Taken branches incur pipeline redirect flush overhead.", 10, 0

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

    ; Benchmark 1: 95% TAKEN
    ; Condition: if (i % 20 != 0) -> jump taken (19 out of 20 times = 95%)
    rdtsc
    mov esi, eax ; start cycle

    mov ecx, 1000
    xor edx, edx
.loop_taken_95:
    mov eax, ecx
    and eax, 15         ; fast pseudo-mod
    cmp eax, 0
    jne .taken_target   ; 93.75% ~ 95% taken
    nop
.taken_target:
    dec ecx
    jnz .loop_taken_95

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_taken

    ; Benchmark 2: 95% NOT-TAKEN
    ; Condition: if (i % 16 == 0) -> jump taken (1 out of 16 times = 6.25% taken, 93.75% not taken)
    rdtsc
    mov esi, eax

    mov ecx, 1000
.loop_nottaken_95:
    mov eax, ecx
    and eax, 15
    cmp eax, 0
    je .rarely_taken    ; NOT TAKEN most of the time!
    nop
    jmp .cont
.rarely_taken:
    nop
.cont:
    dec ecx
    jnz .loop_nottaken_95

    rdtsc
    sub eax, esi ; cycles_nottaken

    mov edx, edi
    sub edx, eax ; diff = cycles_taken - cycles_nottaken

    push edx
    push eax
    push edi
    push bench_msg
    call _printf
    add esp, 16

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
