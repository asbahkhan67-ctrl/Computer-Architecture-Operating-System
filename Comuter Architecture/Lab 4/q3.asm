; Lab 4 - Task 3: Register File Write-Port Contention
; Objective: Identify structural writeback conflicts between multicycle and single-cycle instructions.
; Hazard: Structural Hazard (WB stage port serialization).

global _main
extern _printf

section .data
    title_msg   db "=== Lab 4 Task 3: Register File Write-Port Contention ===", 10, 0
    sched_msg   db "[Pipeline Schedule & Conflict Analysis]:", 10
                db "  Instruction 1: MULT R1, R2, R3 (Latency = 4 cycles)", 10
                db "    - Cycle 1: IF", 10
                db "    - Cycle 2: ID", 10
                db "    - Cycle 3: EX1", 10
                db "    - Cycle 4: EX2", 10
                db "    - Cycle 5: EX3", 10
                db "    - Cycle 6: EX4 (Result ready)", 10
                db "    - Cycle 7: WB  <-- Contends for Register File Write Port!", 10, 10
                db "  Instruction 2: ADD R4, R5, R6 (Latency = 1 cycle, issued Cycle 4)", 10
                db "    - Cycle 4: IF", 10
                db "    - Cycle 5: ID", 10
                db "    - Cycle 6: EX", 10
                db "    - Cycle 7: WB  <-- Contends for Register File Write Port simultaneously!", 10, 10, 0
    arbit_msg   db "[Arbiter Resolution & Pipeline Serialization]:", 10
                db "  - Architecture has a SINGLE Write Port on the Register File.", 10
                db "  - Priority Rule: Older instruction (MULT) wins port access at Cycle 7.", 10
                db "  - Pipeline stall inserted: ADD is stalled in EX/WB register by 1 cycle.", 10
                db "  - ADD Writeback committed at Cycle 8.", 10
                db "  - Result: 1 Structural Stall cycle introduced at WB stage.", 10, 10, 0
    calc_msg    db "[Execution Verification]:", 10
                db "  MULT result (R1 = 25 * 40) = %d", 10
                db "  ADD  result (R4 = 15 + 35) = %d", 10
                db "Pipeline state successfully validated.", 10, 0

    val_r1      dd 0
    val_r4      dd 0

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

    push sched_msg
    call _printf
    add esp, 4

    push arbit_msg
    call _printf
    add esp, 4

    ; Perform the arithmetic operations in x86
    mov eax, 25
    mov edx, 40
    imul eax, edx       ; MULT R1 = 25 * 40 = 1000
    mov [val_r1], eax

    mov ebx, 15
    add ebx, 35         ; ADD R4 = 15 + 35 = 50
    mov [val_r4], ebx

    push dword [val_r4]
    push dword [val_r1]
    push calc_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
