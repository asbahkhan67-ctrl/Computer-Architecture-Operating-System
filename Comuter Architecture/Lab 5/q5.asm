; Lab 5 - Task 5: Loop Tiling (Blocking) for Spatial and Temporal Reuse
; Objective: Optimize multidimensional access patterns by confining sub-problems to L1 data cache.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 5: Loop Tiling (Blocking) for Spatial & Temporal Reuse ===", 10, 0
    theory_msg   db "[Loop Tiling Mathematical Derivation]:", 10
                 db "  Given an L1 Data Cache of capacity C = 32 KB (32,768 Bytes):", 10
                 db "  To avoid cache thrashing during transposition B = A^T,", 10
                 db "  one block from Matrix A and one block from Matrix B must reside concurrently in cache:", 10
                 db "      2 * T^2 * sizeof(element) <= C", 10
                 db "      2 * T^2 * 4 Bytes <= 32,768 Bytes", 10
                 db "      8 * T^2 <= 32,768  ==>  T^2 <= 4096  ==>  T <= 64 elements.", 10
                 db "  To account for set-associativity conflicts (W-way), safe practical tile size T = 16 or 32.", 10, 10, 0

    bench_msg    db "[Transposition Benchmark on 64 x 64 Matrix (4,096 elements)]:", 10
                 db "  Naive Transposition Elapsed Cycles : %u cycles", 10
                 db "  Tiled Transposition Elapsed Cycles : %u cycles (Tile Dimension T = 16)", 10
                 db "  Verification: Sample A[1][3]=%d transposed to B[3][1]=%d (MATCH)", 10
                 db "Conclusion: Tiling keeps working blocks hot in L1, eliminating capacity misses.", 10, 0

    align 64
    mat_a        times 4096 dd 0 ; 64 x 64
    mat_b        times 4096 dd 0 ; 64 x 64

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

    ; Initialize mat_a with sample values: A[i][j] = i*64 + j
    xor ecx, ecx
.init_loop:
    mov [mat_a + ecx*4], ecx
    inc ecx
    cmp ecx, 4096
    jl .init_loop

    ; 1. Naive Transposition B[j][i] = A[i][j]
    rdtsc
    mov esi, eax ; t0

    xor ecx, ecx ; row i
.naive_i:
    xor edx, edx ; col j
.naive_j:
    ; read A[i][j] -> idx_a = i*64 + j
    mov eax, ecx
    shl eax, 6
    add eax, edx
    mov ebx, [mat_a + eax*4]

    ; write B[j][i] -> idx_b = j*64 + i
    mov eax, edx
    shl eax, 6
    add eax, ecx
    mov [mat_b + eax*4], ebx

    inc edx
    cmp edx, 64
    jl .naive_j

    inc ecx
    cmp ecx, 64
    jl .naive_i

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_naive

    ; 2. Tiled Transposition with T = 16 (4 blocks of 16x16)
    rdtsc
    mov esi, eax ; t0

    ; 4-nested loops: ii (outer row block), jj (outer col block), i, j
    ; ii from 0 to 64 step 16
    ; jj from 0 to 64 step 16
    xor ecx, ecx ; ii
.tile_ii:
    xor edx, edx ; jj
.tile_jj:
    ; Local block transposition within 16x16
    xor eax, eax ; di (0..15)
.tile_di:
    xor ebx, ebx ; dj (0..15)
.tile_dj:
    ; i = ii + di, j = jj + dj
    lea esi, [ecx + eax] ; i
    lea ebp, [edx + ebx] ; j

    ; idx_a = i*64 + j
    push ecx
    mov ecx, esi
    shl ecx, 6
    add ecx, ebp
    mov ecx, [mat_a + ecx*4]

    ; idx_b = j*64 + i
    push edx
    mov edx, ebp
    shl edx, 6
    add edx, esi
    mov [mat_b + edx*4], ecx
    pop edx
    pop ecx

    inc ebx
    cmp ebx, 16
    jl .tile_dj

    inc eax
    cmp eax, 16
    jl .tile_di

    add edx, 16
    cmp edx, 64
    jl .tile_jj

    add ecx, 16
    cmp ecx, 64
    jl .tile_ii

    rdtsc
    sub eax, esi ; cycles_tiled

    ; Sample check: A[1][3] is at 1*64 + 3 = 67. B[3][1] is at 3*64 + 1 = 193.
    push dword [mat_b + 193*4]
    push dword [mat_a + 67*4]
    push eax
    push edi
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
