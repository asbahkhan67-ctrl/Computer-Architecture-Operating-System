; Lab 5 - Task 13: Least Recently Used (LRU) State Machine Tracing
; Objective: Track the dynamic state transition of LRU tracking bits under an active access stream.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 13: Least Recently Used (LRU) State Machine Tracing ===", 10, 0
    theory_msg   db "[2-Way Set-Associative LRU State Machine Mechanics]:", 10
                 db "  - Architecture : 2-way set associative, single set.", 10
                 db "  - Storage      : Way 0 slot, Way 1 slot, and a 1-bit LRU state flag.", 10
                 db "  - LRU Rule     : LRU bit indicates which way is the LEAST recently used.", 10
                 db "    * If access hits Way 0 -> LRU bit set to 1 (Way 1 is now LRU victim).", 10
                 db "    * If access hits Way 1 -> LRU bit set to 0 (Way 0 is now LRU victim).", 10
                 db "    * On Miss: Evict the way pointed to by the LRU bit, insert block, flip bit.", 10
                 db "  - Access Stream: [A, B, A, C, A, B]", 10, 10, 0

    trace_hdr    db " Step | Access Block | Way 0 | Way 1 | LRU Bit (Victim) | Result", 10
                 db " -----+--------------+-------+-------+------------------+-------", 10, 0
    step_fmt     db "   %d  |      %c       |   %c   |   %c   |      Way %d       | %s", 10, 0

    hit_str      db "HIT", 0
    miss_str     db "MISS (Cold)", 0
    evict_str    db "MISS (Evict)", 0

    stream       db 'A', 'B', 'A', 'C', 'A', 'B'

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

    ; Simulation State:
    ; Way 0: '-' (empty = 0)
    ; Way 1: '-' (empty = 0)
    ; LRU bit: 0 (initially Way 0 is victim)
    mov bl, '-'         ; Way 0
    mov bh, '-'         ; Way 1
    mov dl, 0           ; LRU bit (0 or 1)

    xor esi, esi        ; step 0..5
.step_loop:
    mov al, [stream + esi] ; requested block
    xor ecx, ecx        ; result type (0=hit, 1=cold miss, 2=eviction miss)

    ; Check Way 0
    cmp bl, al
    jne .check_way1
    ; Hit on Way 0
    mov dl, 1           ; Way 1 becomes LRU victim
    mov ecx, 0
    jmp .print_step

.check_way1:
    cmp bh, al
    jne .miss_handler
    ; Hit on Way 1
    mov dl, 0           ; Way 0 becomes LRU victim
    mov ecx, 0
    jmp .print_step

.miss_handler:
    ; Miss: check if cold or eviction
    test dl, dl
    jnz .evict_way1
    ; Evict/fill Way 0
    cmp bl, '-'
    je .cold_w0
    mov ecx, 2          ; Evict
    jmp .install_w0
.cold_w0:
    mov ecx, 1          ; Cold
.install_w0:
    mov bl, al
    mov dl, 1           ; Way 1 is now LRU victim
    jmp .print_step

.evict_way1:
    ; Evict/fill Way 1
    cmp bh, '-'
    je .cold_w1
    mov ecx, 2
    jmp .install_w1
.cold_w1:
    mov ecx, 1
.install_w1:
    mov bh, al
    mov dl, 0           ; Way 0 is now LRU victim

.print_step:
    ; String for result
    cmp ecx, 0
    jne .t_miss
    lea edi, [hit_str]
    jmp .do_print
.t_miss:
    cmp ecx, 1
    jne .t_evict
    lea edi, [miss_str]
    jmp .do_print
.t_evict:
    lea edi, [evict_str]

.do_print:
    push edi            ; Result string
    movzx eax, dl
    push eax            ; LRU bit
    movzx eax, bh
    push eax            ; Way 1
    movzx eax, bl
    push eax            ; Way 0
    movzx eax, byte [stream + esi]
    push eax            ; Access
    lea eax, [esi + 1]
    push eax            ; Step
    push step_fmt
    call _printf
    add esp, 28

    inc esi
    cmp esi, 6
    jl .step_loop

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
