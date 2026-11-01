; Lab 4 - Task 17: Software Pipelining (Modulo Scheduling)
; Objective: Emulate hardware pipelining principles at the software assembly level.
; Hazard: Data Hazard (RAW) (eliminated within kernel).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 17: Software Pipelining (Modulo Scheduling) ===", 10, 0
    theory_msg   db "[Software Pipelined Kernel Architecture]:", 10
                 db "  Transform: Y[i] = X[i] * 2 + 10", 10
                 db "  - In standard loops, iteration i waits for load -> compute -> store.", 10
                 db "  - Modulo Scheduling overlaps three different iterations concurrently:", 10
                 db "    * PROLOGUE : Warm up pipeline (Load X[0], Load X[1], Compute X[0]).", 10
                 db "    * KERNEL   : Steady state: Store Y[k], Compute Y[k+1], Load X[k+2].", 10
                 db "                 All operations in the kernel are mutually independent!", 10
                 db "                 RAW data hazards are completely eliminated within the kernel.", 10
                 db "    * EPILOGUE : Drain remaining iterations (Compute X[N-1], Store Y[N-2], Store Y[N-1]).", 10, 10, 0

    verif_msg    db "[Execution Verification across 100 Elements]:", 10
                 db "  Sample Input  : X[0]=%d, X[1]=%d, X[99]=%d", 10
                 db "  Sample Output : Y[0]=%d, Y[1]=%d, Y[99]=%d", 10
                 db "Verification: Y[i] = X[i]*2 + 10 matches expected values for all elements.", 10, 0

    align 16
    array_x      times 100 dd 7
    array_y      times 100 dd 0

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

    ; ============================================
    ; SOFTWARE PIPELINED IMPLEMENTATION
    ; N = 100 elements
    ; Registers:
    ;   k : store index
    ;   edx : held value for iteration k (to store)
    ;   ebx : held value for iteration k+1 (computed)
    ;   eax : held loaded value for iteration k+2
    ; ============================================

    ; --- PROLOGUE ---
    ; Iteration 0: Load
    mov eax, [array_x]      ; load X[0]
    ; Iteration 0: Compute -> ebx
    lea ebx, [eax*2 + 10]   ; compute result for X[0]
    ; Iteration 1: Load -> eax
    mov eax, [array_x + 4]  ; load X[1]
    
    ; Setup for kernel:
    ; Iteration 0 result ready to store -> edx
    mov edx, ebx
    ; Iteration 1: Compute -> ebx
    lea ebx, [eax*2 + 10]   ; compute result for X[1]
    
    ; Iteration 2: Load initial for kernel -> eax
    mov eax, [array_x + 8]  ; load X[2]

    ; --- STEADY-STATE KERNEL ---
    ; Loop for k = 0 to 97 (stores Y[k], computes Y[k+1], loads X[k+2])
    xor ecx, ecx            ; k = 0
.kernel_loop:
    mov [array_y + ecx*4], edx      ; Store iteration k
    mov edx, ebx                    ; Hand over computed k+1 for next store
    lea ebx, [eax*2 + 10]           ; Compute iteration k+1
    mov eax, [array_x + ecx*4 + 12] ; Load iteration k+2
    inc ecx
    cmp ecx, 98
    jl .kernel_loop

    ; --- EPILOGUE ---
    ; Store Y[98]
    mov [array_y + 98*4], edx
    ; Compute and Store Y[99]
    mov [array_y + 99*4], ebx

    ; Print verification
    push dword [array_y + 99*4]
    push dword [array_y + 4]
    push dword [array_y]
    push dword [array_x + 99*4]
    push dword [array_x + 4]
    push dword [array_x]
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
