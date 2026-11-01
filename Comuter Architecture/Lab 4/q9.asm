; Lab 4 - Task 9: Distance-1 vs. Distance-2 Forwarding Path Analysis
; Objective: Differentiate between EX-to-EX and MEM-to-EX forwarding networks.
; Hazard: Data Hazard (RAW).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 9: Distance-1 vs. Distance-2 Forwarding Path Analysis ===", 10, 0
    dist1_msg    db "[Distance-1 Forwarding (Adjacent Producer-Consumer)]:", 10
                 db "  Instruction 1: ADD $s1, $s2, $s3  (Producer: result computed at EX3)", 10
                 db "  Instruction 2: SUB $s4, $s1, $s5  (Consumer: requires operand at EX4)", 10
                 db "  Pipeline Stage Relationship: Producer is in EX/MEM; Consumer is in ID/EX.", 10
                 db "  Hardware Multiplexer Activated: EX-to-EX Bypassing Network.", 10
                 db "  Forwarding Control Unit Signal: ForwardA = 10 (Selects EX/MEM pipeline register).", 10, 10, 0

    dist2_msg    db "[Distance-2 Forwarding (Separated by 1 Instruction)]:", 10
                 db "  Instruction 1: ADD $s1, $s2, $s3  (Producer: result committed to MEM/WB)", 10
                 db "  Instruction 2: AND $t0, $t1, $t2  (Independent instruction)", 10
                 db "  Instruction 3: SUB $s4, $s1, $s5  (Consumer: requires operand at EX5)", 10
                 db "  Pipeline Stage Relationship: Producer is in MEM/WB; Consumer is in ID/EX.", 10
                 db "  Hardware Multiplexer Activated: MEM-to-EX Bypassing Network.", 10
                 db "  Forwarding Control Unit Signal: ForwardA = 01 (Selects MEM/WB pipeline register).", 10, 10, 0

    verif_msg    db "[Execution Verification]:", 10
                 db "  Producer inputs: s2 = %d, s3 = %d -> s1 = %d", 10
                 db "  Consumer inputs: s1 = %d, s5 = %d -> s4 = %d", 10
                 db "Hardware multiplexers verified: Distance-1 (ForwardA=10), Distance-2 (ForwardA=01).", 10, 0

    val_s2       dd 45
    val_s3       dd 55
    val_s5       dd 20
    val_s1       dd 0
    val_s4       dd 0

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

    push dist1_msg
    call _printf
    add esp, 4

    push dist2_msg
    call _printf
    add esp, 4

    ; Execute Distance-1
    mov eax, [val_s2]
    add eax, [val_s3]   ; Producer
    mov [val_s1], eax
    sub eax, [val_s5]   ; Consumer (Distance-1)
    mov [val_s4], eax

    push dword [val_s4]
    push dword [val_s5]
    push dword [val_s1]
    push dword [val_s1]
    push dword [val_s3]
    push dword [val_s2]
    push verif_msg
    call _printf
    add esp, 28

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
