; Lab 5 - Task 12: Cache Index Hashing Emulation
; Objective: Implement XOR-based set index randomization to mitigate regular conflict strides.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 12: Cache Index Hashing Emulation ===", 10, 0
    theory_msg   db "[XOR Set-Index Hashing / Pseudo-Randomization]:", 10
                 db "  Standard Cache Indexing: Index_raw = (Address >> 6) & 0xFF  (Lower bits directly index set)", 10
                 db "  Problem: Strides of 2^K repeatedly produce the same Index_raw, overloading 1 set.", 10
                 db "  Solution: Fold high-order tag bits into index bits using XOR:", 10
                 db "      Index_hashed = Index_raw XOR (Tag & Mask)", 10
                 db "  Result: Breaks pathological harmonics and uniformly disperses colliding lines.", 10, 10, 0

    trace_hdr    db "  Access Address | Raw Set Index | Tag Field | Hashed Set Index | Redistribution", 10
                 db "  ---------------+---------------+-----------+------------------+---------------", 10, 0
    row_fmt      db "    0x%08X   |    Set %3d    |  0x%05X  |     Set %3d      | %s", 10, 0

    col_note1    db "Collides on raw index Set 0!", 0
    col_note2    db "Redistributed evenly via XOR hash!", 0

    test_addrs   dd 0x00010000, 0x00020000, 0x00030000, 0x00040000

section .text

; Input : EAX = 32-bit physical address
; Output: EBX = Raw Set Index (bits 13:6)
;         ECX = Tag (bits 31:14)
;         EDX = Hashed Set Index (Index_raw XOR (Tag & 0xFF))
hash_index:
    ; Raw index: shift right 6, mask 0xFF (256 sets)
    mov ebx, eax
    shr ebx, 6
    and ebx, 0xFF

    ; Tag: shift right 14
    mov ecx, eax
    shr ecx, 14

    ; Hashed index = ebx XOR (ecx & 0xFF)
    mov edx, ecx
    and edx, 0xFF
    xor edx, ebx
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

    ; Trace 4 pathological addresses that collide on raw index Set 0
    xor esi, esi
.trace_loop:
    mov eax, [test_addrs + esi*4]
    call hash_index

    push col_note2
    push edx            ; Hashed Set Index
    push ecx            ; Tag
    push ebx            ; Raw Set Index
    push dword [test_addrs + esi*4]
    push row_fmt
    call _printf
    add esp, 24

    inc esi
    cmp esi, 4
    jl .trace_loop

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
