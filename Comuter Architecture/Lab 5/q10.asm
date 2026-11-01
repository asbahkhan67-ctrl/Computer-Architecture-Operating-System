; Lab 5 - Task 10: Fully Associative Software Emulation
; Objective: Model content-addressable memory (CAM) parallel search logic in software assembly.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 10: Fully Associative Software Emulation (CAM Search) ===", 10, 0
    theory_msg   db "[Content-Addressable Memory (CAM) Hardware Architecture & Trade-Offs]:", 10
                 db "  - Fully associative caches eliminate set indexing entirely: any line can reside in any entry.", 10
                 db "  - In hardware, every cache entry requires a dedicated hardware comparator circuit.", 10
                 db "  - For 8 entries: 8 comparators evaluate the input tag simultaneously in 1 clock cycle.", 10
                 db "  - Trade-off: High silicon area, power consumption, and capacitive wire load limit CAM", 10
                 db "    structures to small sizes (typically 16-64 entries, e.g., TLBs, trace caches).", 10
                 db "  - Software emulation must perform unrolled sequential linear search over all entries.", 10, 10, 0

    hit_msg      db "  Lookup Tag: 0x%05X ==> RESULT: CACHE HIT!  (Matched in Slot %d)", 10, 0
    miss_msg     db "  Lookup Tag: 0x%05X ==> RESULT: CACHE MISS! (Allocated into Slot %d via CAM replacement)", 10, 0

    ; 8-Entry CAM table: valid bytes and tags
    align 16
    cam_valid    db 1, 1, 1, 1, 0, 0, 0, 0
    align 4
    cam_tags     dd 0x10A, 0x20B, 0x30C, 0x40D, 0, 0, 0, 0

    test_tag_hit  dd 0x30C
    test_tag_miss dd 0x50E

section .text

; CAM Lookup Routine
; Input: EAX = search tag
; Output: ECX = slot index, EDX = 1 (Hit) or 0 (Miss)
cam_lookup:
    push ebx
    push esi

    ; Linear scan across all 8 entries
    xor ecx, ecx
.scan_loop:
    movzx ebx, byte [cam_valid + ecx]
    test ebx, ebx
    jz .skip_entry
    cmp eax, [cam_tags + ecx*4]
    je .hit_found
.skip_entry:
    inc ecx
    cmp ecx, 8
    jl .scan_loop

    ; Not found -> MISS
    xor edx, edx
    mov ecx, 4          ; allocate into first free slot (slot 4)
    mov byte [cam_valid + 4], 1
    mov [cam_tags + 4*4], eax
    jmp .done_cam

.hit_found:
    mov edx, 1          ; HIT!
.done_cam:
    pop esi
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

    ; Test 1: Hit test with Tag 0x30C
    mov eax, [test_tag_hit]
    call cam_lookup
    push ecx            ; matched slot
    push dword [test_tag_hit]
    push hit_msg
    call _printf
    add esp, 12

    ; Test 2: Miss test with Tag 0x50E
    mov eax, [test_tag_miss]
    call cam_lookup
    push ecx            ; allocated slot
    push dword [test_tag_miss]
    push miss_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
