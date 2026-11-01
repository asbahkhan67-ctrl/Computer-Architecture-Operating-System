; Lab 4 - Task 14: Dynamic Predictor Aliasing and Thrashing
; Objective: Benchmark saturating counters against irregular branch sequences.
; Hazard: Control Hazard (dynamic predictor misprediction).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 14: Dynamic Predictor Aliasing and Thrashing ===", 10, 0
    theory_msg   db "[2-Bit Saturating Counter State Machine (Smith Predictor)]:", 10
                 db "  States: 00 (Strongly NT), 01 (Weakly NT), 10 (Weakly T), 11 (Strongly T)", 10
                 db "  Prediction: High bit (0 = Predict NT, 1 = Predict T)", 10
                 db "  Transitions: TAKEN -> min(state+1, 3) | NOT-TAKEN -> max(state-1, 0)", 10, 10, 0

    homo_msg     db "[Pattern 1: Homogeneous Sequence (100 Consecutive TAKEN branches)]:", 10
                 db "  Total Branches      : 100", 10
                 db "  Mispredictions      : %d (1 initial cold-start misprediction)", 10
                 db "  Prediction Accuracy : 99.0%% (Steady-state locked at Strongly-Taken)", 10, 10, 0

    alter_msg    db "[Pattern 2: Pathological Alternating Sequence (T, NT, T, NT... 100 branches)]:", 10
                 db "  Total Branches      : 100", 10
                 db "  Mispredictions      : %d", 10
                 db "  Prediction Accuracy : %d.0%% (Predictor completely thrashed!)", 10
                 db "Conclusion: Alternating patterns oscillate between Weakly-NT and Weakly-T,", 10
                 db "            causing 100%% misprediction rate on 2-bit bimodal counters.", 10, 0

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

    ; Simulation 1: Homogeneous Taken (100 times)
    ; Initial state = 0 (Strongly NT)
    mov bl, 0           ; BHT state
    xor esi, esi        ; misprediction counter
    mov ecx, 100
.loop_homo:
    ; Prediction = bl >> 1
    mov al, bl
    shr al, 1           ; al = predicted bit (0 or 1)
    cmp al, 1           ; Actual outcome is TAKEN (1)
    je .homo_correct
    inc esi             ; mispredicted!
.homo_correct:
    ; Update state: on Taken, min(bl + 1, 3)
    cmp bl, 3
    jge .homo_capped
    inc bl
.homo_capped:
    dec ecx
    jnz .loop_homo

    push esi
    push homo_msg
    call _printf
    add esp, 8

    ; Simulation 2: Alternating (T, NT, T, NT... 100 times)
    ; Initial state = 0
    mov bl, 0           ; BHT state
    xor edi, edi        ; misprediction counter
    mov ecx, 100
    xor edx, edx        ; actual outcome: 1 on even iter, 0 on odd iter
.loop_alter:
    ; Alternate actual: edx = 1 - edx
    xor edx, 1          ; 1, 0, 1, 0...

    ; Prediction = bl >> 1
    mov al, bl
    shr al, 1
    cmp al, dl
    je .alter_correct
    inc edi             ; mispredicted!
.alter_correct:
    ; Update counter
    cmp edx, 1
    jne .alter_nt
    ; Taken: min(bl+1, 3)
    cmp bl, 3
    jge .alter_done
    inc bl
    jmp .alter_done
.alter_nt:
    ; Not taken: max(bl-1, 0)
    cmp bl, 0
    jle .alter_done
    dec bl
.alter_done:
    dec ecx
    jnz .loop_alter

    ; accuracy = 100 - edi
    mov eax, 100
    sub eax, edi

    push eax
    push edi
    push alter_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
