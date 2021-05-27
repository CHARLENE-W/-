.386
.model flat,stdcall
option casemap:none

include E:\masm32\include\windows.inc
include E:\masm32\include\user32.inc
include E:\masm32\include\kernel32.inc
include E:\masm32\include\gdi32.inc
includelib  E:\masm32\lib\user32.lib
includelib E:\masm32\lib\kernel32.lib
includelib E:\masm32\lib\gdi32.lib

IDD_Caption equ 129
IDM_Caption equ 130
IDM_M equ 40000
IDCANCEL equ 2
IDOK equ 1
IDC_CaptionA equ 1000
IDC_CaptionB equ 1001
IDC_STATIC equ -1

.data
hInstance dd ?
hFileA dd ?
hFileB dd ?
rowList dw 500 dup(?)
outputString BYTE 500 dup(?)
row1 dw ?
row2 dw ?
szPathA dd 2048 dup(?)
szPathB dd 2048 dup(?)
bufferFileA db 1024 dup(?)
bufferSizeA dw ($-bufferFileA )
bufferFileB db 1024 dup(?)
bufferSizeB  dw ($-bufferFileB )
listCount dw 0
rowNum dw 1
byteCountA dw ?
byteCountB dw ?
.const
;szPathA db  "E:\Projects\ASM_Projects\1.txt",0
;szPathB db  "E:\Projects\ASM_Projects\2.txt",0
szOpenError db "open File error",0
szReadError db "read File error",0
szNotEqual  db "File A and File B are different.",0
szEqual  db "File A and File B are same.",0
szCaption db "debug",0
szMBCap db "Message Box!",0
szMsg db "hello,bug",0
point db ","

.code 
divdw proc 
	jcxz divdw_return	;除数cx为0，直接返回
	push bx			;作为一个临时存储器使用，先保存bx的值
	push ax			;保存低位
	mov ax, dx		;把高位放在低位中
	mov dx, 0		;把高位置0
	div cx			;执行H/N，高位相除的余数保存在dx中
	mov bx, ax		;把商保存在bx寄存器中
	pop ax			;执行rem(H/N)*2^16+L
	div cx			;执行[rem(H/N)*2^16+L]/N，商保存在ax中
	mov cx, dx		;用cx寄存器保存余数
	mov dx, bx		;把bx的值复制到dx，即执行int(H/N)*2^16
						;由于[rem(H/N)*2^16+L]/N已保存于ax中，
						;即同时完成+运算
	pop bx			;恢复bx的值
	divdw_return:
	ret
divdw endp
_Deal proc hDlg
        mov rowNum,1
        mov listCount , 0
        invoke ReadFile,hFileA,addr bufferFileA,bufferSizeA,addr byteCountA,0
        invoke ReadFile,hFileB,addr bufferFileB,bufferSizeB,addr byteCountB,0
       
        mov cx , byteCountA
        .if eax == 0
            invoke MessageBox,NULL,addr szReadError,addr szMBCap,MB_OK
            ret
        .elseif cx == byteCountB
             mov eax ,0
             push cx
            .while TRUE
                mov cl,bufferFileA[eax] 
                .if (cl==bufferFileB[eax])
                    .if cl == 0
                            .break
                    .endif
                    .if cl == 10
                         push ax
                        mov ax,rowNum
                        inc ax
                        mov rowNum,ax
                        pop ax 
                    .endif
                    inc eax
                .else
                    push eax
                    mov eax ,0
          
                    mov ax,listCount
                    push bx
                    mov bx,rowNum
                    mov  rowList[eax*2],bx
                    pop bx
    
                    pop eax
                    .while cl != 10
                        mov cl,bufferFileA[eax] 
                        .if cl== 0
                            .break
                        .endif
                        inc eax
                    .endw
                    push ax
                    mov ax,listCount
                    inc ax
                    mov listCount,ax
                    pop ax
                    push ax
                    mov ax,rowNum
                    inc ax
                    mov rowNum,ax
                    pop ax
                    .if bufferFileA[eax]== 0
                            .break
                    .endif
                .endif
            .endw
            pop cx
        .else
            invoke MessageBox,hDlg,addr szNotEqual,addr szMBCap,MB_OK
            ret
        .endif
        push eax
        push si
        push cx
        mov eax ,0
        mov ax,listCount
        mov  rowList[eax*2],0
        pop eax
        mov eax,0
        mov cx,rowList[eax*2]
        mov esi,offset outputString
    .while cx != 0
            push eax
            mov ax,cx
	        mov cx, 0	;把0先压入栈底
	        push cx
            mov dx,0

    rem:	;求余，把对应的数字转换成ASCII码
            
	        mov cx, 10	;设置除数
	        call divdw	;执行安全的除法
	        add cx, 30H	;把余数转换成ASCII码
	        push cx		;把对应的ASCII码压入栈中
	        or ax, dx	;判断商是否为0
	        mov cx, ax
	        jcxz copy	;商为0，表示除完
	        jmp rem		;否则，继续相除
		
copy:	;把栈中的数据复制到string中
	    pop cx		;ASCII码出栈
	    jcxz dtoc_return	;若0出栈，则退出复制
         mov [esi], cl;把字符保存到string中
	    inc si		;指向下一个写入位置
	    jmp copy	;若0没出栈，则继续出栈复制数据
		
dtoc_return:;恢复寄存器内容，并退出子程序
        push cx
        mov cl,point
        mov [esi], cl;把字符保存到string中
        pop cx
        inc si		;指向下一个写入位置
        pop eax
        inc eax
	    mov cx,rowList[eax*2]
    .endw
        inc si
        mov cl,0
        mov [esi],cl
        pop cx
	    pop si
    .if listCount ==0
    invoke MessageBox,NULL,addr szEqual,addr szMBCap,MB_OK
    .elseif
    invoke MessageBox,NULL,addr outputString,addr szMBCap,MB_OK
    .endif
    mov hFileA,0
     mov hFileB,0
    ret
     
_Deal endp
_Islegal proc hDlg
    invoke CreateFile,addr szPathA,GENERIC_READ, FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
    .if eax == INVALID_HANDLE_VALUE
        invoke MessageBox,NULL,addr szOpenError,addr szMBCap,MB_OK
         ret

    .else 
        mov hFileA,eax
        invoke CreateFile,addr szPathB,GENERIC_READ, FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
        .if eax == INVALID_HANDLE_VALUE
            invoke MessageBox,NULL,addr szOpenError,addr szMBCap,MB_OK
            ret
        .else 
            mov hFileB,eax
            invoke _Deal,hDlg
            ret
        .endif
    .endif
    ret
   
_Islegal endp
_ProcCaption proc hDlg,uMsg,wParam,lParam
    .if uMsg == WM_INITDIALOG
        invoke SetDlgItemText,hDlg,IDC_CaptionA,NULL
        invoke SetDlgItemText,hDlg,IDC_CaptionB,NULL
    .elseif uMsg == WM_COMMAND
        mov eax,wParam
        movzx eax,ax
        .if eax == IDCANCEL
            invoke SetDlgItemText,hDlg,IDC_CaptionA,NULL
            invoke SetDlgItemText,hDlg,IDC_CaptionB,NULL
        .elseif eax == IDOK
            invoke GetDlgItemText,hDlg,IDC_CaptionA,addr szPathA,sizeof szPathA
            invoke GetDlgItemText,hDlg,IDC_CaptionB,addr szPathB,sizeof szPathB
            invoke _Islegal,hDlg

        .endif
    .elseif uMsg == WM_CLOSE
        invoke EndDialog,hDlg,NULL
    .else 
        mov eax ,FALSE
        ret
    .endif
    mov eax ,TRUE
    ret
_ProcCaption endp

start:
    invoke GetModuleHandle,NULL
    mov hInstance,eax
    invoke DialogBoxParam,hInstance,IDD_Caption,NULL,_ProcCaption,NULL
    invoke ExitProcess,NULL
end start

