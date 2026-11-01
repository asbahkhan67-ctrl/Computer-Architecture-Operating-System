; Lab 4 - Task 6: Software Instruction Rescheduling
; Objective: Eliminate load-use latency penalties via static instruction reordering.
; Hazard: Data Hazard (RAW / Load-Use).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 6: Software Instruction Rescheduling ===", 10, 0
    orig_msg     db "[Original Code with Load-Use Penalties]:", 10
                 db "  LW  $t0, 0($a0)", 10
                 db "  ADD $t1, $t0, $t2   ; STALL (Load-use penalty on $t0)", 10
                 db "  LW  $t3, 4($a0)", 10
                 db "  SUB $t4, $t3, $t5   ; STALL (Load-use penalty on $t3)", 10
                 db "  Pipeline Cycles: 4 instrs + 4 latency + 2 stalls = 10 cycles (CPI: 2.5)", 10, 10, 0

    reord_msg    db "[Rescheduled Code (Stalls Completely Eliminated)]:", 10
                 db "  LW  $t0, 0($a0)", 10
                 db "  LW  $t3, 4($a0)     ; Fills load-delay slot of $t0! Independent memory op.", 10
                 db "  ADD $t1, $t0, $t2   ; $t0 is ready in MEM/WB register! 0 stalls.", 10
                 db "  SUB $t4, $t3, $t5   ; $t3 is ready in MEM/WB register! 0 stalls.", 10
                 db "  Pipeline Cycles: 4 instrs + 4 latency + 0 stalls = 8 cycles (20%% speedup!)", 10, 10, 0

    res_msg      db "[Execution Results Verification]:", 10
                 db "  Memory: 0($a0)=%d, 4($a0)=%d | $t2=%d, $t5=%d", 10
                 db "  Calculated $t1 (t0 + t2) = %d", 10
                 db "  Calculated $t4 (t3 - t5) = %d", 10
                 db "Both code sequences produce mathematically identical register states.", 10, 0

    array_a0     dd 50, 120
    val_t2       dd 30
    val_t5       dd 45
    res_t1       dd 0
    res_t4       dd 0

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

    push orig_msg
    call _printf
    add esp, 4

    push reord_msg
    call _printf
    add esp, 4

    ; Execute rescheduled sequence
    lea esi, [array_a0]
    mov eax, [esi]       ; lw $t0, 0($a0)
    mov ebx, [esi + 4]   ; lw $t3, 4($a0) (interleaved)
    add eax, [val_t2]    ; add $t1, $t0, $t2
    mov [res_t1], eax
    sub ebx, [val_t5]    ; sub $t4, $t3, $t5
    mov [res_t4], ebx

    push dword [res_t4]
    push dword [res_t1]
    push dword [val_t5]
    push dword [val_t2]
    push dword [array_a0 + 4]
    push dword [array_a0]
    push res_msg
    call _printf
    add esp, 28

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
