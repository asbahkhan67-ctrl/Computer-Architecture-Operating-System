; Lab 4 - Task 1: Dual-Port vs. Single-Port Memory Contention
; Objective: Trace the impact of unified memory architecture versus split Harvard architecture.
; Structural Hazard: Memory port conflict during concurrent IF and MEM stages.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 1: Dual-Port vs. Single-Port Memory Contention ===", 10, 0
    desc_msg     db "Simulating 100 iterations of tight loop with 4 memory ops per iteration (2 lw, 2 sw)", 10, 0
    harvard_msg  db "[Split Harvard Architecture (Dual-Port / Separate I-D Cache)]:", 10
                 db "  - IF and MEM stages access separate ports concurrently.", 10
                 db "  - Structural Stalls = 0", 10
                 db "  - Total Execution Cycles: %d (CPI: %d.%02d)", 10, 10, 0
    unified_msg  db "[Unified Memory Architecture (Single-Port / Von Neumann)]:", 10
                 db "  - IF and MEM stages compete for single port on every lw/sw.", 10
                 db "  - Structural Stalls = %d (4 stalls/iteration)", 10
                 db "  - Total Execution Cycles: %d (CPI: %d.%02d)", 10, 10, 0
    summary_msg  db "Conclusion: Unified memory introduces %d stall cycles (%.1f%% execution slowdown).", 10, 0

    array_data   times 256 dd 1

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

    push desc_msg
    call _printf
    add esp, 4

    ; Loop simulation:
    ; 100 iterations.
    ; Each iteration has 6 instructions: 2 lw, 1 add, 2 sw, 1 bne
    ; Split Harvard: 6 instrs * 100 = 600 instrs + 4 cycle pipeline latency = 604 cycles.
    ; CPI = 604 / 600 = 1.006 (approx 1.01)
    mov eax, 604
    mov ecx, 100
    xor edx, edx
    div ecx ; eax = 6, edx = 4 (for CPI calculation: 604/600 ~ 1.00)
    
    ; Split Harvard output
    push 1
    push 1
    push 604
    push harvard_msg
    call _printf
    add esp, 16

    ; Unified Memory:
    ; 4 memory operations per iteration contend with IF.
    ; Each contention causes 1 pipeline bubble stall = 4 * 100 = 400 stalls.
    ; Total cycles = 604 + 400 = 1004 cycles. CPI = 1004 / 600 = 1.67.
    push 67
    push 1
    push 1004
    push 400
    push unified_msg
    call _printf
    add esp, 20

    ; Real execution of loop in x86
    mov ecx, 100
    lea esi, [array_data]
.sim_loop:
    mov eax, [esi]       ; lw $t0
    mov ebx, [esi + 4]   ; lw $t1
    add eax, ebx         ; add $t2, $t0, $t1
    mov [esi + 8], eax   ; sw $t2
    mov [esi + 12], ebx  ; sw $t1
    dec ecx
    jnz .sim_loop

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
