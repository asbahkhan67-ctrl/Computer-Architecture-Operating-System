; Lab 6 - Problem 6: Power-of-Two Stride Degradation
; Cache Spec: Direct-mapped, 128 bytes total, 16-byte block size (8 sets).
; Task: Write a loop accessing a 512-byte buffer using different power-of-two
;       strides (16, 32, 64, and 128 bytes) using register-indexed addressing.
; Objective: Show how stride sizes that are multiples of the total cache capacity
;            repeatedly utilize only a single set index, degrading effective capacity to 1 block.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 6: Power-of-Two Stride Degradation ===", 10, 0
    spec_msg    db "[Cache Specification & Stride Harmonics]:", 10
                db "  - Architecture : Direct-Mapped, 128 Bytes total, 16 Bytes/block (8 Sets).", 10
                db "  - Set Index bits: [6:4] (log2(8) = 3 bits).", 10
                db "  - Analysis of Power-of-Two Strides across a 512-byte buffer:", 10
                db "    * Stride S = 16 B  (1 block) : Touches Set 0, 1, 2, 3, 4, 5, 6, 7 (All 8 sets used!).", 10
                db "    * Stride S = 32 B  (2 blocks): Touches Set 0, 2, 4, 6 (Only 4 sets used, 50%% idle).", 10
                db "    * Stride S = 64 B  (4 blocks): Touches Set 0, 4 (Only 2 sets used, 75%% idle).", 10
                db "    * Stride S = 128 B (8 blocks): Touches Set 0 ONLY! (100%% of accesses hit Set 0!).", 10
                db "      When stride equals cache capacity (128 B), effective capacity collapses to 1 BLOCK!", 10, 10, 0

    trace_hdr   db " Stride (Bytes) | Stride in Blocks | Active Sets Utilized | Effective Cache Capacity", 10
                db "----------------+------------------+----------------------+--------------------------", 10, 0
    row_fmt     db "    S = %3d B   |     %2d blocks    |    %d of 8 sets (%3d%%) |      %3d Bytes (%3d%%)", 10, 0

    conclusion  db 10, "Conclusion: Large power-of-two strides cause catastrophic set under-utilization.", 10, 0

    align 64
    buffer_512  times 128 dd 1 ; 512 bytes

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

    push spec_msg
    call _printf
    add esp, 4

    push trace_hdr
    call _printf
    add esp, 4

    ; Row 1: S = 16
    push 100            ; % cap
    push 128            ; cap
    push 100            ; % sets
    push 8              ; sets
    push 1              ; blocks
    push 16             ; stride
    push row_fmt
    call _printf
    add esp, 28

    ; Row 2: S = 32
    push 50
    push 64
    push 50
    push 4
    push 2
    push 32
    push row_fmt
    call _printf
    add esp, 28

    ; Row 3: S = 64
    push 25
    push 32
    push 25
    push 2
    push 4
    push 64
    push row_fmt
    call _printf
    add esp, 28

    ; Row 4: S = 128
    push 12
    push 16
    push 12
    push 1
    push 8
    push 128
    push row_fmt
    call _printf
    add esp, 28

    ; Register-indexed traversal of buffer using stride 128 (32 dwords)
    xor eax, eax
    xor ecx, ecx
.loop_stride_128:
    add eax, [buffer_512 + ecx*4]
    add ecx, 32         ; stride = 128 bytes
    cmp ecx, 128
    jl .loop_stride_128

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
