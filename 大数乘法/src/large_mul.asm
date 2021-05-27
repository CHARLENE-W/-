.386
.model flat, stdcall
option casemap : none

includelib E:\masm32\lib\msvcrt.lib
include E:\masm32\include\msvcrt.inc

.data
numA_char byte 200 dup(0)
numB_char byte 200 dup(0)
numA_int dw 200 dup(0)
numB_int dw 200 dup(0)
ans_char byte 400 dup(0)
ans_int dw 400 dup(0)

lenA dd 0
lenB dd 0
len_ans dd 0

radix dw 0ah
Flag db 0

Flag_char db "-"

inputMsg byte "please input a large multiplier: ",0
szFmt_s byte "%s", 0
szFmt_d byte "%d", 0

outputMsg byte "the result is %s",0ah,0
outputMsg2 byte "the result is %s%s",0ah,0

.code
intTochar proc C uses eax ebx
    mov ebx,0
    .while ebx != len_ans
        mov ax, ans_int[ebx*2]
        add ax,30H
        push ax
        inc ebx
    .endw
    
    mov ebx,0
    .while ebx != len_ans
        pop ax
        mov ans_char[ebx],al
        inc ebx
    .endw
    ret
intTochar endp

large_mul proc C uses ebx eax ecx edx esi
    mov ebx,0
    .while ebx !=lenB
        mov ecx,0
        .while ecx !=lenA
        mov eax,0
        mov esi,ebx
        add esi,ecx
        mov ax,numA_int[ecx*2]
        mul  numB_int[ebx*2]
        add ans_int[esi*2],ax
        inc ecx
        .endw
        inc ebx
    .endw
    inc esi
    mov len_ans,esi
    mov ebx,0
    mov ecx,0
    .while ebx != len_ans
    mov edx,0
    mov ax,ans_int[ebx*2]
    add ax,cx
    cmp ax,0ah
    jl L1
    div  radix
    mov ans_int[ebx*2],dx
    mov cx,ax
    jmp L2
  L1: 
     mov ans_int[ebx*2],ax
     mov cx,0
  L2:
    inc ebx
    .endw
    .if cx != 0
        mov ebx,len_ans
        mov ans_int[ebx*2],cx
        inc len_ans
    .endif
    invoke intTochar
    ret
large_mul endp



charToint proc C uses ax ebx esi num_char:ptr byte, num_int:ptr word, len:dword
    mov ecx,len
    mov esi ,num_char
L1:  
    movzx ax, byte ptr [esi]
    sub ax,30H
    push ax
    add esi,1
    loop L1

    mov ecx,len
    mov esi ,num_int
L2: 
    pop ax
    mov word ptr [esi],ax
    add esi,2
    loop L2
    ret
charToint endp

getAlen proc C uses eax 
    .if numA_char == 2DH ;;2DH��ӦASCII��Ϊ'-'
        xor Flag ,1
        invoke crt_strlen,addr (numA_char+1)
        mov lenA,eax
        invoke charToint,addr(numA_char+1),addr numA_int,lenA
    .else
        invoke crt_strlen,addr (numA_char)
        mov lenA,eax
        invoke charToint ,addr (numA_char),addr numA_int,lenA
    .endif
    ret
getAlen endp

getBlen proc C uses eax
    .if numB_char[0] == 2DH ;;2DH��ӦASCII��Ϊ'-'
        xor Flag ,1
        invoke crt_strlen,addr (numB_char+1)
        mov lenB,eax
        invoke charToint ,addr (numB_char+1) ,addr numB_int,lenB
    .else
        invoke crt_strlen,addr (numB_char)
        mov lenB,eax
        invoke charToint ,addr (numB_char),addr numB_int,lenB
    .endif
    ret
getBlen endp

main proc 
	invoke crt_printf,addr inputMsg
    invoke crt_scanf,addr szFmt_s,addr numA_char
    invoke crt_printf,addr inputMsg
    invoke crt_scanf,addr szFmt_s,addr numB_char
    invoke getAlen
    invoke getBlen
    invoke large_mul
    .if Flag == 1
        invoke crt_printf,outputMsg2,addr Flag_char,addr ans_char
    .else
        invoke crt_printf,addr outputMsg,addr ans_char
    .endif
    ret
main endp
start:
    invoke main
end start

