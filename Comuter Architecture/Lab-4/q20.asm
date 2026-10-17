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
msg1 db "Q20: Combined load-use and branch hazard", 10, "LW IF1 ID2 EX3 MEM4 WB5; NOP IF2; NOP IF3; BEQ IF4/ID5.", 10, "Two waits let ID5 read load data via WB-first register access or forwarding to ID.", 10, "Branch delay slot is an explicit NOP; target fetch follows that slot.", 10, 10, 10, 0
msg2 db "Taken branch example:", 10, 0
msg3 db "Initial R2 = %d", 10, 0
msg4 db "LW [R2+0] -> R1 = %d", 10, 0
msg5 db "NOP: one educational pipeline waiting slot", 10, 0
msg6 db "NOP: one educational pipeline waiting slot", 10, 0
msg7 db "BEQ evaluated after two waits; execute branch delay-slot NOP.", 10, 0
msg8 db "NOP: one educational pipeline waiting slot", 10, 0
msg9 db "Branch NOT taken: fall-through path.", 10, 0
msg10 db "Branch TAKEN: target path.", 10, 0
msg11 db "Not-taken branch example:", 10, 0
msg12 db "Initial R2 = %d", 10, 0
msg13 db "LW [R2+0] -> R1 = %d", 10, 0
msg14 db "NOP: one educational pipeline waiting slot", 10, 0
msg15 db "NOP: one educational pipeline waiting slot", 10, 0
msg16 db "BEQ evaluated after two waits; execute branch delay-slot NOP.", 10, 0
msg17 db "NOP: one educational pipeline waiting slot", 10, 0
msg18 db "Branch NOT taken: fall-through path.", 10, 0
msg19 db "Branch TAKEN: target path.", 10, 0
msg20 db "Program complete.", 10, 0
section .text
MAIN:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    and esp, -16
    SAY msg1
    SAY msg2
    mov dword [vr2], mem
    VALUE msg3, [vr2]
    mov dword [mem], 0
    mov edx, [vr2]
    mov eax, [edx+0]
    mov [vr1], eax
    VALUE msg4, [vr1]
    nop
    SAY msg5
    nop
    SAY msg6
    cmp dword [vr1], 0
    sete byte [saved]
    SAY msg7
    nop
    SAY msg8
    cmp byte [saved], 1
    je taken_0
    SAY msg9
    jmp end_0
taken_0:
    SAY msg10
end_0:
    SAY msg11
    mov dword [vr2], mem
    VALUE msg12, [vr2]
    mov dword [mem], 7
    mov edx, [vr2]
    mov eax, [edx+0]
    mov [vr1], eax
    VALUE msg13, [vr1]
    nop
    SAY msg14
    nop
    SAY msg15
    cmp dword [vr1], 0
    sete byte [saved]
    SAY msg16
    nop
    SAY msg17
    cmp byte [saved], 1
    je taken_1
    SAY msg18
    jmp end_1
taken_1:
    SAY msg19
end_1:
    SAY msg20
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
