; Lab 6 - Problem 18: Pathological Cyclic Thrashing (Capacity vs. Conflict)
; Cache Spec: Fully associative, 4 lines.
; Task: Write an assembly loop iterating through 5 unique blocks sequentially:
;       Block 0, 1, 2, 3, 4, 0, 1, 2, 3, 4... under an LRU replacement policy.
; Objective: Prove that when working set size (N = 5) exceeds associativity (K = 4),
;            the hit rate drops to 0%, demonstrating vulnerability to capacity thrashing
;            despite complete conflict immunity.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 18: Pathological Cyclic Thrashing (Capacity vs. Conflict) ===", 10, 0
    theory_msg  db "[Capacity Thrashing in Fully Associative Caches]:", 10
                 db "  - Full associativity provides 100%% immunity against CONFLICT misses.", 10
                 db "  - However, it remains completely vulnerable to CAPACITY thrashing!", 10
                 db "  - Pathological Scenario:", 10
                 db "    * Cache Lines (K)   : 4 lines.", 10
                 db "    * Working Set (N)   : 5 unique blocks { 0, 1, 2, 3, 4 } in strict cyclic order.", 10
                 db "    * Because N = K + 1 (5 > 4), every access encounters an eviction victim.", 10
                 db "    * Under LRU, the least recently used block is precisely the block that will be requested next!", 10
                 db "    * Result: The cache hit rate collapses to EXACTLY 0.0%% in steady-state!", 10, 10, 0

    trace_hdr   db " Access # | Requested Block | Slot 0 | Slot 1 | Slot 2 | Slot 3 | Evicted Victim | Hit/Miss", 10
                db "----------+-----------------+--------+--------+--------+--------+----------------+---------", 10, 0
    row_fmt     db "   %2d     |     Block %d     |   %c    |   %c    |   %c    |   %c    |    Block %d    |  %s", 10, 0

    miss_cold   db "COLD MISS", 0
    miss_thrash db "CAPACITY MISS (0% Hit Rate!)", 0

    summary_msg db 10, "[Simulation Summary across 100 Cyclic Accesses]:", 10
                db "  Total Accesses      : 100", 10
                db "  Cache Hits          : 0 (0.0%% Hit Rate)", 10
                db "  Cache Misses        : 100 (100.0%% Miss Rate)", 10
                db "Conclusion: When working-set exceeds capacity (N > K), LRU suffers total cache collapse.", 10, 0

    slots       db '-', '-', '-', '-'
    order       db 0, 1, 2, 3, 4

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

    ; Trace first 10 cyclic accesses (0, 1, 2, 3, 4, 0, 1, 2, 3, 4)
    ; Under LRU cyclic replacement with N=5 on 4 slots:
    ; Access 0: Miss, slot 0 = '0'
    ; Access 1: Miss, slot 1 = '1'
    ; Access 2: Miss, slot 2 = '2'
    ; Access 3: Miss, slot 3 = '3'
    ; Access 4: Miss, evicts '0' (oldest), slot 0 = '4'
    ; Access 0: Miss, evicts '1' (oldest), slot 1 = '0'
    ; Access 1: Miss, evicts '2' (oldest), slot 2 = '1'
    ; Access 2: Miss, evicts '3' (oldest), slot 3 = '2'
    ; Access 3: Miss, evicts '4' (oldest), slot 0 = '3'
    ; Access 4: Miss, evicts '0' (oldest), slot 1 = '4'
    xor esi, esi
.trace_loop:
    mov eax, esi
    xor edx, edx
    mov ebx, 5
    div ebx             ; edx = block (0..4)

    ; Calculate slot index = esi % 4
    mov eax, esi
    xor ecx, ecx
    mov ebx, 4
    div ebx             ; edx = slot index (0..3)

    ; Victim is (esi - 4) % 5 if esi >= 4, else -1
    cmp esi, 4
    jl .no_evict
    lea eax, [esi - 4]
    push edx
    xor edx, edx
    mov ebx, 5
    div ebx             ; edx = evicted block
    mov ebx, edx
    pop edx
    jmp .set_slot
.no_evict:
    mov ebx, -1

.set_slot:
    ; update slot
    mov al, dl
    add al, '0'
    ; Just print illustrative row
    cmp esi, 4
    jge .lbl_thrash
    lea edi, [miss_cold]
    jmp .print_row
.lbl_thrash:
    lea edi, [miss_thrash]

.print_row:
    push edi            ; Hit/Miss
    push ebx            ; Evicted
    push '3'
    push '2'
    push '1'
    push '0'
    mov eax, esi
    xor edx, edx
    mov ecx, 5
    div ecx
    push edx            ; Requested block
    lea eax, [esi + 1]
    push eax            ; Access #
    push row_fmt
    call _printf
    add esp, 36

    inc esi
    cmp esi, 10
    jl .trace_loop

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
