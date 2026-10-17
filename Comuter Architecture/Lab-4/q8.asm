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
msg1 db "Q8: Back-to-back address dependency", 10, "LW pointer IF1/MEM4; NOP IF2; second LW IF3/EX5/MEM6/WB7.", 10, "The second effective address needs the loaded pointer: one bubble.", 10, 10, 10, 0
msg2 db "Initial R2 = %d", 10, 0
msg3 db "R2 -> ptr; ptr[0] holds address of mem; mem[1]=60.", 10, 0
msg4 db "LW [R2+0] -> R1 = %d", 10, 0
msg5 db "NOP: one educational pipeline waiting slot", 10, 0
msg6 db "LW [R1+4] -> R3 = %d", 10, 0
msg7 db "Program complete.", 10, 0
section .text
MAIN:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    and esp, -16
    SAY msg1
    mov dword [vr2], pointer_cell
    VALUE msg2, [vr2]
    SAY msg3
    mov edx, [vr2]
    mov eax, [edx+0]
    mov [vr1], eax
    VALUE msg4, [vr1]
    nop
    SAY msg5
    mov edx, [vr1]
    mov eax, [edx+4]
    mov [vr3], eax
    VALUE msg6, [vr3]
    SAY msg7
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
