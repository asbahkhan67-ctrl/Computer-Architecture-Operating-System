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
msg1 db "Q3: Manual NOP insertion (distance 2)", 10, "ADD IF1/WB5; independent AND IF2; NOP IF3; OR IF4/ID5/WB8.", 10, "Independent work hides one of the two required waiting slots.", 10, 10, 10, 0
msg2 db "Initial R4 = %d", 10, 0
msg3 db "Initial R5 = %d", 10, 0
msg4 db "Initial R7 = %d", 10, 0
msg5 db "Initial R8 = %d", 10, 0
msg6 db "Initial R10 = %d", 10, 0
msg7 db "ADD -> R2 = %d", 10, 0
msg8 db "AND -> R6 = %d", 10, 0
msg9 db "NOP: one educational pipeline waiting slot", 10, 0
msg10 db "OR -> R9 = %d", 10, 0
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
    mov dword [vr4], 10
    VALUE msg2, [vr4]
    mov dword [vr5], 20
    VALUE msg3, [vr5]
    mov dword [vr7], 12
    VALUE msg4, [vr7]
    mov dword [vr8], 10
    VALUE msg5, [vr8]
    mov dword [vr10], 1
    VALUE msg6, [vr10]
    mov eax, [vr4]
    add eax, [vr5]
    mov [vr2], eax
    VALUE msg7, [vr2]
    mov eax, [vr7]
    and eax, [vr8]
    mov [vr6], eax
    VALUE msg8, [vr6]
    nop
    SAY msg9
    mov eax, [vr2]
    or eax, [vr10]
    mov [vr9], eax
    VALUE msg10, [vr9]
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
