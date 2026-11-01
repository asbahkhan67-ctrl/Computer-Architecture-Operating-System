; Lab 5 - Task 8: Direct-Mapped Cache Conflict Thrashing
; Objective: Induce continuous conflict misses (ping-pong thrashing) in a direct-mapped structure.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 8: Direct-Mapped Cache Conflict Thrashing ===", 10, 0
    theory_msg   db "[Ping-Pong Conflict Thrashing in Direct-Mapped Caches]:", 10
                 db "  - Cache Capacity C = 8 KB (8,192 Bytes). Block Size B = 32 Bytes (256 Sets).", 10
                 db "  - Construction: Pointer P1 = Base, Pointer P2 = Base + 8,192 Bytes.", 10
                 db "    * Set Index(P1) = (P1 >> 5) & 0xFF", 10
                 db "    * Set Index(P2) = ((P1 + 8192) >> 5) & 0xFF = Set Index(P1) ! (Identical Set Index)", 10
                 db "    * Tag(P1) != Tag(P2)", 10
                 db "  - Alternating Access Pattern: [P1, P2, P1, P2, P1, P2 ... 2,000 accesses]", 10
                 db "    * Access P1: Evicts P2 from Set K.", 10
                 db "    * Access P2: Evicts P1 from Set K.", 10
                 db "    * Data Cache Miss Rate = 100.0%% (Every single access is a conflict miss!).", 10
                 db "    * Active working set is ONLY 8 Bytes, yet 8 KB of cache is rendered useless.", 10, 10, 0

    bench_msg    db "[Simulation Results for 2,000 Alternating Accesses]:", 10
                 db "  Total Accesses       : 2,000", 10
                 db "  Cache Hits           : %d", 10
                 db "  Conflict Misses      : %d", 10
                 db "  Effective Miss Rate  : 100.0%%", 10
                 db "Conclusion: Direct-mapped caches suffer severe conflict thrashing on power-of-2 strides.", 10, 0

    align 64
    buffer_arena times 4096 dd 1 ; 16 KB buffer

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

    ; Direct-Mapped Cache Simulator Tracking:
    ; Set 0 tag occupant
    ; 2000 accesses:
    ; Access 0: P1 (tag 0) -> Miss, occupant = tag 0
    ; Access 1: P2 (tag 1) -> Miss, occupant = tag 1
    ; ... all 2,000 accesses miss!
    xor edi, edi        ; miss count = 2000
    xor esi, esi        ; hit count = 0

    mov ecx, 2000
    mov edx, -1         ; current tag in set (-1 = empty)
.sim_loop:
    test ecx, 1
    jz .load_p1
.load_p2:
    mov eax, 1          ; Tag(P2) = 1
    jmp .check_tag
.load_p1:
    mov eax, 0          ; Tag(P1) = 0
.check_tag:
    cmp eax, edx
    je .hit
    ; Miss: evict and replace
    inc edi
    mov edx, eax
    jmp .next_iter
.hit:
    inc esi
.next_iter:
    dec ecx
    jnz .sim_loop

    push edi            ; misses
    push esi            ; hits
    push bench_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
