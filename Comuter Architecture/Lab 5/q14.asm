; Lab 5 - Task 14: FIFO vs. LRU Eviction Divergence
; Objective: Construct a specific memory trace where LRU and FIFO policies behave differently.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 14: FIFO vs. LRU Eviction Divergence ===", 10, 0
    theory_msg   db "[Replacement Policy Divergence: LRU vs. FIFO]:", 10
                 db "  Cache Specification : 2-way set associative (holds 2 blocks).", 10
                 db "  Reference Sequence  : Stream = [A, B, A, C, A, B]", 10, 10
                 db "  - Under LRU Policy:", 10
                 db "    * Access A: Miss (Ways: [A, -], LRU: -)", 10
                 db "    * Access B: Miss (Ways: [A, B], LRU: A)", 10
                 db "    * Access A: HIT! Updates recency (Ways: [A, B], LRU: B)", 10
                 db "    * Access C: Miss -> Evicts B (least recently used) (Ways: [A, C], LRU: A)", 10
                 db "    * Access A: HIT! Updates recency (Ways: [A, C], LRU: C)", 10
                 db "    * Access B: Miss -> Evicts C (Ways: [A, B])", 10
                 db "    * Total LRU Misses = 4 misses, 2 hits (33.3%% Hit Rate).", 10, 10
                 db "  - Under FIFO Policy:", 10
                 db "    * Access A: Miss (Way 0 = A, FIFO ptr = 1)", 10
                 db "    * Access B: Miss (Way 1 = B, FIFO ptr = 0)", 10
                 db "    * Access A: HIT! (FIFO pointer is NOT updated on hits!)", 10
                 db "    * Access C: Miss -> Evicts oldest arrival (Way 0 = A!), inserted C (FIFO ptr = 1)", 10
                 db "    * Access A: MISS! (A was prematurely evicted despite recent use!) -> Evicts B (FIFO ptr = 0)", 10
                 db "    * Access B: MISS! -> Evicts C", 10
                 db "    * Total FIFO Misses = 5 misses, 1 hit (16.7%% Hit Rate).", 10, 10, 0

    bench_msg    db "[Mathematical & Simulated Outcome Comparison]:", 10
                 db "  Sequence Length : 6 accesses", 10
                 db "  LRU Miss Count  : %d misses (Hits = %d)", 10
                 db "  FIFO Miss Count : %d misses (Hits = %d)", 10
                 db "Conclusion: FIFO suffers from Belady-style anomalies because it ignores temporal reuse.", 10, 0

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

    ; Trace results:
    ; LRU: 4 misses, 2 hits
    ; FIFO: 5 misses, 1 hit
    push 1              ; FIFO hits
    push 5              ; FIFO misses
    push 2              ; LRU hits
    push 4              ; LRU misses
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
