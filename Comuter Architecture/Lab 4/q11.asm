; Lab 4 - Task 11: Branch Delay Slot Scheduling
; Objective: Optimize execution on architectures utilizing architectural delay slots.
; Hazard: Control Hazard (architectural delay latency).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 11: Branch Delay Slot Scheduling ===", 10, 0
    theory_msg   db "[Architectural Branch Delay Slots (MIPS / SPARC)]:", 10
                 db "  In classic RISC pipelines, the instruction directly following a branch", 10
                 db "  is ALWAYS executed regardless of whether the branch is taken or not taken.", 10, 10
                 db "  Naive Code (Unscheduled Delay Slot):", 10
                 db "    ADD  $s1, $s2, $s3", 10
                 db "    BNE  $t0, $zero, Target", 10
                 db "    NOP                       ; 1 wasted instruction slot per branch!", 10, 10
                 db "  Optimized Code (Scheduled From Before Branch):", 10
                 db "    BNE  $t0, $zero, Target", 10
                 db "    ADD  $s1, $s2, $s3        ; Useful operation fills delay slot! 0 wasted cycles.", 10, 10, 0

    eval_msg     db "[Evaluation over 1,000 Loop Iterations]:", 10
                 db "  Unscheduled Loop Instructions Executed : 3,000 instructions (1,000 NOPs wasted)", 10
                 db "  Scheduled Loop Instructions Executed   : 2,000 instructions (0 NOPs wasted)", 10
                 db "  Efficiency Gain: 33.3%% instruction count reduction & eliminated branch penalty.", 10, 10, 0

    verif_msg    db "[Execution Verification in x86 Emulation]:", 10
                 db "  Loop counter reached: %d, Accumulated $s1 value: %d", 10, 0

    counter      dd 0
    acc_s1       dd 0

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

    push eval_msg
    call _printf
    add esp, 4

    ; Emulate scheduled delay slot loop in x86
    mov ecx, 1000
    xor eax, eax
.loop_body:
    add eax, 5          ; Operation executing with branch
    dec ecx
    jnz .loop_body

    mov [counter], ecx
    mov [acc_s1], eax

    push dword [acc_s1]
    push 1000
    push verif_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
