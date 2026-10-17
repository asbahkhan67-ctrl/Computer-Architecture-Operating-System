; Standalone 32-bit NASM program. Build using NASM -f win32 and 32-bit MinGW GCC.
; Virtual MIPS registers live in memory; x86 executes the operations and prints traces.
; Printed pipeline cycles describe the educational model, not host CPU timing.
BITS 32
%ifidn __OUTPUT_FORMAT__,win32
    global _main
    extern _printf
    %define MAIN _main
    %define PRINTF _printf
%else
    global main
    extern printf
    %define MAIN main
    %define PRINTF printf
%endif

; Preserve all general registers and flags around output. Align the C call stack.
%macro SAY 1
    pushfd
    pushad
    mov ebx, esp
    and esp, -16
    sub esp, 12
    push dword %1
    call PRINTF
    mov esp, ebx
    popad
    popfd
%endmacro
%macro VALUE 2
    pushfd
    pushad
    mov ebx, esp
    mov eax, %2
    and esp, -16
    sub esp, 8
    push eax
    push dword %1
    call PRINTF
    mov esp, ebx
    popad
    popfd
%endmacro

section .data
vr0 dd 0
vr1 dd 0
vr2 dd 0
vr3 dd 0
vr4 dd 0
vr5 dd 0
vr6 dd 0
vr7 dd 0
vr8 dd 0
vr9 dd 0
vr10 dd 0
vr11 dd 0
mem dd 40, 60
x dd 2, 3
y dd 4, 5
pointer_cell dd mem
saved dd 0
msg1 db "Q1: Spot the RAW dependency", 10, "ADD: IF1 ID2 EX3 MEM4 WB5; adjacent SUB: IF2 ID3 EX4 MEM5 WB6.", 10, "Without forwarding/interlocks SUB reads old R1 in ID3: RAW hazard.", 10, "Real x86 preserves sequential results; stale read below is deliberately simulated.", 10, 10, 10, 0
msg2 db "Initial R1 = %d", 10, 0
msg3 db "Initial R2 = %d", 10, 0
msg4 db "Initial R3 = %d", 10, 0
msg5 db "Initial R5 = %d", 10, 0
msg6 db "Producer pending R1 (not committed yet) = %d", 10, 0
msg7 db "SUB -> R4 = %d", 10, 0
msg8 db "Above consumer deliberately read stale R1=5 (unprotected toy pipeline).", 10, 0
msg9 db "WB commits R1 = %d", 10, 0
msg10 db "SUB -> R4 = %d", 10, 0
msg11 db "Correct sequential result after the dependency is respected: R4=26.", 10, 0
msg12 db "Program complete.", 10, 0
section .text
MAIN:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    and esp, -16
    SAY msg1
    mov dword [vr1], 5
    VALUE msg2, [vr1]
    mov dword [vr2], 10
    VALUE msg3, [vr2]
    mov dword [vr3], 20
    VALUE msg4, [vr3]
    mov dword [vr5], 4
    VALUE msg5, [vr5]
    mov eax, [vr2]
    add eax, [vr3]
    mov [saved], eax
    VALUE msg6, [saved]
    mov eax, [vr1]
    sub eax, [vr5]
    mov [vr4], eax
    VALUE msg7, [vr4]
    SAY msg8
    mov eax, [saved]
    mov [vr1], eax
    VALUE msg9, [vr1]
    mov eax, [vr1]
    sub eax, [vr5]
    mov [vr4], eax
    VALUE msg10, [vr4]
    SAY msg11
    SAY msg12
    xor eax, eax
    lea esp, [ebp-12]
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
%ifidn __OUTPUT_FORMAT__,elf32
section .note.GNU-stack noalloc noexec nowrite progbits
%endif
