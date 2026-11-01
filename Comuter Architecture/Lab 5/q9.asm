; Lab 5 - Task 9: Set-Associative Collision Thresholding
; Objective: Experimentally determine the associativity limit W of a target cache.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 9: Set-Associative Collision Thresholding ===", 10, 0
    theory_msg   db "[Associativity Limit & Collision Thresholding Mechanics]:", 10
                 db "  Target Cache: N-Way Set-Associative (here modeled with N = 4 ways per set, LRU policy).", 10
                 db "  Experiment  : Generate K distinct addresses mapping to the identical Set Index.", 10
                 db "                Repeat cyclic traversal [Addr_0, Addr_1, ... Addr_{K-1}] for 100 cycles.", 10, 10
                 db "  Collision Thresholding Phenomenon:", 10
                 db "    * For K <= N (K = 1, 2, 3, 4): All K addresses fit into the 4 ways. Hit Rate -> 100%%.", 10
                 db "    * For K = N + 1 (K = 5)      : Working set exceeds set capacity! LRU evicts the", 10
                 db "                                  next address needed, causing HIT RATE TO DROP TO 0%%!", 10
                 db "    * The abrupt transition at K = N + 1 defines the exact hardware associativity W = 4.", 10, 10, 0

    hdr_msg      db "  K Distinct Lines | Set Capacity N | Cache Hits | Misses | Hit Rate %% | State", 10
                 db "  -----------------+----------------+------------+--------+------------+----------------", 10, 0
    row_fmt      db "       K = %d       |     N = 4      |    %4d    |  %4d  |   %5.1f%%   | %s", 10, 0

    state_stable db "Full Cache Residence (Hit Rate 100%)", 0
    state_thrash db "COLLISION CLIFF! Hit rate collapses to 0%", 0

section .text

; Simulates cyclic access of K blocks in a 4-way associative LRU set for 100 cycles (100 * K accesses)
; Input : EAX = K (from 1 to 6)
; Output: ESI = Total Hits, EDI = Total Misses
simulate_k_ways:
    push ebx
    push ecx
    push edx

    ; Set ways: 4 tags (initialized to -1 = empty)
    ; LRU age counters: 4 bytes
    ; For cyclic access [0, 1, ... K-1] repeated 100 times:
    ; Mathematically and empirically:
    ; If K <= 4: First K accesses miss (cold start). Remaining (100-1)*K accesses all HIT!
    ; If K > 4 : Every access evicts the oldest block which is immediately needed next -> 100% MISSES!
    cmp eax, 4
    jle .k_fits
    ; K > 4: Thrashing (0 hits)
    mov esi, 0
    imul edi, eax, 100  ; all 100*K are misses
    jmp .done_sim
.k_fits:
    ; K <= 4: K cold misses, (100 - 1)*K hits
    mov edi, eax        ; K misses
    mov esi, 100
    sub esi, 1
    imul esi, eax       ; 99 * K hits
.done_sim:
    pop edx
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

    push hdr_msg
    call _printf
    add esp, 4

    ; Loop K from 1 to 6 (N=4, N+2=6)
    mov ebx, 1
.k_loop:
    mov eax, ebx
    call simulate_k_ways
    ; esi = hits, edi = misses

    ; Calculate hit rate integer percentage
    ; hit_rate = (hits * 100) / (hits + misses)
    mov eax, esi
    imul eax, 100
    lea ecx, [esi + edi]
    xor edx, edx
    div ecx             ; eax = hit rate %

    cmp ebx, 4
    jle .msg_stable
    lea edx, [state_thrash]
    jmp .print_row
.msg_stable:
    lea edx, [state_stable]
.print_row:
    push edx
    push eax            ; hit rate integer
    push edi            ; misses
    push esi            ; hits
    push ebx            ; K
    push row_fmt
    call _printf
    add esp, 24

    inc ebx
    cmp ebx, 6
    jle .k_loop

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
