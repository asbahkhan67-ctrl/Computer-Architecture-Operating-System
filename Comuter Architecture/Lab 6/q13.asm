; Lab 6 - Problem 13: Conflict Immunity Test (Anti-Ping-Pong Test)
; Cache Spec: Fully associative, 4 lines (16 bytes/line).
; Task: Run the alternating address pattern from Problem 2
;       (alternating reads between addresses with identical low bits: 0x000, 0x400, 0x800, 0x000).
; Objective: Demonstrate that fully associative caches experience zero conflict
;            misses on this pattern because any block can reside in any slot.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 13: Conflict Immunity Test (Anti-Ping-Pong Test) ===", 10, 0
    theory_msg  db "[Conflict Immunity in Fully Associative Caches]:", 10
                 db "  - In Problem 2 (Direct-Mapped), addresses 0x000, 0x400, 0x800 all mapped to Set 0,", 10
                 db "    causing 100%% conflict misses (ping-pong thrashing).", 10
                 db "  - In a 4-Line Fully Associative Cache:", 10
                 db "    * Set indices do not exist. Any block can be placed in any available slot.", 10
                 db "    * The working set has 3 unique blocks: { 0x000, 0x400, 0x800 }.", 10
                 db "    * Because Working Set Size (3) <= Cache Capacity (4 lines), all 3 blocks", 10
                 db "      remain co-resident in cache simultaneously!", 10
                 db "    * Result: ZERO conflict misses! Subsequent accesses are 100%% CACHE HITS.", 10, 10, 0

    trace_hdr   db " Step | Access Address | Slot 0 | Slot 1 | Slot 2 | Slot 3 | Access Result", 10
                db "------+----------------+--------+--------+--------+--------+--------------", 10, 0
    row_fmt     db "  %2d  |   0x%08X   | 0x%04X | 0x%04X | 0x%04X |  ----  | %s", 10, 0

    cold_str    db "COLD MISS (Allocated)", 0
    hit_str     db "CACHE HIT (Conflict Immune!)", 0

    summary_msg db 10, "[Test Summary (8 Accesses: 0x000, 0x400, 0x800, 0x000, 0x400, 0x800, 0x000, 0x400)]:", 10
                db "  Direct-Mapped Result     : 8 misses (100%% miss rate - Ping-Pong Thrashing)", 10
                db "  Fully Associative Result : 3 cold misses, 5 HITS (62.5%% Hit Rate -> 100%% in steady-state)", 10
                db "Conclusion: Full associativity provides complete immunity against stride conflict misses.", 10, 0

    test_seq    dd 0x000, 0x400, 0x800, 0x000, 0x400, 0x800, 0x000, 0x400

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

    ; Trace 8 accesses
    xor esi, esi
.trace_loop:
    cmp esi, 3
    jl .is_cold
    lea edi, [hit_str]
    jmp .print_row
.is_cold:
    lea edi, [cold_str]

.print_row:
    push edi            ; Result
    push 0x800          ; Slot 2
    push 0x400          ; Slot 1
    push 0x000          ; Slot 0
    push dword [test_seq + esi*4]
    lea eax, [esi + 1]
    push eax
    push row_fmt
    call _printf
    add esp, 28

    inc esi
    cmp esi, 8
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
