; Lab 4 - Task 13: Static Heuristic Alignment: BTFN Evaluation
; Objective: Analyze Backwards-Taken, Forwards-Not-Taken (BTFN) branch prediction.
; Hazard: Control Hazard.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 13: Static Heuristic Alignment: BTFN Evaluation ===", 10, 0
    theory_msg   db "[BTFN (Backwards-Taken, Forwards-Not-Taken) Static Heuristic]:", 10
                 db "  Static branch prediction rules:", 10
                 db "    1. Backwards branch (target address < PC): Predict TAKEN (assumed to be loop back-edge).", 10
                 db "    2. Forwards branch  (target address > PC): Predict NOT-TAKEN (assumed to be error/exit).", 10, 10
                 db "  While Loop Construct (Forward Branch at Header):", 10
                 db "    Header: CMP i, N -> JGE Exit (Forward branch predicted NOT-TAKEN).", 10
                 db "    At loop end: JMP Header (Unconditional redirect).", 10, 10
                 db "  Do-While Loop Construct (Backwards Branch at Footer):", 10
                 db "    Loop Body: ... -> INC i -> CMP i, N -> JL Loop Body (Backwards branch predicted TAKEN).", 10
                 db "    Matches BTFN heuristic for every iteration except the single loop termination!", 10, 10, 0

    bench_msg    db "[Benchmark on 50,000 Iterations]:", 10
                 db "  Forward-Branch While Loop Cycles   : %u cycles", 10
                 db "  Backwards-Branch Do-While Cycles   : %u cycles", 10
                 db "  Cycle Difference                   : %d cycles", 10
                 db "Conclusion: Backwards-branching alignment reduces branch redirect stalls.", 10, 0

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

    ; 1. Forward-branch while loop
    rdtsc
    mov esi, eax ; t0

    xor ecx, ecx
    xor edx, edx
.while_header:
    cmp ecx, 50000
    jge .while_exit     ; Forward conditional branch
    add edx, ecx
    inc ecx
    jmp .while_header   ; Unconditional jump back
.while_exit:

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_while

    ; 2. Backwards-branch do-while loop
    rdtsc
    mov esi, eax

    xor ecx, ecx
    xor edx, edx
.dowhile_body:
    add edx, ecx
    inc ecx
    cmp ecx, 50000
    jl .dowhile_body    ; Backwards conditional branch (BTFN predicted TAKEN)

    rdtsc
    sub eax, esi ; cycles_dowhile

    mov edx, edi
    sub edx, eax ; diff = cycles_while - cycles_dowhile

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
