; Lab 4 - Task 2: Multicycle Functional Unit Stalls
; Objective: Profile and mitigate execution latency penalties from multicycle execution units.
; Hazard: Structural / Functional Unit Latency Hazard.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 2: Multicycle Functional Unit Stalls ===", 10, 0
    unsched_msg  db "[Unscheduled Execution Sequence]:", 10
                 db "  DIV R1, R2, R3    ; Multicycle execution (Latency = 12 cycles)", 10
                 db "  MFLO R4           ; Dependent read -> Pipeline STALLS for 11 cycles!", 10
                 db "  ADD R5, R6, R7    ; Independent ALU (1 cycle)", 10
                 db "  SUB R8, R9, R10   ; Independent ALU (1 cycle)", 10
                 db "  XOR R11, R12, R13 ; Independent ALU (1 cycle)", 10
                 db "  Total Pipeline Cycles = 16 (11 stall cycles)", 10, 10, 0
    sched_msg    db "[Rescheduled Execution Sequence]:", 10
                 db "  DIV R1, R2, R3    ; Start multicycle operation", 10
                 db "  ADD R5, R6, R7    ; Independent ALU executes concurrently with DIV!", 10
                 db "  SUB R8, R9, R10   ; Independent ALU executes concurrently with DIV!", 10
                 db "  XOR R11, R12, R13 ; Independent ALU executes concurrently with DIV!", 10
                 db "  MFLO R4           ; Latency masked by 3 cycles -> Stalls reduced to 8 cycles!", 10
                 db "  Total Pipeline Cycles = 13 (8 stall cycles, 18.75%% latency reduction)", 10, 10, 0
    hw_meas_msg  db "[Host Hardware Profile (RDTSC elapsed cycles)]:", 10
                 db "  Unscheduled loop: %u cycles | Rescheduled loop: %u cycles", 10
                 db "Result verification: DIV quotient = %d, Remainder = %d", 10, 0

    dividend     dd 1000000
    divisor      dd 333
    quotient     dd 0
    remainder    dd 0

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

    push unsched_msg
    call _printf
    add esp, 4

    push sched_msg
    call _printf
    add esp, 4

    ; Benchmark Unscheduled
    rdtsc
    mov esi, eax ; t0

    mov ecx, 1000
.loop_unsched:
    mov eax, [dividend]
    xor edx, edx
    mov ebx, [divisor]
    div ebx             ; Multicycle division
    mov [quotient], eax ; immediate dependent read
    mov [remainder], edx
    add ebx, 1          ; independent ALU
    sub ebx, 1
    xor eax, eax
    dec ecx
    jnz .loop_unsched

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_unsched

    ; Benchmark Rescheduled
    rdtsc
    mov esi, eax ; t0

    mov ecx, 1000
.loop_sched:
    mov eax, [dividend]
    xor edx, edx
    mov ebx, [divisor]
    div ebx             ; Multicycle division
    ; independent instructions interleaved
    add ecx, 0
    sub ebx, 0
    mov [quotient], eax ; read quotient after latency mask
    mov [remainder], edx
    dec ecx
    jnz .loop_sched

    rdtsc
    sub eax, esi ; cycles_sched

    push dword [remainder]
    push dword [quotient]
    push eax
    push edi
    push hw_meas_msg
    call _printf
    add esp, 20

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
