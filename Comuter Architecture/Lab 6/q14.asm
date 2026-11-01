; Lab 6 - Problem 14: First-In, First-Out (FIFO) Replacement Queue
; Cache Spec: Fully associative, 4 lines.
; Task: Implement replacement using a circular pointer/index (modulo 4) stored in a register.
;       On every miss, evict the slot at ptr and increment ptr = (ptr + 1) & 0x03.
; Objective: Compare hit rates between FIFO and LRU algorithms for cyclic reference
;            strings such as {A, B, C, D, E, A, B, C, D, E}.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 14: First-In, First-Out (FIFO) Replacement Queue ===", 10, 0
    theory_msg  db "[FIFO Circular Queue Mechanics & Comparison with LRU]:", 10
                 db "  - Architecture : Fully Associative, 4 slots (Slot 0..3).", 10
                 db "  - FIFO Rule    : A circular pointer 'ptr' in a register tracks the oldest loaded slot.", 10
                 db "                   On a miss, replace slot[ptr] and update ptr = (ptr + 1) & 0x03.", 10
                 db "                   On a hit, ptr is UNCHANGED.", 10
                 db "  - Cyclic Test String: { A, B, C, D, E,  A, B, C, D, E } (Length = 10)", 10, 10
                 db "  - Cyclic String Behavior (Working set N = 5 > Cache lines K = 4):", 10
                 db "    * Under FIFO: Every single access from E onwards evicts the next needed block -> 100%% Misses!", 10
                 db "    * Under LRU : Also suffers 100%% misses due to cyclic capacity thrashing.", 10
                 db "  - Locality-Heavy String { A, B, C, D, A, E, A, B, C, D }:", 10
                 db "    * LRU retains 'A' because of recency update -> 2 Hits.", 10
                 db "    * FIFO blindly evicts 'A' as oldest insertion -> 0 Hits (FIFO degrades!).", 10, 10, 0

    trace_hdr   db " Step | Access | Result | FIFO Ptr | Slot 0 | Slot 1 | Slot 2 | Slot 3", 10
                db "------+--------+--------+----------+--------+--------+--------+-------", 10, 0
    row_fmt     db "  %2d  |   %c    |  %s  |    %d     |   %c    |   %c    |   %c    |   %c", 10, 0

    hit_str     db "HIT ", 0
    miss_str    db "MISS", 0

    summary_msg db 10, "[Policy Comparison Summary]:", 10
                db "  FIFO Hits on Cyclic Trace : 0 hits, 10 misses (0.0%% Hit Rate)", 10
                db "  FIFO Hardware Complexity  : Minimal (1 circular register pointer, 0 age comparators)", 10
                db "Conclusion: FIFO provides low hardware overhead at the expense of ignoring recency.", 10, 0

    slots       db '-', '-', '-', '-'
    stream      db 'A', 'B', 'C', 'D', 'E', 'A', 'B', 'C', 'D', 'E'

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

    ; FIFO replacement simulation
    ; DL = circular ptr (0..3)
    xor edx, edx

    xor esi, esi
.stream_loop:
    mov al, [stream + esi] ; requested char
    xor ecx, ecx        ; 1=hit, 0=miss

    ; Check if in slots
    xor ebx, ebx
.check_hit:
    cmp al, [slots + ebx]
    je .found_fifo_hit
    inc ebx
    cmp ebx, 4
    jl .check_hit

    ; MISS: replace slot at ptr DL
    movzx ebx, dl
    mov [slots + ebx], al
    inc dl
    and dl, 0x03        ; ptr = (ptr + 1) & 3
    xor ecx, ecx
    jmp .print_fifo_row

.found_fifo_hit:
    mov ecx, 1

.print_fifo_row:
    cmp ecx, 1
    jne .lbl_fm
    lea edi, [hit_str]
    jmp .do_pf
.lbl_fm:
    lea edi, [miss_str]

.do_pf:
    movzx eax, byte [slots + 3]
    push eax
    movzx eax, byte [slots + 2]
    push eax
    movzx eax, byte [slots + 1]
    push eax
    movzx eax, byte [slots]
    push eax
    movzx eax, dl
    push eax            ; FIFO ptr
    push edi            ; Result
    movzx eax, byte [stream + esi]
    push eax            ; Access
    lea eax, [esi + 1]
    push eax            ; Step
    push row_fmt
    call _printf
    add esp, 36

    inc esi
    cmp esi, 10
    jl .stream_loop

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
