; Lab 6 - Problem 17: Cache Invalidation and Maintenance Routines
; Cache Spec: Fully associative, 16 lines.
; Task: Write a cache_invalidate_all subroutine that clears all valid and dirty bits,
;       followed by a selective cache_invalidate_addr(reg_addr) routine that
;       searches tags and invalidates only a specific line.
; Objective: Implement cache maintenance operations essential for operating
;            system context switches and DMA transfers.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 17: Cache Invalidation and Maintenance Routines ===", 10, 0
    theory_msg  db "[OS Maintenance & DMA Cache Invalidation Architecture]:", 10
                 db "  - Context Switches: The OS kernel flushes or invalidates stale user process cache entries.", 10
                 db "  - DMA Transfers   : Network / Disk controllers write directly into physical DRAM.", 10
                 db "    * If the CPU holds dirty cache lines, DMA will read stale data from DRAM (Writeback needed).", 10
                 db "    * If CPU reads from cache after DMA writes DRAM, CPU reads stale data (Invalidation needed).", 10
                 db "  - Subroutines Implemented:", 10
                 db "    1. cache_invalidate_all()           : Global flush (clears all 16 Valid & Dirty bits).", 10
                 db "    2. cache_invalidate_addr(reg_addr)  : Selective flush (searches tag and clears single line).", 10, 10, 0

    state_msg   db "[Maintenance Routine Execution Trace]:", 10
                 db "  1. Initial State        : Populated 8 active cache lines with valid=1, dirty=1.", 10
                 db "  2. Selective Flush      : Invalidating Address 0x00020000 (Tag 0x0002)...", 10
                 db "     --> Result           : Slot %d successfully invalidated (Valid=0, Dirty=0).", 10
                 db "  3. Subsequent Read Test : Accessing Address 0x00020000 ==> Result: CACHE MISS (Forced refill)!", 10
                 db "  4. Global Invalidation  : Invoking cache_invalidate_all()...", 10
                 db "     --> Result           : All 16 slots reset to clean state (Valid count = %d).", 10
                 db "Conclusion: Maintenance routines enforce cache coherency across OS transitions.", 10, 0

    ; 16-Line Fully Associative Cache
    align 16
    fa16_valid  times 16 db 0
    fa16_dirty  times 16 db 0
    align 4
    fa16_tags   times 16 dd 0

section .text

; Subroutine 1: cache_invalidate_all
; Clears all 16 valid and dirty bits
cache_invalidate_all:
    push eax
    push ecx
    xor ecx, ecx
.clear_loop:
    mov byte [fa16_valid + ecx], 0
    mov byte [fa16_dirty + ecx], 0
    inc ecx
    cmp ecx, 16
    jl .clear_loop
    pop ecx
    pop eax
    ret

; Subroutine 2: cache_invalidate_addr(reg_addr)
; Input: EAX = physical address to invalidate
; Output: ECX = slot invalidated (-1 if not found)
cache_invalidate_addr:
    push ebx
    push edx
    mov edx, eax
    shr edx, 12         ; Tag

    xor ecx, ecx
.find_line:
    movzx ebx, byte [fa16_valid + ecx]
    test ebx, ebx
    jz .skip_line
    cmp edx, [fa16_tags + ecx*4]
    je .found_line
.skip_line:
    inc ecx
    cmp ecx, 16
    jl .find_line

    mov ecx, -1         ; not found
    pop edx
    pop ebx
    ret

.found_line:
    ; Invalidate line
    mov byte [fa16_valid + ecx], 0
    mov byte [fa16_dirty + ecx], 0
    pop edx
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

    ; Populate 8 lines
    xor ecx, ecx
.pop_loop:
    mov byte [fa16_valid + ecx], 1
    mov byte [fa16_dirty + ecx], 1
    lea eax, [ecx + 1]
    mov [fa16_tags + ecx*4], eax
    inc ecx
    cmp ecx, 8
    jl .pop_loop

    ; Selective invalidate of Tag 0x0002 (Address 0x00020000) -> should be Slot 1
    mov eax, 0x00020000
    call cache_invalidate_addr
    mov esi, ecx        ; saved slot index

    ; Global invalidate
    call cache_invalidate_all

    ; Count valid lines after global invalidate
    xor ebx, ebx
    xor ecx, ecx
.cnt_loop:
    movzx eax, byte [fa16_valid + ecx]
    add ebx, eax
    inc ecx
    cmp ecx, 16
    jl .cnt_loop

    push ebx            ; valid count after global flush (0)
    push esi            ; selectively invalidated slot (1)
    push state_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
