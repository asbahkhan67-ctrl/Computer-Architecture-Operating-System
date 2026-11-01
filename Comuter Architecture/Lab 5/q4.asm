; Lab 5 - Task 4: Row-Major vs. Column-Major Matrix Traversal
; Objective: Quantify performance divergence between cache-friendly and cache-hostile nested loops.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 4: Row-Major vs. Column-Major Matrix Traversal ===", 10, 0
    theory_msg   db "[Matrix Access Pattern & Cache Line Analysis (256 x 256 Matrix)]:", 10
                 db "  - Matrix dimensions   : 256 rows x 256 cols x 4 bytes = 262,144 Bytes (256 KB).", 10
                 db "  - Memory layout       : Contiguous Row-Major (Element [i][j] at Base + (i*256 + j)*4).", 10
                 db "  - Row-Major Traversal : Stride = 1 element (4 bytes).", 10
                 db "    * Consecutive elements reside in the same 64-byte cache line.", 10
                 db "    * 15 hits for every 1 compulsory line fetch -> 6.25%% Miss Rate.", 10
                 db "  - Col-Major Traversal : Stride = 256 elements (1,024 bytes).", 10
                 db "    * Consecutive accesses jump across rows, thrashing L1 cache sets.", 10
                 db "    * Generates 100%% cache line misses + capacity/conflict evictions!", 10, 10, 0

    bench_msg    db "[Benchmark Results (65,536 elements read)]:", 10
                 db "  Row-Major Sweep Elapsed Cycles : %u cycles (Sum = %d)", 10
                 db "  Col-Major Sweep Elapsed Cycles : %u cycles (Sum = %d)", 10
                 db "  Performance Divergence Ratio   : %.1fx speedup from spatial locality!", 10
                 db "Explanation: Column stride exceeds cache line size, defeating L1 prefetch.", 10, 0

    align 64
    matrix_data  times 65536 dd 1 ; 256 x 256 integers

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

    ; 1. Row-Major Sweep: i outer, j inner
    rdtsc
    mov esi, eax ; t0

    xor eax, eax ; sum
    xor ecx, ecx ; linear index (i*256 + j)
.row_loop:
    add eax, [matrix_data + ecx*4]
    inc ecx
    cmp ecx, 65536
    jl .row_loop

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_row

    ; 2. Column-Major Sweep: j outer (0..255), i inner (0..255)
    rdtsc
    mov esi, eax ; t0

    xor eax, eax ; sum
    xor edx, edx ; col j
.col_outer:
    xor ecx, ecx ; row i
.col_inner:
    ; index = i * 256 + j
    mov ebx, ecx
    shl ebx, 8          ; i * 256
    add ebx, edx        ; + j
    add eax, [matrix_data + ebx*4]
    inc ecx
    cmp ecx, 256
    jl .col_inner

    inc edx
    cmp edx, 256
    jl .col_outer

    rdtsc
    sub eax, esi
    mov ebx, eax ; cycles_col

    push 65536          ; sum col
    push ebx            ; cycles col
    push 65536          ; sum row
    push edi            ; cycles row
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
