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
msg1 db "Q14: Dot product element interleaving", 10, "Load X0 IF1, Y0 IF2, X1 IF3; multiply IF4; accumulate IF5.", 10, "X1 prefetch fills Y0 load-use gap. Multiply latency is unspecified: no exact MUL stall count claimed.", 10, "The PDF snippet accumulates only X0*Y0; this demo also completes X1*Y1.", 10, 10, 10, 0
msg2 db "Initial R1 = %d", 10, 0
msg3 db "Initial R2 = %d", 10, 0
msg4 db "Initial R10 = %d", 10, 0
msg5 db "X=[2,3], Y=[4,5].", 10, 0
msg6 db "LW [R1+0] -> R3 = %d", 10, 0
msg7 db "LW [R2+0] -> R4 = %d", 10, 0
msg8 db "LW [R1+4] -> R5 = %d", 10, 0
msg9 db "IMUL -> R6 = %d", 10, 0
msg10 db "ADD -> R10 = %d", 10, 0
msg11 db "End of PDF snippet: running sum=8, X1=3 prefetched. Extension completes second pair.", 10, 0
msg12 db "LW [R2+4] -> R7 = %d", 10, 0
msg13 db "NOP: one educational pipeline waiting slot", 10, 0
msg14 db "IMUL -> R6 = %d", 10, 0
msg15 db "ADD -> R10 = %d", 10, 0
msg16 db "Full dot product = 2*4 + 3*5 = 23.", 10, 0
msg17 db "Program complete.", 10, 0
section .text
MAIN:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    and esp, -16
    SAY msg1
    mov dword [vr1], x
    VALUE msg2, [vr1]
    mov dword [vr2], y
    VALUE msg3, [vr2]
    mov dword [vr10], 0
    VALUE msg4, [vr10]
    SAY msg5
    mov edx, [vr1]
    mov eax, [edx+0]
    mov [vr3], eax
    VALUE msg6, [vr3]
    mov edx, [vr2]
    mov eax, [edx+0]
    mov [vr4], eax
    VALUE msg7, [vr4]
    mov edx, [vr1]
    mov eax, [edx+4]
    mov [vr5], eax
    VALUE msg8, [vr5]
    mov eax, [vr3]
    imul eax, [vr4]
    mov [vr6], eax
    VALUE msg9, [vr6]
    mov eax, [vr10]
    add eax, [vr6]
    mov [vr10], eax
    VALUE msg10, [vr10]
    SAY msg11
    mov edx, [vr2]
    mov eax, [edx+4]
    mov [vr7], eax
    VALUE msg12, [vr7]
    nop
    SAY msg13
    mov eax, [vr5]
    imul eax, [vr7]
    mov [vr6], eax
    VALUE msg14, [vr6]
    mov eax, [vr10]
    add eax, [vr6]
    mov [vr10], eax
    VALUE msg15, [vr10]
    SAY msg16
    SAY msg17
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
