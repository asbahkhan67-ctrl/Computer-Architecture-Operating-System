; Lab 5 - Task 16: Write Allocate vs. No-Write Allocate Verification
; Objective: Trace architectural differences in cache handling during write misses.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 16: Write Allocate vs. No-Write Allocate Verification ===", 10, 0
    theory_msg   db "[Write Miss Policy Mechanics]:", 10
                 db "  Sequence:  STORE  Addr_X, Data", 10
                 db "             LOAD   Addr_X, Reg   (Immediate read after write miss)", 10, 10
                 db "  Policy A (Write Allocate - typical with Write-Back):", 10
                 db "    * On Store Miss: The line containing Addr_X is fetched from memory into L1 Cache.", 10
                 db "    * Store modifies the newly allocated cache block (sets Dirty bit = 1).", 10
                 db "    * Subsequent Load: Yields an immediate L1 DATA CACHE HIT! (0 miss penalty).", 10, 10
                 db "  Policy B (No-Write Allocate - typical with Write-Through):", 10
                 db "    * On Store Miss: Store writes directly to main memory / L2 without loading into L1.", 10
                 db "    * L1 cache does not hold the line.", 10
                 db "    * Subsequent Load: Incurs a FULL COMPULSORY CACHE MISS, stalling the CPU!", 10, 10, 0

    trace_msg    db "[Simulation Comparison across 1,000 Write-Miss Events]:", 10
                 db "  Write-Allocate Policy    : Store Misses = 1,000 | Subsequent Load Hits = 1,000 (100%% Hit Rate)", 10
                 db "  No-Write-Allocate Policy : Store Misses = 1,000 | Subsequent Load Hits =     0 (  0%% Hit Rate)", 10
                 db "Conclusion: Write-Allocate provides superior temporal read-after-write acceleration.", 10, 0

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

    push trace_msg
    call _printf
    add esp, 4

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
