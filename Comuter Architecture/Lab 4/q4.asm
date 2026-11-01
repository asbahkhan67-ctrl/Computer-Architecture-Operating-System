; Lab 4 - Task 4: Software Hazard Resolution via NOP Insertion
; Objective: Mitigate data hazards when hardware forwarding is disabled.
; Hazard: Data Hazard (RAW) under non-forwarding pipeline configurations.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 4: Software Hazard Resolution via NOP Insertion ===", 10, 0
    theory_msg   db "[Pipeline Timing Analysis without Hardware Forwarding]:", 10
                 db "  Producer: ADD R1, R2, R5  -> Writes R1 in WB stage (first half of Cycle 5)", 10
                 db "  Consumer: ADD R4, R1, R5  -> Reads R1 in ID stage (second half of Cycle)", 10, 10
                 db "  If 0 NOPs: Consumer ID occurs at Cycle 3 -> Reads STALE value!", 10
                 db "  If 1 NOP : Consumer ID occurs at Cycle 4 -> Reads STALE value!", 10
                 db "  If 2 NOPs: Consumer ID occurs at Cycle 5 -> Reads UPDATED value! (Hazard Resolved)", 10
                 db "  Conclusion: Exact minimum NOPs required = 2.", 10, 10, 0

    stale_msg    db "[Simulation 1: Non-forwarded execution with 0 NOPs (Stale Read)]:", 10
                 db "  Initial R1 = %d, R2 = %d, R3 = %d, R5 = %d", 10
                 db "  Producer calculates R1 = R2 + R3 = %d (committed at WB5)", 10
                 db "  Consumer in ID3 reads stale R1 = %d -> R4 = stale_R1 + R5 = %d (INCORRECT!)", 10, 10, 0

    valid_msg    db "[Simulation 2: Software Scheduled with 2 NOPs (Correct Execution)]:", 10
                 db "  ADD R1, R2, R3", 10
                 db "  NOP  ; Software delay slot 1", 10
                 db "  NOP  ; Software delay slot 2", 10
                 db "  ADD R4, R1, R5", 10
                 db "  Consumer in ID5 reads updated R1 = %d -> R4 = R1 + R5 = %d (CORRECT!)", 10, 0

    r1_initial   dd 5
    r2_val       dd 10
    r3_val       dd 20
    r5_val       dd 4
    r1_updated   dd 0
    r4_stale     dd 0
    r4_correct   dd 0

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

    ; Calculate updated R1
    mov eax, [r2_val]
    add eax, [r3_val]
    mov [r1_updated], eax ; 10 + 20 = 30

    ; Stale calculation: uses initial R1 (5) + R5 (4) = 9
    mov eax, [r1_initial]
    add eax, [r5_val]
    mov [r4_stale], eax

    push dword [r4_stale]
    push dword [r1_initial]
    push dword [r1_updated]
    push dword [r5_val]
    push dword [r3_val]
    push dword [r2_val]
    push dword [r1_initial]
    push stale_msg
    call _printf
    add esp, 32

    ; Correct calculation: uses updated R1 (30) + R5 (4) = 34
    nop
    nop
    mov eax, [r1_updated]
    add eax, [r5_val]
    mov [r4_correct], eax

    push dword [r4_correct]
    push dword [r1_updated]
    push valid_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
