; Lab 4 - Task 18: Subroutine Call and Return Pipeline Overhead
; Objective: Quantify control stalls associated with indirect jumps.
; Hazard: Control Hazard (jump register latency).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 18: Subroutine Call and Return Pipeline Overhead ===", 10, 0
    theory_msg   db "[Subroutine Linkage Pipeline Cost Analysis]:", 10
                 db "  Inlined Execution : Single continuous instruction stream, 0 control redirection.", 10
                 db "  Subroutine Call   : Requires CALL (push EIP, branch to target) + RET (pop EIP, indirect jump).", 10
                 db "  Pipeline Penalties: Return address stack (RSB) prediction, branch target latency,", 10
                 db "                      and stack pointer modifications (PUSH/POP data hazards).", 10, 10, 0

    bench_msg    db "[Benchmark on 100,000 Iterations]:", 10
                 db "  Inlined Loop Elapsed Cycles    : %u cycles (%.2f cycles/iteration)", 10
                 db "  Subroutine Loop Elapsed Cycles : %u cycles (%.2f cycles/iteration)", 10
                 db "  Overhead per Function Call     : %u cycles", 10
                 db "Conclusion: Function call/return linkage imposes measurable pipeline overhead.", 10, 0

section .text

; Small subroutine to test call/ret linkage overhead
calc_subroutine:
    add eax, 3
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

    ; 1. Inlined Loop
    rdtsc
    mov esi, eax ; t0

    xor eax, eax
    mov ecx, 100000
.loop_inlined:
    add eax, 3          ; Inlined body
    dec ecx
    jnz .loop_inlined

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_inlined

    ; 2. Subroutine Call Loop
    rdtsc
    mov esi, eax ; t0

    xor eax, eax
    mov ecx, 100000
.loop_call:
    call calc_subroutine
    dec ecx
    jnz .loop_call

    rdtsc
    sub eax, esi
    mov ebx, eax ; cycles_call

    ; Calculate overhead = (cycles_call - cycles_inlined) / 100000
    mov edx, ebx
    sub edx, edi
    mov eax, edx
    xor edx, edx
    mov ecx, 100000
    div ecx             ; eax = average overhead per call

    push eax            ; overhead per call
    push ebx            ; cycles call
    push edi            ; cycles inlined
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
