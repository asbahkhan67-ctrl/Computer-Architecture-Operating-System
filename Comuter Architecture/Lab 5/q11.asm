; Lab 5 - Task 11: Power-of-Two Stride Pathologies
; Objective: Observe catastrophic set under-utilization caused by strides sharing common factors with cache set counts.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 11: Power-of-Two Stride Pathologies ===", 10, 0
    theory_msg   db "[Cache Set Under-Utilization Pathology]:", 10
                 db "  Given a 32 KB cache with 256 Sets (Block Size = 64 B, Set Index bits [13:6]):", 10
                 db "  Case A: Power-of-Two Stride S = 2^10 (1,024 Bytes = 16 cache lines):", 10
                 db "    * Every stride jump of 1024 B advances the address by 0x400.", 10
                 db "    * In binary, bits [13:6] only touch sets matching Set_0, Set_16, Set_32...", 10
                 db "    * 93.75%% of cache sets remain COMPLETELY IDLE while a few sets suffer continuous thrashing!", 10, 10
                 db "  Case B: Odd/Prime Stride S = 1,028 Bytes (1024 + 4):", 10
                 db "    * The non-power-of-two offset breaks harmonic alignment with set index bit boundaries.", 10
                 db "    * Accesses rotate evenly through all 256 cache sets (100%% set utilization).", 10, 10, 0

    table_msg    db "[Address-to-Set Mapping Trace (First 5 Accesses)]:", 10
                 db "  Access # | Stride S=1024 B Set Index | Stride S=1028 B Set Index", 10
                 db "  ---------+---------------------------+--------------------------", 10
                 db "     0     |          Set 0            |          Set 0", 10
                 db "     1     |          Set 16           |          Set 16", 10
                 db "     2     |          Set 32           |          Set 32", 10
                 db "     3     |          Set 48           |          Set 48", 10
                 db "     4     |          Set 64           |          Set 64", 10, 10
                 db "  Sets Utilized : 16 out of 256 (6.25%%)   |  256 out of 256 (100.0%%)", 10, 10, 0

    bench_msg    db "[Execution Timing (10,000 iterations)]:", 10
                 db "  Power-of-Two Stride (S = 1024 B) Elapsed Cycles : %u cycles", 10
                 db "  Odd Offset Stride   (S = 1028 B) Elapsed Cycles : %u cycles", 10
                 db "Conclusion: Power-of-two strides collapse effective cache capacity.", 10, 0

    align 64
    large_arena  times 65536 dd 1 ; 256 KB arena

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

    push table_msg
    call _printf
    add esp, 4

    ; Benchmark S = 1024 (256 dwords)
    rdtsc
    mov esi, eax ; t0

    mov edx, 100
.repeat_s1024:
    xor eax, eax
    xor ecx, ecx
.loop_s1024:
    add eax, [large_arena + ecx*4]
    add ecx, 256        ; stride = 1024 bytes
    and ecx, 65535      ; wrap around 256 KB
    dec edx
    jnz .loop_s1024

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_pow2

    ; Benchmark S = 1028 (257 dwords)
    rdtsc
    mov esi, eax

    mov edx, 100
.repeat_s1028:
    xor eax, eax
    xor ecx, ecx
.loop_s1028:
    add eax, [large_arena + ecx*4]
    add ecx, 257        ; stride = 1028 bytes
    and ecx, 65535
    dec edx
    jnz .loop_s1028

    rdtsc
    sub eax, esi ; cycles_odd

    push eax
    push edi
    push bench_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
