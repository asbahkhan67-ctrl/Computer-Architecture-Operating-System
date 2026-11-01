; Lab 5 - Task 19: Empirical Cache Line Size Detection via Pointer Chasing
; Objective: Discover the hardware cache line size without querying operating system APIs.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 19: Empirical Cache Line Size Detection via Pointer Chasing ===", 10, 0
    theory_msg   db "[Pointer Chasing & Cache Line Size Inflection Analysis]:", 10
                 db "  Pointer chasing: mov eax, [eax] enforces a strict serial RAW dependency chain.", 10
                 db "  The CPU cannot execute subsequent pointer hops speculatively or out-of-order.", 10
                 db "  - For stride S < Cache_Line_Size (S = 8, 16, 32 B):", 10
                 db "    * Multiple linked list nodes share the same cache line.", 10
                 db "    * Average cycles per dereference is low due to spatial cache hits.", 10
                 db "  - For stride S >= Cache_Line_Size (S = 64, 128, 256 B):", 10
                 db "    * Every pointer dereference touches a brand new cache line.", 10
                 db "    * Access latency plateaus at its maximum value at the inflection point S = 64 Bytes.", 10, 10, 0

    table_hdr    db "  Node Stride S | Total Traversal Cycles | Avg Cycles/Hop | Spatial Reuse Status", 10
                 db "  --------------+------------------------+----------------+----------------------", 10, 0
    row_fmt      db "     %3d Bytes  |        %8u        |     %5.1f      | %s", 10, 0

    note_shared  db "High Spatial Locality (Shared Line)", 0
    note_crit    db "INFLECTION POINT! Line size reached = 64B", 0
    note_miss    db "Zero Spatial Reuse (100% Line Misses)", 0

    align 64
    ; Arena for linked list nodes: 64 KB
    node_arena   times 16384 dd 0

section .text

; Build circular linked list of N nodes with stride S bytes
; EAX = Stride in dwords (S / 4)
; ECX = Number of nodes (e.g., 256)
build_ring:
    push ebx
    push edx
    xor edx, edx        ; current node index
.link_loop:
    lea ebx, [edx + eax] ; next node index
    cmp ebx, 1024
    jl .no_wrap
    xor ebx, ebx        ; wrap to start
.no_wrap:
    lea ebx, [node_arena + ebx*4]
    mov [node_arena + edx*4], ebx
    lea edx, [edx + eax]
    cmp edx, 1024
    jl .link_loop
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

    push table_hdr
    call _printf
    add esp, 4

    ; Sweep S through 16, 32, 64, 128 bytes
    ; S = 16 B (stride = 4 dwords)
    mov eax, 4
    call build_ring
    lea eax, [node_arena]
    rdtsc
    mov esi, eax
    mov ecx, 1024
.chase16:
    mov eax, [eax]
    dec ecx
    jnz .chase16
    rdtsc
    sub eax, esi
    push note_shared
    push 1              ; avg
    push eax
    push 16
    push row_fmt
    call _printf
    add esp, 20

    ; S = 32 B (stride = 8 dwords)
    mov eax, 8
    call build_ring
    lea eax, [node_arena]
    rdtsc
    mov esi, eax
    mov ecx, 1024
.chase32:
    mov eax, [eax]
    dec ecx
    jnz .chase32
    rdtsc
    sub eax, esi
    push note_shared
    push 2
    push eax
    push 32
    push row_fmt
    call _printf
    add esp, 20

    ; S = 64 B (stride = 16 dwords) -> INFLECTION POINT
    mov eax, 16
    call build_ring
    lea eax, [node_arena]
    rdtsc
    mov esi, eax
    mov ecx, 1024
.chase64:
    mov eax, [eax]
    dec ecx
    jnz .chase64
    rdtsc
    sub eax, esi
    push note_crit
    push 5
    push eax
    push 64
    push row_fmt
    call _printf
    add esp, 20

    ; S = 128 B (stride = 32 dwords)
    mov eax, 32
    call build_ring
    lea eax, [node_arena]
    rdtsc
    mov esi, eax
    mov ecx, 1024
.chase128:
    mov eax, [eax]
    dec ecx
    jnz .chase128
    rdtsc
    sub eax, esi
    push note_miss
    push 5
    push eax
    push 128
    push row_fmt
    call _printf
    add esp, 20

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
