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
msg1 db "Q4: Multi-operand hazard", 10, "ADD R1 IF1/WB5; ADD R2 IF2/WB6; NOP IF3; NOP IF4; consumer IF5/ID6/WB9.", 10, "The younger producer R2 determines the two NOPs.", 10, 10, 10, 0
msg2 db "Initial R3 = %d", 10, 0
msg3 db "Initial R4 = %d", 10, 0
msg4 db "Initial R5 = %d", 10, 0
msg5 db "Initial R6 = %d", 10, 0
msg6 db "ADD -> R1 = %d", 10, 0
msg7 db "ADD -> R2 = %d", 10, 0
msg8 db "NOP: one educational pipeline waiting slot", 10, 0
msg9 db "NOP: one educational pipeline waiting slot", 10, 0
msg10 db "ADD -> R7 = %d", 10, 0
msg11 db "Program complete.", 10, 0
section .text
MAIN:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    and esp, -16
    SAY msg1
    mov dword [vr3], 10
    VALUE msg2, [vr3]
    mov dword [vr4], 20
    VALUE msg3, [vr4]
    mov dword [vr5], 7
    VALUE msg4, [vr5]
    mov dword [vr6], 8
    VALUE msg5, [vr6]
    mov eax, [vr3]
    add eax, [vr4]
    mov [vr1], eax
    VALUE msg6, [vr1]
    mov eax, [vr5]
    add eax, [vr6]
    mov [vr2], eax
    VALUE msg7, [vr2]
    nop
    SAY msg8
    nop
    SAY msg9
    mov eax, [vr1]
    add eax, [vr2]
    mov [vr7], eax
    VALUE msg10, [vr7]
    SAY msg11
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
