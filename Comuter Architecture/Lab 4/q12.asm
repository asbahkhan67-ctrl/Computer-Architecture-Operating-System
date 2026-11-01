; Lab 4 - Task 12: Branch Elimination via Predication and Conditional Moves
; Objective: Eliminate control hazards using branchless arithmetic.
; Hazard: Control Hazard (misprediction penalties).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 12: Branch Elimination via Predication & Conditional Moves ===", 10, 0
    theory_msg   db "[Control Hazard Elimination via Branchless Arithmetic]:", 10
                 db "  Random data causes unpredictable branch paths, thrashing the Branch Target Buffer (BTB).", 10
                 db "  Each branch misprediction flushes 14-20 pipeline stages on modern superscalar CPUs.", 10
                 db "  Branchless arithmetic (CMOV or bitmasking) converts control dependencies into data dependencies.", 10, 10, 0

    bench_msg    db "[Benchmark on 10,000 Alternating Positive/Negative Numbers]:", 10
                 db "  1. Branching abs() (CMP + JGE)      : %u cycles", 10
                 db "  2. Predicated abs() (CMOVS)          : %u cycles", 10
                 db "  3. Branchless Bitwise abs() (SAR+XOR): %u cycles", 10
                 db "Verification: Sample abs(-42) = %d, abs(88) = %d", 10
                 db "Conclusion: Predication eliminates branch misprediction flush penalties.", 10, 0

    align 16
    test_vec     times 5000 dd 45, -45
    sample_neg   dd -42
    sample_pos   dd 88
    res_neg      dd 0
    res_pos      dd 0

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

    ; 1. Branching abs
    rdtsc
    mov esi, eax ; t0

    mov ecx, 10000
.loop_branchy:
    mov eax, [test_vec + ecx*4 - 4]
    cmp eax, 0
    jge .skip_neg
    neg eax
.skip_neg:
    dec ecx
    jnz .loop_branchy

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_branchy

    ; 2. Predicated CMOV abs
    rdtsc
    mov esi, eax

    mov ecx, 10000
.loop_cmov:
    mov eax, [test_vec + ecx*4 - 4]
    mov edx, eax
    neg edx
    test eax, eax
    cmovs eax, edx      ; Conditional move on sign flag
    dec ecx
    jnz .loop_cmov

    rdtsc
    sub eax, esi
    mov ebx, eax ; cycles_cmov

    ; 3. Bitwise branchless abs: (x ^ (x >> 31)) - (x >> 31)
    rdtsc
    mov esi, eax

    mov ecx, 10000
.loop_bitwise:
    mov eax, [test_vec + ecx*4 - 4]
    mov edx, eax
    sar edx, 31
    xor eax, edx
    sub eax, edx
    dec ecx
    jnz .loop_bitwise

    rdtsc
    sub eax, esi ; cycles_bitwise

    ; Sample verification
    mov eax, [sample_neg]
    mov edx, eax
    sar edx, 31
    xor eax, edx
    sub eax, edx
    mov [res_neg], eax

    mov eax, [sample_pos]
    mov edx, eax
    sar edx, 31
    xor eax, edx
    sub eax, edx
    mov [res_pos], eax

    push dword [res_pos]
    push dword [res_neg]
    push eax            ; cycles_bitwise
    push ebx            ; cycles_cmov
    push edi            ; cycles_branchy
    push bench_msg
    call _printf
    add esp, 24

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
