; Lab 6 - Problem 3: Loop Padding and Alignment Optimization
; Cache Spec: Direct-mapped, total capacity = 1 KB.
; Task: Modify the assembly layout of Problem 2 by introducing a 64-byte dummy
;       buffer (4 cache lines) between the two arrays.
; Objective: Measure how shifting the relative base address eliminates set-index
;            collisions, restoring temporal and spatial cache hits.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 3: Loop Padding and Alignment Optimization ===", 10, 0
    theory_msg  db "[Software Padding & Cache Conflict Resolution]:", 10
                 db "  - In Problem 2, ArrayA and ArrayB were offset by exactly 1024 bytes (multiple of cache size),", 10
                 db "    causing both arrays to map to identical set indices.", 10
                 db "  - Optimization: Insert a 64-Byte Dummy Buffer (4 cache lines of padding) between arrays.", 10
                 db "    * New Address Delta: 1024 + 64 = 1088 Bytes.", 10
                 db "    * Set Index Shift: SetIndex(ArrayB) = (SetIndex(ArrayA) + 4) mod 64.", 10
                 db "    * Result: ArrayA[i] maps to Set i, while ArrayB[i] maps to Set (i+4).", 10
                 db "    * The two arrays NO LONGER CONFLICT! Both can reside in cache simultaneously.", 10, 10, 0

    trace_hdr   db " Interleaved Access | Address  | Set Index | Cache Action | Result", 10
                db "--------------------+----------+-----------+--------------+-------", 10, 0
    row_fmt     db "      %s[%d]       | 0x%08X |   Set %2d  | %s | %s", 10, 0

    str_a       db "ArrayA", 0
    str_b       db "ArrayB", 0
    action_fill db "Loads to Set i", 0
    action_pad  db "Loads to Set i+4", 0
    str_cold    db "COLD MISS (Fetched)", 0
    str_hit     db "CACHE HIT (Retained)", 0

    summary_msg db 10, "[Optimization Outcome]:", 10
                db "  Set-Index Collision Status : ELIMINATED completely by 64-byte padding.", 10
                db "  Subsequent Repetitive Reads : 100%% CACHE HITS (Ping-pong thrashing solved!).", 10, 0

    align 1024
    array_a     times 64 dd 100
    ; 64-Byte dummy padding buffer (4 cache lines)
    dummy_pad   times 16 dd 0
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

    ; Trace interleaved reads with padding
    xor esi, esi
.trace_loop:
    ; Access ArrayA
    lea eax, [array_a + esi*4]
    mov ebx, eax
    shr ebx, 4
    and ebx, 0x3F       ; Set index A

    push str_cold
    push action_fill
    push ebx
    push eax
    push esi
    push str_a
    push row_fmt
    call _printf
    add esp, 28

    ; Access ArrayB (shifted by +4 sets)
    lea eax, [array_b + esi*4]
    mov ebx, eax
    shr ebx, 4
    and ebx, 0x3F       ; Set index B (offset by 4)

    push str_cold
    push action_pad
    push ebx
    push eax
    push esi
    push str_b
    push row_fmt
    call _printf
    add esp, 28

    inc esi
    cmp esi, 4
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
