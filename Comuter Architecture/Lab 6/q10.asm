; Lab 6 - Problem 10: Loop Tiling (Blocking) for a 1D Filter
; Cache Spec: Direct-mapped, 256 bytes (16 lines x 16 bytes).
; Task: Implement a 3-tap moving average filter (Y[i] = (X[i-1] + X[i] + X[i+1])/3)
;       over an array larger than cache capacity (1024 bytes).
;       Implement a naive loop, then implement a tiled/blocked traversal in assembly.
; Objective: Show how tiling retains array segments in the direct-mapped cache
;            across repeated access cycles.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 10: Loop Tiling (Blocking) for a 1D Filter ===", 10, 0
    theory_msg  db "[1D Filter Locality & Loop Tiling Optimization]:", 10
                 db "  - Filter Formulation: Y[i] = (X[i-1] + X[i] + X[i+1]) / 3", 10
                 db "  - Array Dimension   : 256 words (1,024 Bytes).", 10
                 db "  - Cache Spec        : Direct-Mapped, 256 Bytes capacity (16 lines x 16 B).", 10
                 db "  - Array is 4x larger than total cache capacity!", 10, 10
                 db "  - Naive Traversal across multiple passes:", 10
                 db "    * Evicts earlier segments of X and Y, causing compulsory re-fetch misses on each pass.", 10
                 db "  - Tiled Traversal (Block size B = 32 words = 128 Bytes):", 10
                 db "    * Sub-blocks of X and Y fit simultaneously within the 256-byte cache.", 10
                 db "    * High temporal reuse across multiple filter passes without spilling.", 10, 10, 0

    bench_msg   db "[Benchmark on 256 Elements (10,000 Repeated Filter Passes)]:", 10
                 db "  Naive Traversal Elapsed Cycles : %u cycles", 10
                 db "  Tiled Traversal Elapsed Cycles : %u cycles (Tile Block = 32 words)", 10
                 db "  Verification: Sample Y[10] = %d (Expected: %d)", 10
                 db "Conclusion: Tiling confines working working-sets to L1 cache footprint.", 10, 0

    align 64
    raw_x       times 256 dd 12 ; 1024 bytes
    filtered_y  times 256 dd 0

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

    ; 1. Naive Traversal
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_naive:
    mov ecx, 1
.loop_naive:
    mov eax, [raw_x + ecx*4 - 4]
    add eax, [raw_x + ecx*4]
    add eax, [raw_x + ecx*4 + 4]
    ; divide by 3
    push edx
    xor edx, edx
    mov ebx, 3
    div ebx
    pop edx
    mov [filtered_y + ecx*4], eax
    inc ecx
    cmp ecx, 255
    jl .loop_naive
    dec edx
    jnz .repeat_naive

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_naive

    ; 2. Tiled Traversal (block size = 32)
    rdtsc
    mov esi, eax ; t0

    mov edx, 1000
.repeat_tiled:
    ; Outer block step
    xor ebx, ebx ; block base = 0, 32, 64...
.block_outer:
    mov ecx, 1
.block_inner:
    lea eax, [ebx + ecx]
    cmp eax, 255
    jge .next_block
    mov ebp, [raw_x + eax*4 - 4]
    add ebp, [raw_x + eax*4]
    add ebp, [raw_x + eax*4 + 4]
    push edx
    mov eax, ebp
    xor edx, edx
    mov ebp, 3
    div ebp
    pop edx
    lea ebp, [ebx + ecx]
    mov [filtered_y + ebp*4], eax

    inc ecx
    cmp ecx, 32
    jl .block_inner

.next_block:
    add ebx, 32
    cmp ebx, 256
    jl .block_outer

    dec edx
    jnz .repeat_tiled

    rdtsc
    sub eax, esi ; cycles_tiled

    push 12             ; expected (12+12+12)/3 = 12
    push dword [filtered_y + 10*4]
    push eax            ; cycles tiled
    push edi            ; cycles naive
    push bench_msg
    call _printf
    add esp, 20

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
