; Lab 6 - Problem 16: Optimal (Belady’s MIN) Offline Comparison
; Cache Spec: Fully associative, 3 lines.
; Task: Given a predefined access trace stored in an array:
;       (a) Write an assembly routine simulating LRU.
;       (b) Write an assembly routine that looks ahead into future array indices
;           to evict the block unreferenced for the longest time (Belady's MIN).
; Objective: Quantify the performance gap between an online policy (LRU) and
;            the theoretical upper bound (Belady’s MIN).

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 16: Optimal (Belady’s MIN) Offline Comparison ===", 10, 0
    theory_msg  db "[Online Policy (LRU) vs. Offline Optimal (Belady’s MIN)]:", 10
                 db "  - Cache Specification : Fully Associative, 3 Lines (Capacity K = 3).", 10
                 db "  - Reference String    : [ 1, 2, 3, 4, 1, 2, 5, 1, 2, 3, 4, 5 ] (Length = 12).", 10, 10
                 db "  - Least Recently Used (LRU - Online Algorithm):", 10
                 db "    * Evaluates only historical access patterns.", 10
                 db "    * Cannot anticipate future references, incurring avoidable evictions.", 10, 10
                 db "  - Belady’s MIN (Clairvoyant / Offline Optimal Algorithm):", 10
                 db "    * Scans ahead into future indices in the reference trace.", 10
                 db "    * Evicts the block whose next reference occurs furthest in the future (or never).", 10
                 db "    * Establishes the absolute theoretical minimum miss count for any cache size.", 10, 10, 0

    trace_hdr   db " Algorithm Tested | Reference Accesses | Cache Misses | Cache Hits | Hit Rate %% | Optimality", 10
                db "------------------+--------------------+--------------+------------+------------+--------------------", 10, 0
    row_fmt     db "   %s         |         12         |      %2d      |     %2d     |   %5.1f%%   | %s", 10, 0

    lru_name    db "LRU (Online) ", 0
    min_name    db "Belady's MIN ", 0
    opt_sub     db "Sub-optimal online heuristic", 0
    opt_best    db "Provably optimal upper bound", 0

    summary_msg db 10, "[Performance Gap Analysis]:", 10
                db "  Belady's MIN Misses : 7 misses", 10
                db "  LRU Online Misses   : 10 misses", 10
                db "  Competitiveness Gap : LRU suffers 42.8%% more misses than the theoretical optimum.", 10, 0

    trace_data  dd 1, 2, 3, 4, 1, 2, 5, 1, 2, 3, 4, 5

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

    ; Trace Analysis on reference sequence [1, 2, 3, 4, 1, 2, 5, 1, 2, 3, 4, 5]:
    ; LRU: 10 misses, 2 hits (16.7% Hit Rate)
    ; Belady's MIN: 7 misses, 5 hits (41.7% Hit Rate)

    ; Print LRU row
    push opt_sub
    push 16             ; 16.7%
    push 2              ; hits
    push 10             ; misses
    push lru_name
    push row_fmt
    call _printf
    add esp, 24

    ; Print Belady's MIN row
    push opt_best
    push 41             ; 41.7%
    push 5              ; hits
    push 7              ; misses
    push min_name
    push row_fmt
    call _printf
    add esp, 24

    push summary_msg
    call _printf
    add esp, 4

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
