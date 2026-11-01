; Lab 6 - Problem 12: Least Recently Used (LRU) Replacement via Counter Array
; Cache Spec: Fully associative, 4 lines.
; Task: Maintain an 8-bit age counter for each of the 4 cache slots. Write an assembly handler:
;       - On a hit: reset the hit slot counter to 0 and increment all other valid slot counters.
;       - On a miss: evict the slot with the maximum counter value, replace its tag, and zero its counter.
; Objective: Trace execution against the address sequence {0x10, 0x20, 0x30, 0x40, 0x10, 0x50}
;            to verify LRU eviction order.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 12: LRU Replacement via Counter Array ===", 10, 0
    theory_msg  db "[LRU Counter Mechanics in 4-Line Fully Associative Cache]:", 10
                 db "  - Each slot maintains an 8-bit age counter.", 10
                 db "  - On HIT : Reset hit slot's age counter to 0. Increment age counters of other valid slots.", 10
                 db "  - On MISS: Evict the slot with the maximum counter value (oldest / LRU victim),", 10
                 db "             replace its tag, and reset its age counter to 0.", 10
                 db "  - Target Sequence: {0x10, 0x20, 0x30, 0x40, 0x10, 0x50}", 10, 10, 0

    trace_hdr   db " Step | Address | Result | Slot 0 [Tag:Age] | Slot 1 [Tag:Age] | Slot 2 [Tag:Age] | Slot 3 [Tag:Age]", 10
                db "------+---------+--------+------------------+------------------+------------------+-----------------", 10, 0
    row_fmt     db "  %d   |  0x%02X   |  %s  |    0x%02X : %d     |    0x%02X : %d     |    0x%02X : %d     |   0x%02X : %d", 10, 0

    hit_str     db "HIT ", 0
    miss_str    db "MISS", 0

    conclusion  db 10, "Conclusion: At Step 6 (0x50), Slot 1 (Tag 0x20, max age=3) was correctly chosen as LRU victim.", 10, 0

    ; 4 Cache slots
    cache_tags  dd 0, 0, 0, 0
    cache_ages  db 0, 0, 0, 0
    cache_valid db 0, 0, 0, 0

    seq_addrs   dd 0x10, 0x20, 0x30, 0x40, 0x10, 0x50

section .text

; Input: EAX = address (tag)
; Output: EDX = 1 (Hit) or 0 (Miss)
lru_access:
    push ebx
    push ecx
    push esi
    mov esi, eax        ; requested tag

    ; 1. Check for Hit
    xor ecx, ecx
.hit_check:
    movzx ebx, byte [cache_valid + ecx]
    test ebx, ebx
    jz .not_hit
    cmp esi, [cache_tags + ecx*4]
    je .found_hit
.not_hit:
    inc ecx
    cmp ecx, 4
    jl .hit_check

    ; 2. MISS: find victim
    ; Check if any empty slot
    xor ecx, ecx
.find_empty:
    movzx ebx, byte [cache_valid + ecx]
    test ebx, ebx
    jz .install_empty
    inc ecx
    cmp ecx, 4
    jl .find_empty

    ; All valid: find slot with maximum age
    xor ebx, ebx        ; max_val
    xor ecx, ecx        ; victim index
    xor edx, edx        ; i
.find_max:
    movzx eax, byte [cache_ages + edx]
    cmp eax, ebx
    jle .skip_max
    mov ebx, eax
    mov ecx, edx
.skip_max:
    inc edx
    cmp edx, 4
    jl .find_max

.install_empty:
    ; Slot in ECX is victim!
    ; Increment all other valid slots
    xor edx, edx
.inc_miss:
    cmp edx, ecx
    je .skip_inc_miss
    movzx eax, byte [cache_valid + edx]
    test eax, eax
    jz .skip_inc_miss
    inc byte [cache_ages + edx]
.skip_inc_miss:
    inc edx
    cmp edx, 4
    jl .inc_miss

    ; Install new tag in victim slot ECX
    mov [cache_tags + ecx*4], esi
    mov byte [cache_ages + ecx], 0
    mov byte [cache_valid + ecx], 1
    xor edx, edx        ; return Miss
    pop esi
    pop ecx
    pop ebx
    ret

.found_hit:
    ; Matched slot is ECX
    ; Increment all other valid slots, reset ECX to 0
    xor edx, edx
.inc_hit:
    cmp edx, ecx
    je .skip_inc_hit
    movzx eax, byte [cache_valid + edx]
    test eax, eax
    jz .skip_inc_hit
    inc byte [cache_ages + edx]
.skip_inc_hit:
    inc edx
    cmp edx, 4
    jl .inc_hit

    mov byte [cache_ages + ecx], 0
    mov edx, 1          ; return Hit
    pop esi
    pop ecx
    pop ebx
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
.seq_loop:
    mov eax, [seq_addrs + esi*4]
    call lru_access

    cmp edx, 1
    jne .lbl_m
    lea edi, [hit_str]
    jmp .print_s
.lbl_m:
    lea edi, [miss_str]

.print_s:
    movzx eax, byte [cache_ages + 3]
    push eax
    push dword [cache_tags + 12]
    movzx eax, byte [cache_ages + 2]
    push eax
    push dword [cache_tags + 8]
    movzx eax, byte [cache_ages + 1]
    push eax
    push dword [cache_tags + 4]
    movzx eax, byte [cache_ages]
    push eax
    push dword [cache_tags]
    push edi
    push dword [seq_addrs + esi*4]
    lea eax, [esi + 1]
    push eax
    push row_fmt
    call _printf
    add esp, 44

    inc esi
    cmp esi, 6
    jl .seq_loop

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
