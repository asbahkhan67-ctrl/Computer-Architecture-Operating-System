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
msg1 db "Q19: Structural hazard: unified memory", 10, "LW IF1 ID2 EX3 MEM4 WB5. Instructions 2 and 3 fetch in cycles 2 and 3.", 10, "At CC4, LW MEM and instruction 4 IF compete for one memory port: IF stalls.", 10, "Instruction 4 fetches in CC5; separate I/D ports remove that structural stall.", 10, 10, 10, 0
msg2 db "Initial R2 = %d", 10, 0
msg3 db "Initial R4 = %d", 10, 0
msg4 db "Initial R5 = %d", 10, 0
msg5 db "Initial R7 = %d", 10, 0
msg6 db "Initial R8 = %d", 10, 0
msg7 db "Initial R10 = %d", 10, 0
msg8 db "Initial R11 = %d", 10, 0
msg9 db "LW [R2+0] -> R1 = %d", 10, 0
msg10 db "ADD -> R3 = %d", 10, 0
msg11 db "SUB -> R6 = %d", 10, 0
msg12 db "CC4: LW uses single memory port. AND instruction fetch waits one cycle.", 10, 0
msg13 db "CC5: port free; AND can be fetched.", 10, 0
msg14 db "AND -> R9 = %d", 10, 0
msg15 db "Program complete.", 10, 0
section .text
MAIN:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    and esp, -16
    SAY msg1
    mov dword [vr2], mem
    VALUE msg2, [vr2]
    mov dword [vr4], 10
    VALUE msg3, [vr4]
    mov dword [vr5], 20
    VALUE msg4, [vr5]
    mov dword [vr7], 9
    VALUE msg5, [vr7]
    mov dword [vr8], 2
    VALUE msg6, [vr8]
    mov dword [vr10], 12
    VALUE msg7, [vr10]
    mov dword [vr11], 10
    VALUE msg8, [vr11]
    mov edx, [vr2]
    mov eax, [edx+0]
    mov [vr1], eax
    VALUE msg9, [vr1]
    mov eax, [vr4]
    add eax, [vr5]
    mov [vr3], eax
    VALUE msg10, [vr3]
    mov eax, [vr7]
    sub eax, [vr8]
    mov [vr6], eax
    VALUE msg11, [vr6]
    SAY msg12
    nop
    SAY msg13
    mov eax, [vr10]
    and eax, [vr11]
    mov [vr9], eax
    VALUE msg14, [vr9]
    SAY msg15
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
