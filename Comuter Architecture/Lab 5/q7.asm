; Lab 5 - Task 7: Address Bit-Field Extraction (Tag, Set Index, Block Offset)
; Objective: Implement internal hardware decoder logic that maps a physical address to cache sets and tags.

global _main
extern _printf

section .data
    title_msg    db "=== Lab 5 Task 7: Address Bit-Field Extraction ===", 10, 0
    spec_msg     db "[Hardware Cache Specification (4 KB Direct-Mapped)]:", 10
                 db "  - Architecture : 32-bit physical address space.", 10
                 db "  - Cache Size   : C = 4 KB (4,096 bytes).", 10
                 db "  - Block Size   : B = 32 bytes  ==> Block Offset = log2(32) = 5 bits [4:0].", 10
                 db "  - Number of Sets: S = C / B = 4096 / 32 = 128 sets ==> Set Index = log2(128) = 7 bits [11:5].", 10
                 db "  - Tag Field    : 32 - (5 + 7) = 20 bits [31:12].", 10, 10, 0

    hdr_msg      db "  Physical Address | Tag (bits 31:12) | Set Index (11:5) | Offset (4:0)", 10
                 db "  -----------------+------------------+------------------+-------------", 10, 0
    row_fmt      db "     0x%08X    |     0x%05X        |       %3d (0x%02X)   |   %2d (0x%02X)", 10, 0

    test_addr1   dd 0x00000000
    test_addr2   dd 0x0000001F
    test_addr3   dd 0x80001FE0

section .text

; Subroutine: decode_address
; Input : EAX = 32-bit physical address (r0)
; Output: EBX = Block Offset (bits 4:0) (r1)
;         ECX = Set Index (bits 11:5)   (r2)
;         EDX = Tag (bits 31:12)        (r3)
decode_address:
    ; 1. Block Offset: bits [4:0] -> mask 0x1F (31)
    mov ebx, eax
    and ebx, 0x1F

    ; 2. Set Index: bits [11:5] -> shift right 5, mask 0x7F (127)
    mov ecx, eax
    shr ecx, 5
    and ecx, 0x7F

    ; 3. Tag: bits [31:12] -> shift right 12
    mov edx, eax
    shr edx, 12
    ret

_main:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    push title_msg
    call _printf
    add esp, 4

    push spec_msg
    call _printf
    add esp, 4

    push hdr_msg
    call _printf
    add esp, 4

    ; Test 1: 0x00000000
    mov eax, [test_addr1]
    call decode_address
    push ebx
    push ebx
    push ecx
    push ecx
    push edx
    push dword [test_addr1]
    push row_fmt
    call _printf
    add esp, 28

    ; Test 2: 0x0000001F
    mov eax, [test_addr2]
    call decode_address
    push ebx
    push ebx
    push ecx
    push ecx
    push edx
    push dword [test_addr2]
    push row_fmt
    call _printf
    add esp, 28

    ; Test 3: 0x80001FE0
    mov eax, [test_addr3]
    call decode_address
    push ebx
    push ebx
    push ecx
    push ecx
    push edx
    push dword [test_addr3]
    push row_fmt
    call _printf
    add esp, 28

    pop edi
    pop esi
    pop ebx
    xor eax, eax
    mov esp, ebp
    pop ebp
    ret
