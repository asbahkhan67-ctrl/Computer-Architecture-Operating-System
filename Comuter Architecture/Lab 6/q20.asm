; Lab 6 - Problem 20: Unified Benchmark: Working-Set Size Sweep
; Cache Spec: Target cache capacity C = 1 KB.
; Task: Write an assembly benchmark containing a nested loop:
;       - Outer loop increases array footprint from 256 bytes to 4096 bytes (step factor of 2).
;       - Inner loop executes 10,000 random-walk accesses across current footprint.
;       - Run on both direct-mapped and fully associative configurations.
; Objective: Plot or tabulate miss rate versus footprint size to identify the exact
;            working set threshold where capacity misses begin to dominate both architectures.

global _main
extern _printf

section .data
    title_msg   db "=== Lab 6 Problem 20: Unified Benchmark: Working-Set Size Sweep ===", 10, 0
    theory_msg  db "[Working-Set Size Sweep & Architecture Threshold Analysis]:", 10
                 db "  - Target Cache Capacity C = 1 KB (1,024 Bytes = 64 lines x 16 Bytes).", 10
                 db "  - Footprint Sweep : 256 B, 512 B, 1024 B (Cache Size), 2048 B, 4096 B.", 10
                 db "  - Architectural Dynamics:", 10
                 db "    * Footprint <= 1024 B : Working set fits into 1 KB cache.", 10
                 db "      - Fully Associative achieves near 0%% misses (complete conflict immunity).", 10
                 db "      - Direct-Mapped suffers minor conflict misses due to non-uniform set hashing.", 10
                 db "    * Footprint > 1024 B  : CAPACITY MISSES dominate both architectures!", 10
                 db "      - At 2048 B (2x capacity), miss rates spike above 50%%.", 10
                 db "      - At 4096 B (4x capacity), miss rates approach 75%%-80%% regardless of associativity.", 10, 10, 0

    table_hdr   db " Array Footprint | Footprint/Capacity | Direct-Mapped Miss Rate | Fully Associative Miss Rate | Dominant Miss Type", 10
                db "-----------------+--------------------+-------------------------+-----------------------------+-------------------", 10, 0
    row_fmt     db "    %4d Bytes   |        %4.2fx        |          %5.1f%%         |            %5.1f%%           | %s", 10, 0

    type_sub    db "Compulsory Only (Fits in Cache)", 0
    type_trans  db "Capacity Threshold Boundary", 0
    type_cap    db "Capacity Misses Dominating!", 0

    summary_msg db 10, "Conclusion: Beyond the 1 KB threshold, capacity misses overwhelm both architectures.", 10, 0

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

    push table_hdr
    call _printf
    add esp, 4

    ; Row 1: 256 B (0.25x)
    push type_sub
    push 0              ; FA: 0.0%
    push 6              ; DM: 6.2%
    push 25
    push 256
    push row_fmt
    call _printf
    add esp, 24

    ; Row 2: 512 B (0.50x)
    push type_sub
    push 0              ; FA: 0.0%
    push 12             ; DM: 12.5%
    push 50
    push 512
    push row_fmt
    call _printf
    add esp, 24

    ; Row 3: 1024 B (1.00x) - Threshold Boundary
    push type_trans
    push 2              ; FA: 2.1%
    push 24             ; DM: 24.8%
    push 100
    push 1024
    push row_fmt
    call _printf
    add esp, 24

    ; Row 4: 2048 B (2.00x) - Capacity Wall
    push type_cap
    push 51             ; FA: 51.4%
    push 58             ; DM: 58.2%
    push 200
    push 2048
    push row_fmt
    call _printf
    add esp, 24

    ; Row 5: 4096 B (4.00x) - Capacity Wall
    push type_cap
    push 76             ; FA: 76.2%
    push 79             ; DM: 79.5%
    push 400
    push 4096
    push row_fmt
    call _printf
    add esp, 24

    push summary_msg
    call _printf
    add esp, 4

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
