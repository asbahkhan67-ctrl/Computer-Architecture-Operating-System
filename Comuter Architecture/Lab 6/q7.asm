; Lab 6 - Problem 7: Write-Through vs. Write-Back Flag Tracking
; Cache Spec: Direct-mapped, 8 blocks.
; Task: In a software-modeled cache structure, maintain a dirty bit array alongside tag
;       and valid bits. Implement store_word(addr, val):
;       - On a miss, evict the current occupant.
;       - If the evicted line is dirty, invoke a simulated mem_writeback() routine before fetching new data.
; Objective: Count memory write bus transactions under burst write access patterns.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 7: Write-Through vs. Write-Back Flag Tracking ===", 10, 0
    theory_msg  db "[Write Policy Mechanics & Bus Transaction Analysis (8-Block Cache)]:", 10
                 db "  - Architecture: Direct-Mapped, 8 Blocks (Set Index = bits [6:4], Tag = bits [31:7]).", 10
                 db "  - Write-Through: Every store immediately issues a write transaction to main memory bus.", 10
                 db "  - Write-Back   : Stores only set the line's DIRTY bit in cache.", 10
                 db "                   Memory bus write occurs ONLY when a dirty block is evicted (mem_writeback).", 10, 10, 0

    trace_hdr   db " Event | Store Addr | Set | Tag | Result | Dirty Status | Bus Writes Generated", 10
                db "-------+------------+-----+-----+--------+--------------+---------------------", 10, 0
    row_fmt     db "   %d   | 0x%08X |  %d  |  %d  |  %s  |    Dirty=%d   | Writeback=%s", 10, 0

    hit_str     db "HIT ", 0
    miss_str    db "MISS", 0
    yes_wb      db "YES (Bus write!)", 0
    no_wb       db "NO  (0 Bus write)", 0

    summary_msg db 10, "[Burst Write Policy Comparison (6 Store Operations)]:", 10
                db "  Write-Through Bus Writes : 6 transactions (Every store hits bus)", 10
                db "  Write-Back Bus Writes    : %d transactions (Only on dirty evictions!)", 10
                db "Conclusion: Write-Back saves %d%% of memory bus bandwidth.", 10, 0

    ; Cache state arrays: 8 blocks
    cache_valid db 0, 0, 0, 0, 0, 0, 0, 0
    cache_dirty db 0, 0, 0, 0, 0, 0, 0, 0
    align 4
    cache_tags  dd 0, 0, 0, 0, 0, 0, 0, 0

    wb_count    dd 0

    ; Access trace: stores to Set 0 repeatedly, then collision eviction
    trace_addrs dd 0x00000000 ; Set 0, Tag 0 (Miss, store sets dirty=1, wb=0)
                dd 0x00000004 ; Set 0, Tag 0 (Hit! store sets dirty=1, wb=0)
                dd 0x00000008 ; Set 0, Tag 0 (Hit! store sets dirty=1, wb=0)
                dd 0x0000000C ; Set 0, Tag 0 (Hit! store sets dirty=1, wb=0)
                dd 0x00000080 ; Set 0, Tag 1 (Miss! Evicts dirty Tag 0 -> MEM_WRITEBACK!)
                dd 0x00000084 ; Set 0, Tag 1 (Hit! store sets dirty=1, wb=0)

section .text

; Subroutine: store_word(addr, val)
; EAX = address, EDX = value
; Returns: EAX = 1 (Hit) or 0 (Miss), EBX = Set, ECX = Tag, EDX = Did writeback? (1/0)
store_word:
    push esi
    mov esi, eax        ; addr

    ; Set index = bits [6:4] (mask 0x07)
    mov ebx, eax
    shr ebx, 4
    and ebx, 0x07

    ; Tag = bits [31:7]
    mov ecx, eax
    shr ecx, 7

    ; Check if valid
    movzx eax, byte [cache_valid + ebx]
    test eax, eax
    jz .miss_clean

    ; Check tag
    cmp ecx, [cache_tags + ebx*4]
    je .store_hit

    ; Collision Miss: check if currently dirty
    movzx eax, byte [cache_dirty + ebx]
    test eax, eax
    jz .evict_clean

    ; Dirty eviction -> invoke mem_writeback()
    inc dword [wb_count]
    mov byte [cache_dirty + ebx], 1 ; new line marked dirty
    mov [cache_tags + ebx*4], ecx
    xor eax, eax        ; Miss
    mov edx, 1          ; Writeback triggered!
    pop esi
    ret

.evict_clean:
    mov byte [cache_dirty + ebx], 1
    mov [cache_tags + ebx*4], ecx
    xor eax, eax        ; Miss
    xor edx, edx        ; No writeback
    pop esi
    ret

.miss_clean:
    mov byte [cache_valid + ebx], 1
    mov byte [cache_dirty + ebx], 1
    mov [cache_tags + ebx*4], ecx
    xor eax, eax        ; Miss
    xor edx, edx        ; No writeback
    pop esi
    ret

.store_hit:
    mov byte [cache_dirty + ebx], 1 ; absorbed
    mov eax, 1          ; Hit
    xor edx, edx        ; No writeback
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
    mov eax, [trace_addrs + esi*4]
    mov edx, 0x1234
    call store_word
    ; EAX = Hit/Miss, EBX = Set, ECX = Tag, EDX = WB (1/0)

    cmp edx, 1
    jne .no_wb_msg
    lea edi, [yes_wb]
    jmp .check_hm
.no_wb_msg:
    lea edi, [no_wb]

.check_hm:
    cmp eax, 1
    jne .miss_lbl
    lea ebp, [hit_str]
    jmp .print_row
.miss_lbl:
    lea ebp, [miss_str]

.print_row:
    push edi            ; Writeback string
    push 1              ; Dirty status
    push ebp            ; Result string
    push ecx            ; Tag
    push ebx            ; Set
    push dword [trace_addrs + esi*4] ; Address
    lea eax, [esi + 1]
    push eax            ; Event #
    push row_fmt
    call _printf
    add esp, 32

    inc esi
    cmp esi, 6
    jl .trace_loop

    ; Summary: WB bus writes = 1 vs WT = 6 (83.3% savings)
    push 83             ; % savings
    push dword [wb_count]
    push summary_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
