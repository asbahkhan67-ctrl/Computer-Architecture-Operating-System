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
msg1 db "Q18: Unconditional jump delay", 10, "The PDF loop is infinite and decrements R1 on every jump.", 10, "This demo limits it to three iterations; each simulated jump executes its slot before transfer.", 10, 10, 10, 0
msg2 db "Initial R1 = %d", 10, 0
msg3 db "J LOOP: execute decrement in simulated delay slot.", 10, 0
msg4 db "Delay-slot SUB -> R1 = %d", 10, 0
msg5 db "Demo stops after 3 jumps; original pseudocode has no exit.", 10, 0
msg6 db "Program complete.", 10, 0
section .text
MAIN:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    and esp, -16
    SAY msg1
    mov dword [vr1], 3
    VALUE msg2, [vr1]
loop_demo:
    SAY msg3
    sub dword [vr1], 1
    VALUE msg4, [vr1]
    cmp dword [vr1], 0
    jg loop_demo
    SAY msg5
    SAY msg6
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
