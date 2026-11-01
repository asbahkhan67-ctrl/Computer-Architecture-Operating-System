; Lab 4 - Task 20: Instruction-Cache Synchronization Hazards
; Objective: Investigate coherency between I-Cache and D-Cache in pipelined execution.
; Hazard: Structural & Control Hazard (coherency stall).

global _main
extern _printf

section .data
    title_msg    db "=== Lab 4 Task 20: Instruction-Cache Synchronization Hazards ===", 10, 0
    theory_msg   db "[Self-Modifying Code (SMC) & I-Cache / D-Cache Coherency]:", 10
                 db "  Processors maintain separate L1 Instruction (I-Cache) and Data (D-Cache).", 10
                 db "  When an upcoming instruction is modified via a data store:", 10
                 db "    1. The store modifies D-Cache (or write buffer).", 10
                 db "    2. The I-Cache or instruction prefetch buffer still holds the old opcode!", 10
                 db "    3. Hardware snooping detects self-modifying code, triggering a massive", 10
                 db "       pipeline clear / machine flush (structural & control hazard) to re-fetch.", 10, 10, 0

    smc_msg      db "[Dynamic Opcode Mutation Demonstration]:", 10
                 db "  Target instruction initial opcode : 0x90 (NOP)", 10
                 db "  Dynamically patching opcode to    : 0x40 (INC EAX)", 10
                 db "  Executing modified instruction stream...", 10, 0

    res_msg      db "[Verification & SMC Performance Impact]:", 10
                 db "  Initial EAX = %d", 10
                 db "  Result after dynamic patch execution: EAX = %d", 10
                 db "  SMC Execution Latency: %u cycles (includes pipeline flush & re-steer)", 10
                 db "Conclusion: Self-modifying code forces complete instruction-pipeline resynchronization.", 10, 0

    initial_val  dd 10
    final_val    dd 0

; Note: Code to be modified must be in a writable section (e.g., .data or writable text)
section .data
align 16
patchable_routine:
    push ebp
    mov ebp, esp
    mov eax, [ebp + 8]
patch_slot:
    nop                 ; byte offset to patch (initially NOP = 0x90)
    nop
    mov esp, ebp
    pop ebp
    ret

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

    push smc_msg
    call _printf
    add esp, 4

    ; Benchmark dynamic patching and pipeline flush
    rdtsc
    mov esi, eax ; t0

    ; Dynamically patch patch_slot: change NOP (0x90) to INC EAX (0x40)
    mov byte [patch_slot], 0x40
    mov byte [patch_slot + 1], 0x40 ; Two INC EAX instructions

    ; Call the self-modified code
    push dword [initial_val]
    call patchable_routine
    add esp, 4

    mov [final_val], eax

    rdtsc
    sub eax, esi ; cycles_smc

    push eax
    push dword [final_val]
    push dword [initial_val]
    push res_msg
    call _printf
    add esp, 16

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
