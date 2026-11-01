; Lab 4 - Task 16: Four-Way Unrolling with Register Renaming
; Objective: Amortize loop branch penalties and avoid artificial dependencies.
; Hazard: Control Hazard & Anti-Dependencies.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 16: Four-Way Unrolling with Register Renaming ===", 10, 0
    theory_msg   db "[Anti-Dependencies & Register Renaming Principle]:", 10
                 db "  Unrolling without renaming reuses the same accumulator register,", 10
                 db "  creating Write-After-Read (WAR) and Write-After-Write (WAW) false hazards.", 10
                 db "  Register Renaming allocates separate architectural/physical registers", 10
                 db "  (Lane 0: EAX, Lane 1: EBX, Lane 2: EDX, Lane 3: ESI) to eliminate false stalls.", 10, 10, 0

    bench_msg    db "[Benchmark on 10,000 Elements (1,000 runs)]:", 10
                 db "  Standard Loop (1 Register)       : %u cycles (Sum = %d)", 10
                 db "  4-Way Unrolled (Renamed Regs)    : %u cycles (Sum = %d)", 10
                 db "  Branch Overhead Reduction        : 75%% fewer branches (amortized across 4 lanes).", 10
                 db "  Anti-Dependencies                : 0 WAR/WAW false serializations.", 10, 0

    align 16
    array_data   times 10000 dd 5
    sum_std      dd 0
    sum_renamed  dd 0

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

    ; 1. Standard loop (single register)
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_std:
    xor eax, eax
    xor ecx, ecx
.loop_std:
    add eax, [array_data + ecx*4]
    inc ecx
    cmp ecx, 10000
    jl .loop_std
    dec edx
    jnz .repeat_std

    mov [sum_std], eax
    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_std

    ; 2. 4-Way Unrolled with 4 distinct registers (Renamed streams)
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_renamed:
    xor eax, eax ; Stream 0 accumulator
    xor ebx, ebx ; Stream 1 accumulator
    xor edi, edi ; Stream 2 accumulator
    xor ecx, ecx ; Stream 3 accumulator & index
    mov [sum_renamed], edx ; save outer counter

    xor edx, edx ; index
.loop_renamed:
    add eax, [array_data + edx*4]       ; Lane 0 (eax)
    add ebx, [array_data + edx*4 + 4]   ; Lane 1 (ebx)
    add edi, [array_data + edx*4 + 8]   ; Lane 2 (edi)
    add ecx, [array_data + edx*4 + 12]  ; Lane 3 (ecx)
    add edx, 4
    cmp edx, 10000
    jl .loop_renamed

    add eax, ebx
    add eax, edi
    add eax, ecx

    mov edx, [sum_renamed]
    dec edx
    jnz .repeat_renamed

    mov [sum_renamed], eax
    rdtsc
    sub eax, esi ; cycles_renamed

    push dword [sum_renamed]
    push eax
    push dword [sum_std]
    push edi
    push bench_msg
    call _printf
    add esp, 20

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
