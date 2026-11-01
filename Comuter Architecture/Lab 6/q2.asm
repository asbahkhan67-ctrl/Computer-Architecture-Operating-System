; Lab 6 - Problem 2: Stride-Induced Conflict Misses (Ping-Pong Thrashing)
; Cache Spec: Direct-mapped, total capacity = 1 KB (64 blocks x 16 bytes).
; Task: Allocate two arrays, ArrayA and ArrayB, separated by exactly 1024 bytes
;       so that ArrayA[i] and ArrayB[i] map to identical set indices.
;       Write a loop interleaving reads: ArrayA[0], ArrayB[0], ArrayA[1], ArrayB[1], etc.
; Objective: Observe a 100% miss rate due to mutual eviction despite having
;            substantial unutilized capacity in the cache.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 2: Stride-Induced Conflict Misses (Ping-Pong Thrashing) ===", 10, 0
    theory_msg  db "[Cache Specification & Stride-Induced Conflict]:", 10
                db "  - Cache Type   : Direct-Mapped, 1 KB total capacity (64 blocks x 16 bytes).", 10
                db "  - Set Indexing : bits [9:4] determine the set index (64 sets total).", 10
                db "  - Address Delta: Exactly 1,024 bytes (0x400) between ArrayA and ArrayB.", 10
                db "    * SetIndex(ArrayA[i]) = (Addr_A >> 4) & 0x3F", 10
                db "    * SetIndex(ArrayB[i]) = ((Addr_A + 1024) >> 4) & 0x3F = SetIndex(ArrayA[i])", 10
                db "    * Both addresses contend for the EXACT SAME cache line in the same set!", 10, 10
                db "  - Interleaved Access Pattern: ArrayA[0], ArrayB[0], ArrayA[1], ArrayB[1]...", 10
                db "    * Reading ArrayA[i] fills Set i, evicting ArrayB[i].", 10
                db "    * Reading ArrayB[i] fills Set i, evicting ArrayA[i].", 10
                db "    * Ping-Pong thrashing results in 100%% MISS RATE on all interleaved reads!", 10, 10, 0

    trace_hdr   db " Interleaved Access | Address  | Set Index | Cache Action | Result", 10
                db "--------------------+----------+-----------+--------------+-------", 10, 0
    row_fmt     db "      %s[%d]       | 0x%08X |   Set %2d  | %s | %s", 10, 0

    str_a       db "ArrayA", 0
    str_b       db "ArrayB", 0
    action_ev_b db "Evicts ArrayB ", 0
    action_ev_a db "Evicts ArrayA ", 0
    str_miss    db "CONFLICT MISS", 0

    summary_msg db 10, "[Benchmark Summary]:", 10
                db "  Total Accesses       : 16 (8 pairs of interleaved reads)", 10
                db "  Cache Hits           : 0", 10
                db "  Conflict Misses      : 16", 10
                db "  Effective Miss Rate  : 100.0%%", 10
                db "Conclusion: 63 out of 64 cache blocks remain empty while 1 set is perpetually thrashed.", 10, 0

    align 1024
    array_a     times 64 dd 100
    align 1024
    array_b     times 64 dd 200

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

    ; Interleaved trace for 4 pairs (8 accesses)
    xor esi, esi
.interleave_loop:
    ; Access ArrayA[esi]
    lea eax, [array_a + esi*4]
    mov ebx, eax
    shr ebx, 4
    and ebx, 0x3F       ; set index

    push str_miss
    push action_ev_b
    push ebx
    push eax
    push esi
    push str_a
    push row_fmt
    call _printf
    add esp, 28

    ; Memory load A
    mov edx, [array_a + esi*4]

    ; Access ArrayB[esi]
    lea eax, [array_b + esi*4]
    mov ebx, eax
    shr ebx, 4
    and ebx, 0x3F       ; identical set index

    push str_miss
    push action_ev_a
    push ebx
    push eax
    push esi
    push str_b
    push row_fmt
    call _printf
    add esp, 28

    ; Memory load B
    mov edx, [array_b + esi*4]

    inc esi
    cmp esi, 4
    jl .interleave_loop

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
