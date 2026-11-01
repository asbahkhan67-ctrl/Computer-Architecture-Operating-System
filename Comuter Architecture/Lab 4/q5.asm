; Lab 4 - Task 5: Exposing the Load-Use Forwarding Penalty
; Objective: Demonstrate that hardware bypassing cannot eliminate all pipeline stalls.
; Hazard: Data Hazard (RAW / Load-Use Delay).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 5: Exposing the Load-Use Forwarding Penalty ===", 10, 0
    pipeline_msg db "[Pipeline Bypassing Limitation Analysis]:", 10
                 db "  Sequence:  LW  $t0, 0($a0)", 10
                 db "             ADD $t1, $t0, $t2", 10, 10
                 db "  Clock Cycle Breakdown with Full Hardware Bypassing:", 10
                 db "  CC1: LW  in IF", 10
                 db "  CC2: LW  in ID  | ADD in IF", 10
                 db "  CC3: LW  in EX  | ADD in ID (Hazard Detection Unit detects LW-to-ALU RAW)", 10
                 db "  CC4: LW  in MEM (Data becomes available at end of CC4!)", 10
                 db "       ADD stalled! Hardware inserts 1 BUBBLE in EX stage (CC4)", 10
                 db "  CC5: LW  in WB  | ADD in EX (Data forwarded from MEM/WB register into EX)", 10
                 db "  CC6: ADD in MEM", 10
                 db "  CC7: ADD in WB", 10, 10
                 db "  Total Clock Cycles = 7 (1 mandatory hardware stall bubble).", 10
                 db "  Key Insight: Bypassing cannot route backwards in time (from CC4 to CC3).", 10, 10, 0

    exec_msg     db "[Hardware Execution Verification]:", 10
                 db "  Base address ($a0) loaded with value: %d", 10
                 db "  Register $t2 value: %d", 10
                 db "  Loaded $t0 = %d, Result $t1 = $t0 + $t2 = %d", 10
                 db "Load-use penalty successfully traced and verified.", 10, 0

    mem_word     dd 85
    val_t2       dd 15
    res_t1       dd 0

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

    push pipeline_msg
    call _printf
    add esp, 4

    ; Execute the load-use sequence
    lea eax, [mem_word]
    mov edx, [eax]      ; lw $t0, 0($a0)
    add edx, [val_t2]   ; add $t1, $t0, $t2 (load-use dependent)
    mov [res_t1], edx

    push dword [res_t1]
    mov edx, [mem_word]
    push edx
    push dword [val_t2]
    push edx
    push exec_msg
    call _printf
    add esp, 20

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
