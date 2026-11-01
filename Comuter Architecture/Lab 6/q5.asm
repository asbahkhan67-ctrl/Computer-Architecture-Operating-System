; Lab 6 - Problem 5: Software Direct-Mapped Cache Simulator (Bit Masking)
; Cache Spec: Direct-mapped, 4 lines, 16 bytes/line (total 64 bytes).
; Task: Write an assembly function cache_lookup(address) that maintains a simulated tag
;       store in memory. Use bitwise instructions to extract:
;       - Block Offset: bits [3:0]
;       - Set Index: bits [5:4]
;       - Tag: bits [31:6]
; Objective: Update valid bits and tags; return 1 for a cache hit and 0 for a cache miss.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 5: Software Direct-Mapped Cache Simulator ===", 10, 0
    spec_msg    db "[Cache Specification & Bit-Field Partitioning]:", 10
                db "  - Architecture : Direct-Mapped, 4 lines, 16 Bytes/line (64 Bytes total).", 10
                db "  - Block Offset : bits [3:0] (4 bits, 0x0F mask)", 10
                db "  - Set Index    : bits [5:4] (2 bits, 0x03 mask, 4 sets)", 10
                db "  - Tag Field    : bits [31:6] (26 bits, shift right by 6)", 10, 10, 0

    trace_hdr   db " Access Address | Tag Field  | Set Index | Offset | Cache Result | Action", 10
                db "----------------+------------+-----------+--------+--------------+----------------", 10, 0
    row_fmt     db "   0x%08X   | 0x%07X |   Set %d   |  0x%02X  |  %s  | %s", 10, 0

    hit_str     db "CACHE HIT ", 0
    miss_str    db "CACHE MISS", 0
    act_install db "Installed into Set", 0
    act_hit     db "Read from Set", 0
    act_evict   db "Evicted previous tag", 0

    ; 4 Cache lines: valid (1 byte) and tag (4 bytes)
    cache_valid db 0, 0, 0, 0
    align 4
    cache_tags  dd 0, 0, 0, 0

    ; Test address sequence
    test_seq    dd 0x00000010 ; Set 1, Tag 0 (Miss, install)
                dd 0x00000018 ; Set 1, Tag 0 (Hit! Same line)
                dd 0x00000050 ; Set 1, Tag 1 (Miss, evict tag 0!)
                dd 0x00000010 ; Set 1, Tag 0 (Miss, re-install tag 0!)
                dd 0x00000020 ; Set 2, Tag 0 (Miss, install into Set 2)

section .text

; Function: cache_lookup
; Input : EAX = 32-bit physical address
; Output: EAX = 1 (Hit) or 0 (Miss)
;         EBX = Set Index
;         ECX = Tag
;         EDX = Offset
cache_lookup:
    push esi
    mov esi, eax        ; save addr

    ; 1. Block Offset: bits [3:0]
    mov edx, eax
    and edx, 0x0F

    ; 2. Set Index: bits [5:4]
    mov ebx, eax
    shr ebx, 4
    and ebx, 0x03

    ; 3. Tag: bits [31:6]
    mov ecx, eax
    shr ecx, 6

    ; Check valid bit
    movzx eax, byte [cache_valid + ebx]
    test eax, eax
    jz .miss_empty

    ; Check tag
    cmp ecx, [cache_tags + ebx*4]
    je .is_cache_hit

    ; Tag mismatch -> Miss (Eviction)
    mov [cache_tags + ebx*4], ecx
    xor eax, eax        ; return 0 (Miss)
    pop esi
    ret

.miss_empty:
    ; Valid = 0 -> Miss (Cold fill)
    mov byte [cache_valid + ebx], 1
    mov [cache_tags + ebx*4], ecx
    xor eax, eax        ; return 0 (Miss)
    pop esi
    ret

.is_cache_hit:
    mov eax, 1          ; return 1 (Hit)
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

    push spec_msg
    call _printf
    add esp, 4

    push trace_hdr
    call _printf
    add esp, 4

    xor esi, esi
.test_loop:
    mov eax, [test_seq + esi*4]
    call cache_lookup
    ; EAX = result (1/0), EBX = set index, ECX = tag, EDX = offset

    cmp eax, 1
    jne .print_miss
    lea edi, [hit_str]
    lea ebp, [act_hit]
    jmp .do_print
.print_miss:
    lea edi, [miss_str]
    lea ebp, [act_install]

.do_print:
    push ebp            ; Action
    push edi            ; Result
    push edx            ; Offset
    push ebx            ; Set Index
    push ecx            ; Tag
    push dword [test_seq + esi*4] ; Address
    push row_fmt
    call _printf
    add esp, 28

    inc esi
    cmp esi, 5
    jl .test_loop

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
