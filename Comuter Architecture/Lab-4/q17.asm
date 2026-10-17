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
msg1 db "Q17: Branch delay slot: NOP fallback", 10, "Decrement must happen before branch comparison. Delay slot is NOP.", 10, "For an ID-stage branch, an immediately preceding ALU producer may also need a data stall.", 10, "Exact extra wait depends on forwarding to ID; the PDF omits that detail.", 10, 10, 10, 0
msg2 db "Taken branch example:", 10, 0
msg3 db "Initial R4 = %d", 10, 0
msg4 db "SUB -> R4 = %d", 10, 0
msg5 db "NOP: one educational pipeline waiting slot", 10, 0
msg6 db "Branch NOT taken: fall-through path.", 10, 0
msg7 db "Branch TAKEN: target path.", 10, 0
msg8 db "Not-taken branch example:", 10, 0
msg9 db "Initial R4 = %d", 10, 0
msg10 db "SUB -> R4 = %d", 10, 0
msg11 db "NOP: one educational pipeline waiting slot", 10, 0
msg12 db "Branch NOT taken: fall-through path.", 10, 0
msg13 db "Branch TAKEN: target path.", 10, 0
msg14 db "Program complete.", 10, 0
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
    mov dword [vr4], 1
    VALUE msg3, [vr4]
    sub dword [vr4], 1
    VALUE msg4, [vr4]
    cmp dword [vr4], 0
    sete byte [saved]
    nop
    SAY msg5
    cmp byte [saved], 1
    je taken_0
    SAY msg6
    jmp end_0
taken_0:
    SAY msg7
end_0:
    SAY msg8
    mov dword [vr4], 2
    VALUE msg9, [vr4]
    sub dword [vr4], 1
    VALUE msg10, [vr4]
    cmp dword [vr4], 0
    sete byte [saved]
    nop
    SAY msg11
    cmp byte [saved], 1
    je taken_1
    SAY msg12
    jmp end_1
taken_1:
    SAY msg13
end_1:
    SAY msg14
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
