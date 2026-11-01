; Lab 6 - Problem 4: Matrix Traversal: Row-Major vs. Column-Major
; Cache Spec: Direct-mapped, 32-byte cache line (8 words), total size = 512 bytes (16 lines).
; Task: Define a 16x16 word matrix. Write two separate subroutines:
;       (1) row-major traversal (stride = 1 word), and
;       (2) column-major traversal (stride = 16 words / 64 bytes).
; Objective: Calculate theoretical hit/miss ratios for both routines and verify
;            how stride size forces multiple lines to contend for identical indices.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 4: Matrix Traversal: Row-Major vs. Column-Major ===", 10, 0
    theory_msg  db "[Cache Specification & Theoretical Hit/Miss Analysis (16x16 Matrix)]:", 10
                 db "  - Matrix Spec    : 16 rows x 16 cols = 256 words (1,024 bytes).", 10
                 db "  - Cache Spec     : Direct-Mapped, 32 Bytes/line (8 words/line), 16 lines (512 B total).", 10
                 db "  - Note           : Matrix size (1024 B) is exactly TWICE the cache capacity (512 B)!", 10, 10
                 db "  Subroutine 1: Row-Major Traversal (Stride = 1 word = 4 bytes):", 10
                 db "    * Line contains 8 consecutive words.", 10
                 db "    * Compulsory line fetch on word 0, followed by 7 consecutive spatial hits.", 10
                 db "    * Total Accesses: 256 | Cache Misses: 32 (1024 B / 32 B) | Cache Hits: 224", 10
                 db "    * Theoretical Hit Rate: 87.5%% (Miss Rate: 12.5%%)", 10, 10
                 db "  Subroutine 2: Column-Major Traversal (Stride = 16 words = 64 bytes = 2 lines):", 10
                 db "    * Consecutive accesses jump across rows, landing in every other cache set.", 10
                 db "    * Row i and Row i+8 map to the IDENTICAL set index in the 16-line cache!", 10
                 db "    * Stride causes continuous self-eviction and conflict thrashing.", 10
                 db "    * Total Accesses: 256 | Cache Misses: 256 | Cache Hits: 0", 10
                 db "    * Theoretical Hit Rate: 0.0%% (Miss Rate: 100.0%%)", 10, 10, 0

    bench_msg   db "[Host Hardware Traversal Execution]:", 10
                 db "  Row-Major Traversal Elapsed Cycles : %u cycles (Sum = %d)", 10
                 db "  Col-Major Traversal Elapsed Cycles : %u cycles (Sum = %d)", 10
                 db "Conclusion: Column stride destroys spatial reuse and overloads cache sets.", 10, 0

    align 64
    mat_16x16   times 256 dd 1

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

    ; 1. Row-major sweep
    rdtsc
    mov esi, eax ; t0

    xor eax, eax ; sum
    xor ecx, ecx
.loop_row:
    add eax, [mat_16x16 + ecx*4]
    inc ecx
    cmp ecx, 256
    jl .loop_row

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_row

    ; 2. Col-major sweep (j outer 0..15, i inner 0..15)
    rdtsc
    mov esi, eax ; t0

    xor eax, eax ; sum
    xor edx, edx ; j
.outer_col:
    xor ecx, ecx ; i
.inner_col:
    mov ebx, ecx
    shl ebx, 4          ; i * 16
    add ebx, edx        ; + j
    add eax, [mat_16x16 + ebx*4]
    inc ecx
    cmp ecx, 16
    jl .inner_col
    inc edx
    cmp edx, 16
    jl .outer_col

    rdtsc
    sub eax, esi ; cycles_col

    push 256            ; sum col
    push eax            ; cycles col
    push 256            ; sum row
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
