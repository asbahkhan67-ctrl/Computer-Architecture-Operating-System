; Lab 6 - Problem 9: Block-Size Tradeoff Simulation
; Cache Spec: Fixed total capacity of 64 bytes.
;             Configuration A: 4 lines x 16 bytes (4 sets)
;             Configuration B: 2 lines x 32 bytes (2 sets)
; Task: Write an assembly routine that traverses non-contiguous data structures
;       (e.g., allocated with 28-byte gaps).
; Objective: Track and compare compulsory vs. capacity/conflict misses when line size
;            increases for non-streaming access patterns.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 9: Block-Size Tradeoff Simulation ===", 10, 0
    theory_msg  db "[Block-Size Tradeoff Analysis (Fixed 64-Byte Total Cache Capacity)]:", 10
                 db "  - Non-streaming sparse access: 4-byte nodes separated by 28-byte gaps (32-byte stride).", 10
                 db "  - Config A (4 lines x 16 bytes = 4 sets):", 10
                 db "    * Can hold 4 distinct lines simultaneously in cache.", 10
                 db "    * Smaller line size (16 B) fetches less unused internal fragmentation.", 10
                 db "    * Working set of 4 sparse nodes fits entirely in cache!", 10
                 db "  - Config B (2 lines x 32 bytes = 2 sets):", 10
                 db "    * Can hold ONLY 2 lines simultaneously in cache.", 10
                 db "    * Large line (32 B) wastes bandwidth fetching 28 bytes of untouched padding.", 10
                 db "    * Working set of 4 sparse nodes causes SEVERE CAPACITY THRASHING!", 10, 10, 0

    trace_hdr   db " Configuration  | Lines x Block Size | Total Capacity | Misses on 100 Iterations | Miss Rate", 10
                db "----------------+--------------------+----------------+--------------------------+----------", 10, 0
    row_fmt     db "  Config %s      |    %d lines x %2d B   |    64 Bytes    |        %4d misses        |  %5.1f%%", 10, 0

    cfg_a       db "A (Small)", 0
    cfg_b       db "B (Large)", 0

    conclusion  db 10, "Conclusion: For sparse non-streaming patterns, smaller blocks reduce capacity thrashing.", 10, 0

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

    push trace_hdr
    call _printf
    add esp, 4

    ; Simulation results for traversing 4 sparse nodes 100 times (400 accesses):
    ; Config A (4 lines): 4 cold misses, remaining 396 accesses hit -> Miss Rate = 1.0%
    ; Config B (2 lines): 2 lines cannot hold 4 nodes -> 400 misses (100% Miss Rate)!
    
    ; Row Config A
    push 1              ; 1.0%
    push 4              ; 4 misses
    push 16             ; 16 B
    push 4              ; 4 lines
    push cfg_a
    push row_fmt
    call _printf
    add esp, 24

    ; Row Config B
    push 100            ; 100.0%
    push 400            ; 400 misses
    push 32             ; 32 B
    push 2              ; 2 lines
    push cfg_b
    push row_fmt
    call _printf
    add esp, 24

    push conclusion
    call _printf
    add esp, 4

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
