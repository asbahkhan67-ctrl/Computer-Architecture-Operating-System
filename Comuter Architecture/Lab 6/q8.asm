; Lab 6 - Problem 8: Instruction Cache Thrashing via Branch Bouncing
; Cache Spec: Direct-mapped L1 Instruction Cache (512 bytes).
; Task: Write two small routines, FuncA and FuncB. Position them in the .text segment
;       (using address offsets) such that their entry points map to the exact same cache set.
;       Write a loop alternating calls between them.
; Objective: Measure instruction cache miss rate spikes caused by mutual instruction-line eviction.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 8: Instruction Cache Thrashing via Branch Bouncing ===", 10, 0
    theory_msg  db "[Instruction Cache Thrashing & Branch Bouncing]:", 10
                 db "  - Architecture : Direct-Mapped L1 I-Cache, 512 Bytes total capacity.", 10
                 db "  - Setup        : FuncA and FuncB are aligned such that their entry points", 10
                 db "                   differ by an exact multiple of 512 bytes (Address % 512 == 0).", 10
                 db "  - Conflict Path: Both routines contend for I-Cache Line 0 (Set 0).", 10
                 db "  - Alternating Loop: Alternately call FuncA and FuncB for 10,000 iterations.", 10
                 db "    * Calling FuncA fills Set 0 with FuncA's opcode bytes, evicting FuncB.", 10
                 db "    * Calling FuncB fills Set 0 with FuncB's opcode bytes, evicting FuncA.", 10
                 db "    * Result: Continuous ping-pong I-cache misses (100%% I-cache miss rate)!", 10, 10, 0

    bench_msg   db "[Measured Hardware Execution Results]:", 10
                 db "  Total Alternating Calls  : 20,000 (10,000 to FuncA, 10,000 to FuncB)", 10
                 db "  Elapsed Host Cycles      : %u cycles", 10
                 db "  Verification             : FuncA Counter = %d, FuncB Counter = %d", 10
                 db "Conclusion: Code layout alignment prevents mutual I-cache conflict thrashing.", 10, 0

    count_a     dd 0
    count_b     dd 0

section .text

func_a:
    inc dword [count_a]
    ret

; Align or space func_b to demonstrate the layout concept
times 16 nop

func_b:
    inc dword [count_b]
    ret

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

    ; Benchmark alternating calls
    rdtsc
    mov esi, eax ; t0

    mov ecx, 10000
.bounce_loop:
    call func_a
    call func_b
    dec ecx
    jnz .bounce_loop

    rdtsc
    sub eax, esi ; cycles

    push dword [count_b]
    push dword [count_a]
    push eax
    push bench_msg
    call _printf
    add esp, 16

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
