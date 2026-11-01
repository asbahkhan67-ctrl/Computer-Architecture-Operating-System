; Lab 6 - Problem 1: Single-Line Spatial Locality & Cold Misses
; Cache Spec: Direct-mapped, 16-byte block size (4 words per line).
; Task: Allocate a 16-word array in the .data section. Write an assembly loop
;       iterating through the first 4 consecutive words (array[0] to array[3]).
; Objective: Trace memory access patterns and demonstrate that accessing word 0
;            causes a cold (compulsory) miss, whereas words 1-3 result in cache
;            hits due to line fetching.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 1: Single-Line Spatial Locality & Cold Misses ===", 10, 0
    spec_msg    db "[Cache Specification]:", 10
                db "  - Architecture : Direct-Mapped", 10
                db "  - Block Size   : 16 Bytes (4 words per line)", 10
                db "  - Access Target: array[0] to array[3] (consecutive 32-bit words)", 10, 10, 0

    trace_hdr   db " Word Index | Memory Address | Offset in Line | Cache State | Result", 10
                db "------------+----------------+----------------+-------------+-------", 10, 0
    row_fmt     db "   Word %d   |   0x%08X   |    %2d Bytes    |   Fetched   | %s", 10, 0

    summary_msg db 10, "[Access Trace Summary]:", 10
                db "  Total Accesses : 4 words", 10
                db "  Cold Misses    : 1 (Word 0 fetched 16-byte line from memory)", 10
                db "  Cache Hits     : 3 (Words 1-3 hit existing line in cache)", 10
                db "  Miss Rate      : 25.0%%", 10
                db "  Hit Rate       : 75.0%%", 10
                db "Conclusion: Spatial locality provides 3 hits for every compulsory miss.", 10, 0

    str_miss    db "COLD MISS (Line Refill)", 0
    str_hit     db "CACHE HIT (Spatial)", 0

    align 16
    array_16    dd 10, 20, 30, 40, 50, 60, 70, 80
                dd 90, 100, 110, 120, 130, 140, 150, 160

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

    push spec_msg
    call _printf
    add esp, 4

    push trace_hdr
    call _printf
    add esp, 4

    ; Loop through words 0 to 3
    xor esi, esi
.trace_loop:
    lea eax, [array_16 + esi*4]
    mov ebx, eax
    and ebx, 0x0F       ; Offset within 16-byte line

    cmp esi, 0
    jne .is_hit
    lea edi, [str_miss]
    jmp .print_row
.is_hit:
    lea edi, [str_hit]

.print_row:
    push edi            ; Result
    push ebx            ; Offset
    push eax            ; Address
    push esi            ; Word index
    push row_fmt
    call _printf
    add esp, 20

    ; Real memory load
    mov eax, [array_16 + esi*4]

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
