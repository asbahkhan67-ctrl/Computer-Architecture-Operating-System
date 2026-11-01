; Lab 4 - Task 19: Cache-Miss Pipeline Freeze Analysis
; Objective: Observe memory stalls halting the pipeline execution stages.
; Hazard: Data / Memory System Stall.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 19: Cache-Miss Pipeline Freeze Analysis ===", 10, 0
    theory_msg   db "[Memory Hierarchy Pipeline Stalls (Cache-Miss Freeze)]:", 10
                 db "  Modern pipelines must FREEZE execution units when an L1 cache miss occurs,", 10
                 db "  waiting for the memory controller / L2 cache line refill (tens to hundreds of cycles).", 10
                 db "  - Sequential Walk (4-byte stride): 1 compulsory miss per 64-byte line (15 cache hits).", 10
                 db "  - Strided Walk (64-byte stride)  : 100%% compulsory misses (Every access stalls the pipeline!).", 10, 10, 0

    bench_msg    db "[Benchmark on 64 KB Buffer (1,024 accesses each)]:", 10
                 db "  Sequential Access (4-Byte Stride) : %u cycles (%.2f cycles/access)", 10
                 db "  Strided Access    (64-Byte Stride): %u cycles (%.2f cycles/access)", 10
                 db "  Pipeline Freeze Stall Overhead    : %u cycles total (%d cycles/miss)", 10
                 db "Conclusion: Cache line misses halt pipeline execution stages dramatically.", 10, 0

    align 64
    buffer_64kb  times 16384 dd 1

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

    ; 1. Sequential Walk (1,024 accesses, stride 4 bytes)
    rdtsc
    mov esi, eax ; t0

    xor eax, eax
    xor ecx, ecx
.loop_seq:
    add eax, [buffer_64kb + ecx*4]
    inc ecx
    cmp ecx, 1024
    jl .loop_seq

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_seq

    ; 2. Strided Walk (1,024 accesses, stride 64 bytes = 16 dwords)
    rdtsc
    mov esi, eax ; t0

    xor eax, eax
    xor ecx, ecx
.loop_strided:
    add eax, [buffer_64kb + ecx*4]
    add ecx, 16         ; 16 dwords = 64 bytes (every access is on a new cache line!)
    cmp ecx, 16384
    jl .loop_strided

    rdtsc
    sub eax, esi
    mov ebx, eax ; cycles_strided

    ; Calculate stall delta = cycles_strided - cycles_seq
    mov edx, ebx
    sub edx, edi
    mov eax, edx
    xor edx, edx
    mov ecx, 1024
    div ecx             ; eax = stall cycles per miss

    push eax            ; cycles/miss
    mov edx, ebx
    sub edx, edi
    push edx            ; total stall overhead
    push ebx            ; cycles strided
    push edi            ; cycles seq
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
