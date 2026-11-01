; Lab 5 - Task 15: Write-Through vs. Write-Back Buffer Pressure
; Objective: Observe store buffer stalls and write-merge efficiency.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 15: Write-Through vs. Write-Back Buffer Pressure ===", 10, 0
    theory_msg   db "[Write Mechanics: Write-Through vs. Write-Back Stalls]:", 10
                 db "  - Pattern 1 (Repeated stores to 1 cache-resident address):", 10
                 db "    * Under Write-Back: Initial write sets Dirty bit. All subsequent 49,999 stores", 10
                 db "      are absorbed entirely in the L1 D-Cache with zero external bus transactions!", 10
                 db "  - Pattern 2 (Dispersed stores across un-cached / strided memory):", 10
                 db "    * Every store triggers an external memory transaction or Line Fill Buffer allocation.", 10
                 db "    * Saturates the hardware Store Buffer (typically 4-12 entries in modern CPUs),", 10
                 db "      forcing execution units to stall waiting for write-merge bus drain.", 10, 10, 0

    bench_msg    db "[Benchmark on 50,000 Store Instructions]:", 10
                 db "  Single-Address Absorbed Stores : %u cycles (%.2f cycles/store)", 10
                 db "  Dispersed Saturated Stores     : %u cycles (%.2f cycles/store)", 10
                 db "  Store-Stall Overhead Ratio     : %.1fx latency penalty under buffer saturation.", 10
                 db "Conclusion: Write-back caching absorbs repetitive store pressure effectively.", 10, 0

    align 64
    single_target dd 0
    align 64
    dispersed_buf times 65536 dd 0 ; 256 KB buffer

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

    ; 1. Single-Address Repeated Stores (Absorbed by cache)
    rdtsc
    mov esi, eax ; t0

    mov ecx, 50000
    lea edx, [single_target]
.loop_single:
    mov [edx], ecx
    dec ecx
    jnz .loop_single

    rdtsc
    sub eax, esi
    mov edi, eax ; cycles_single

    ; 2. Dispersed Stores (Stride 64 bytes = 16 dwords)
    rdtsc
    mov esi, eax ; t0

    mov ecx, 50000
    xor edx, edx
.loop_dispersed:
    mov [dispersed_buf + edx*4], ecx
    add edx, 16         ; 64-byte stride (hits separate cache lines)
    and edx, 65535      ; wrap inside buffer
    dec ecx
    jnz .loop_dispersed

    rdtsc
    sub eax, esi
    mov ebx, eax ; cycles_dispersed

    push ebx            ; cycles dispersed
    push edi            ; cycles single
    push bench_msg
    call _printf
    add esp, 12

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
