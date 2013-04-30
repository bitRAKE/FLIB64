hHk rq 1 ; global CBTMessageBox hook handle


CBTMessageBox: ; hWnd,lpText,lpCaption,uType
    push rcx rdx r8 r9
    enter 32,0
    kernel32 call [GetCurrentThreadId]
    mov ecx,5 ; WH_CBT
    lea edx,CBTProc ; #32#
    xor r8,r8
    xchg r9,rax
    user32 call [SetWindowsHookEx]
    leave
    mov [hHk],rax ; doesn't matter if it fails, we need to continue
    pop r9 r8 rdx rcx
    user32 jmp [MessageBoxU]


CBTProc: ; nCode,hChild,lpCBTact
    enter .frame,0
    virtual at rbp-.frame
	    rq 4
	.4  rq 1
	.5  rq 1
	.6  rq 1
	.rParent RECT
	.rChild RECT
	.frame = NOT 15 AND ($-$$+15)
	    rb $$+.frame-$ ; stack alignment
    end virtual
    cmp ecx,5 ; HCBT_ACTIVATE
    jz .HCBT_ACTIVATE
    user32 call [CallNextHookEx],[hHk],rcx,rdx,r8
    xor eax,eax
    leave
    retn

.HCBT_ACTIVATE:
    mov [.hChild],rdx
    mov rcx,rdx
    lea edx,[.rChild] ; #32#
    user32 call [GetWindowRect]
    test eax,eax
    jz @F
    user32 call [GetParent],[.hChild]
    test eax,eax
    jz @F
    user32 call [GetWindowRect],rax,addr rParent
    test eax,eax
    jz @F
    mov r9d,[.rChild.right]
    mov eax,[.rChild.bottom]
    mov edx,[.rParent.right]
    mov r8d,[.rParent.bottom]
    sub r9d,[.rChild.left] ; width
    sub eax,[.rChild.top] ; height
    add edx,[.rParent.left]
    add r8d,[.rParent.top]
    sub edx,r9d
    sub r8d,eax
    sar edx,1 ; start.x
    sar r8d,1 ; start.x
    mov rcx,[.hChild]
    mov [.4],rax
    and [.5],0 ; FALSE
    user32 call [MoveWindow]
;
; any error results in unhooking and just presenting without centering
;
@@: user32 call [UnhookWindowsHookEx],[hHk]
    xor eax,eax
    leave
    retn


