; Lab 6 - Problem 11: Tag Comparison Engine (Linear Search)
; Cache Spec: Fully associative, 8 lines, 16 bytes/line.
; Task: Write an assembly routine that maintains 8 tag entries. Given an input address:
;       - Extract Tag = bits [31:4].
;       - Sequentially loop through all 8 entries to evaluate hit or miss.
; Objective: Contrast the O(1) single-cycle set-index lookup of direct-mapped caches
;            with the multi-step search required by associative software lookups.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 11: Tag Comparison Engine (Linear Search) ===", 10, 0
    theory_msg  db "[Fully Associative Lookup vs. Direct-Mapped Lookup]:", 10
                 db "  - Direct-Mapped Cache  : Set Index directly addresses RAM array -> O(1) in 1 cycle.", 10
                 db "  - Fully Associative   : Any block can reside anywhere. No Set Index (Tag = bits [31:4]).", 10
                 db "    * Software model requires O(N) linear sequential loop over all 8 tag entries.", 10
                 db "    * Hardware requires N parallel comparator circuits (CAM cell matrix) to avoid O(N) penalty.", 10, 10, 0

    trace_hdr   db " Input Address | Extracted Tag | Linear Search Steps | Match Status | Result", 10
                db "---------------+---------------+---------------------+--------------+-------", 10, 0
    row_fmt     db "   0x%08X  |    0x%07X  |      %d comparisons  |  Slot %d hit | %s", 10, 0

    hit_str     db "CACHE HIT ", 0
    miss_str    db "CACHE MISS", 0

    ; 8 tag entries
    align 16
    fa_tags     dd 0x001000, 0x002000, 0x003000, 0x004000
                dd 0x005000, 0x006000, 0x007000, 0x008000

    test_addrs  dd 0x00030004 ; Tag = 0x003000 -> Hits in Slot 2!
                dd 0x00700008 ; Tag = 0x007000 -> Hits in Slot 6!
                dd 0x00900000 ; Tag = 0x009000 -> MISS (Scanned all 8 entries)

section .text

; Input: EAX = address
; Output: EDX = 1 (Hit) or 0 (Miss), ECX = steps, EBX = slot
fa_linear_lookup:
    push esi
    mov esi, eax
    shr esi, 4          ; Tag = bits [31:4]

    xor ecx, ecx        ; step counter
.search_loop:
    inc ecx
    cmp esi, [fa_tags + ecx*4 - 4]
    je .match_found
    cmp ecx, 8
    jl .search_loop

    ; Miss
    xor edx, edx
    mov ebx, -1
    pop esi
    ret

.match_found:
    mov edx, 1
    lea ebx, [ecx - 1]  ; matched slot index (0..7)
    pop esi
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

    push trace_hdr
    call _printf
    add esp, 4

    xor esi, esi
.trace_loop:
    mov eax, [test_addrs + esi*4]
    call fa_linear_lookup
    ; EDX = Hit/Miss, ECX = steps, EBX = slot

    cmp edx, 1
    jne .lbl_miss
    lea edi, [hit_str]
    jmp .print_row
.lbl_miss:
    lea edi, [miss_str]

.print_row:
    push edi            ; Result
    push ebx            ; Slot
    push ecx            ; Comparisons
    mov eax, [test_addrs + esi*4]
    shr eax, 4
    push eax            ; Tag
    push dword [test_addrs + esi*4] ; Address
    push row_fmt
    call _printf
    add esp, 24

    inc esi
    cmp esi, 3
    jl .trace_loop

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
