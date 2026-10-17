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
msg1 db "Q7: Load-use with independent work", 10, "LW IF1/MEM4; independent SUB IF2/EX4; ADD IF3/EX5.", 10, "Independent work replaces the load-use bubble.", 10, 10, 10, 0
msg2 db "Initial R2 = %d", 10, 0
msg3 db "R2 points to mem; mem[0]=40.", 10, 0
msg4 db "Initial R4 = %d", 10, 0
msg5 db "Initial R6 = %d", 10, 0
msg6 db "Initial R7 = %d", 10, 0
msg7 db "LW [R2+0] -> R1 = %d", 10, 0
msg8 db "SUB -> R5 = %d", 10, 0
msg9 db "ADD -> R3 = %d", 10, 0
msg10 db "Program complete.", 10, 0
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
    SAY msg3
    mov dword [vr4], 2
    VALUE msg4, [vr4]
    mov dword [vr6], 20
    VALUE msg5, [vr6]
    mov dword [vr7], 3
    VALUE msg6, [vr7]
    mov edx, [vr2]
    mov eax, [edx+0]
    mov [vr1], eax
    VALUE msg7, [vr1]
    mov eax, [vr6]
    sub eax, [vr7]
    mov [vr5], eax
    VALUE msg8, [vr5]
    mov eax, [vr1]
    add eax, [vr4]
    mov [vr3], eax
    VALUE msg9, [vr3]
    SAY msg10
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
