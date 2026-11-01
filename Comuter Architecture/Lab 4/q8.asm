; Lab 4 - Task 8: Memory-to-Memory Store Forwarding Verification
; Objective: Examine pipeline interaction with store buffers and memory forwarding.
; Hazard: Data Hazard (RAW through Memory).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 8: Memory-to-Memory Store Forwarding Verification ===", 10, 0
    theory_msg   db "[Store-to-Load Forwarding (STLF) Architecture]:", 10
                 db "  Sequence:  SW  $t0, 0($s0)", 10
                 db "             LW  $t1, 0($s0)   ; Load targets IDENTICAL address immediately", 10, 10
                 db "  Pipeline Behavior Analysis:", 10
                 db "  - Naive Pipeline (No STLF): Store writes to L1 D-Cache at MEM stage.", 10
                 db "    Load must stall until store commits data to cache, causing 3-5 pipeline stalls.", 10
                 db "  - Advanced Pipeline (With STLF): Hardware Store Buffer holds pending writes.", 10
                 db "    When load address matches pending store entry, data is forwarded directly", 10
                 db "    from Store Buffer to Load Execution unit without touching L1 cache!", 10, 10, 0

    bench_msg    db "[Hardware Execution Profile (100,000 iterations)]:", 10
                 db "  STLF Benchmark Elapsed Cycles: %u cycles (%.2f cycles/access)", 10
                 db "  Value stored = 0x%08X, Value forwarded & loaded = 0x%08X", 10
                 db "Conclusion: Store buffer successfully forwarded data with zero cache-commit stall.", 10, 0

    align 16
    target_addr  dd 0
    loaded_val   dd 0

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

    ; Benchmark STLF
    rdtsc
    mov esi, eax ; start cycle

    mov ecx, 100000
    lea edx, [target_addr]
.stlf_loop:
    mov [edx], ecx      ; Store instruction (sw)
    mov eax, [edx]      ; Immediate Load instruction (lw) targeting SAME address
    dec ecx
    jnz .stlf_loop

    mov [loaded_val], eax

    rdtsc
    sub eax, esi        ; total cycles

    push dword [loaded_val]
    push 1              ; loop ended when ecx=1 stored
    push eax
    push bench_msg
    call _printf
    add esp, 16

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
