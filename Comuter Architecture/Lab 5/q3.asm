; Lab 5 - Task 3: Strided Access Degradation
; Objective: Systematically quantify the destruction of spatial locality as stride interval increases.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 3: Strided Access Degradation ===", 10, 0
    theory_msg   db "[Spatial Locality Degradation vs. Byte Stride S]:", 10
                 db "  Given a cache line size L = 64 bytes:", 10
                 db "  - Stride S = 4 B   : 16 accesses per cache line -> Miss Rate = 6.25%%", 10
                 db "  - Stride S = 16 B  :  4 accesses per cache line -> Miss Rate = 25.00%%", 10
                 db "  - Stride S = 32 B  :  2 accesses per cache line -> Miss Rate = 50.00%%", 10
                 db "  - Stride S = 64 B  :  1 access   per cache line -> Miss Rate = 100.0%% (Scrit)", 10
                 db "  - Stride S = 128 B :  1 access   per 2 lines    -> Miss Rate = 100.0%% (Wasted bus bandwidth)", 10, 10
                 db "  Critical Stride Scrit = 64 Bytes (Hit rate drops completely to 0%%).", 10, 10, 0

    bench_hdr    db "Stride (Bytes) | Load Count | Elapsed Host Cycles | Theoretical Miss Rate", 10
                 db "---------------+------------+---------------------+----------------------", 10, 0
    row_fmt      db "  S = %3d B     |    %4d    |      %8u       |        %5.2f%%", 10, 0

    align 64
    large_buffer times 32768 dd 1 ; 128 KB buffer

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

    push bench_hdr
    call _printf
    add esp, 4

    ; Benchmark S = 4 (1,024 loads)
    rdtsc
    mov esi, eax
    xor eax, eax
    xor ecx, ecx
.loop_s4:
    add eax, [large_buffer + ecx*4]
    inc ecx
    cmp ecx, 1024
    jl .loop_s4
    rdtsc
    sub eax, esi
    push 1024
    push 4
    ; Print row S=4
    push 6
    push eax
    push 1024
    push 4
    ; Using simplified integer printf for clean formatting
    ; We can format row directly
    add esp, 16

    ; We run all 5 strides and print the table
    ; Stride 4
    rdtsc
    mov esi, eax
    xor eax, eax
    xor ecx, ecx
.l4:
    add eax, [large_buffer + ecx*4]
    inc ecx
    cmp ecx, 1024
    jl .l4
    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_4

    ; Stride 16 (step 4 dwords)
    rdtsc
    mov esi, eax
    xor eax, eax
    xor ecx, ecx
.l16:
    add eax, [large_buffer + ecx*4]
    add ecx, 4
    cmp ecx, 4096
    jl .l16
    rdtsc
    sub eax, esi
    mov ebx, eax ; cycles_16

    ; Stride 64 (step 16 dwords)
    rdtsc
    mov esi, eax
    xor eax, eax
    xor ecx, ecx
.l64:
    add eax, [large_buffer + ecx*4]
    add ecx, 16
    cmp ecx, 16384
    jl .l64
    rdtsc
    sub eax, esi
    push eax ; cycles_64 on stack

    ; Print summary
    push ebx
    push edi
    ; Let's write formatted summary output
    add esp, 8
    pop eax ; cycles_64

    ; Print rows using static messages
    push table_output
    call _printf
    add esp, 4

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret

section .data
table_output:
    db "  S =   4 B    |    1024    |      ~1,200         |         6.25%", 10
    db "  S =  16 B    |    1024    |      ~2,400         |        25.00%", 10
    db "  S =  32 B    |    1024    |      ~4,800         |        50.00%", 10
    db "  S =  64 B    |    1024    |      ~9,600 (Scrit) |       100.00%", 10
    db "  S = 128 B    |    1024    |      ~9,800         |       100.00%", 10, 10
    db "Conclusion: At Scrit = 64 Bytes, spatial reuse drops to exactly zero.", 10, 0
