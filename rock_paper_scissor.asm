
section .data
    clear db 27,"[H",27,"[2J"               ; Clear the screen (Works on linux but not sure about other OS's)
    clear_len equ $ - clear
    req1 db "First player: ",0              ; First player input
    req1_len equ $ - req1
    req2 db "Second player: ",0             ; Second player input
    req2_len equ $ - req2
    equal db "This game is equal!",10       ; Equal result
    equal_len equ $ - equal
    one_win db "Player one won!",10         ; Player one won
    one_win_len equ $ - one_win
    two_win db "Player two won!",10         ; Player two won
    two_win_len equ $ - two_win
    rock db "rock",10                       ; Rock
    rock_len equ $ - rock
    scissor db "scissor",10                 ; Scissor
    scissor_len equ $ - scissor
    paper db "paper",10                     ; Paper
    paper_len equ $ - paper
    error db "*** Wrong input -- Chose between rock, paper, scissor ***",10
    error_len equ $ - error


section .bss
    ans1 resb 10    ; First answer
    ans2 resb 10    ; Second answer
    nothing resb 20

section .text
    global _start


_start:            

    ; ========================= Clear screen =========================

    call .clear



    ; ========================= Get input ========================

    ; Person 1
    push req1      
    push req1_len
    call .print     ; Prints the request
    push ans1        
    push 10
    call .get       ; Gets input

    cmp byte [ans1], 81     ; Check Exit
    je .exit
    cmp byte [ans1], 113
    je .exit

    ; Person 2
    push req2     
    push req2_len
    call .print     ; Prints the request
    push ans2
    push 10
    call .get       ; Gets input

    cmp byte [ans2], 81     ; Check Exit
    je .exit
    cmp byte [ans2], 113
    je .exit



    ; ========================== Who won ===========================

    push ans1           ; Check if first input is rock
    call .rock_cmp
    cmp rax, 0
    je .rock

    call .scissor_cmp   ; Check if first input is scissor
    cmp rax, 0
    je .scissor

    call .paper_cmp     ; Check if first input is paper
    cmp rax, 0
    je .paper



    ; ========================== Invalid input ==============================

    push error  
    push error_len
    call .print
    push nothing    
    push 20
    call .get
    jmp _start
    
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------



; ========================== Rock ==========================

.rock:
    push ans2           ; Check if second input is rock
    call .rock_cmp
    cmp rax, 0
    je .equal_res

    call .scissor_cmp   ; Check if second input is scissor
    cmp rax, 0
    je .first_res

    call .paper_cmp     ; Check if second input is paper
    cmp rax, 0
    je .second_res

    push error          ; In case of invalid input
    push error_len
    call .print
    push nothing
    push 20
    call .get
    jmp _start



; ========================== Scissor ==========================

.scissor:
    push ans2           ; Check if second input is rock
    call .rock_cmp
    cmp rax, 0
    je .second_res

    call .scissor_cmp   ; Check if second input is scissor
    cmp rax, 0
    je .equal_res

    call .paper_cmp     ; Check if second input is paper
    cmp rax, 0
    je .first_res

    push error          ; In case of invalid input
    push error_len
    call .print
    push nothing
    push 20
    call .get
    jmp _start



; ========================== Paper ==========================

.paper:
    push ans2           ; Check if second input is rock
    call .rock_cmp
    cmp rax, 0
    je .first_res

    call .scissor_cmp   ; Check if second input is scissor
    cmp rax, 0
    je .second_res

    call .paper_cmp     ; Check if second input is paper
    cmp rax, 0
    je .equal_res

    push error          ; In case of invalid input
    push error_len
    call .get
    push nothing
    push 20
    call .print
    jmp _start



; ========================== Rock cmp ===============================

.rock_cmp:
    push rbp
    mov rbp, rsp
    mov rsi, rock           ; Rock template
    mov rdi, [rbp + 0x10]   ; User's input
    xor rdx, rdx            ; Index
.L1:
    mov al, [rsi + rdx]     ; Char from string 1 at offset rdx
    mov bl, [rdi + rdx]     ; Char from string 2 at offset rdx
    inc rdx
    cmp al, bl
    jne .not_equal          ; Not equal
    cmp al, 10
    je .equal               ; Equal
    jmp .L1                 ; Continue

    

; ========================== Scissor cmp ==========================

.scissor_cmp:
    push rbp
    mov rbp, rsp
    mov rsi, scissor        ; Scissor template
    mov rdi, [rbp + 0x10]   ; User's input
    xor rdx, rdx            ; Index
.L2:
    mov al, [rsi + rdx]     ; Char from string 1 at offset rdx
    mov bl, [rdi + rdx]     ; Char from string 2 at offset rdx
    inc rdx
    cmp al, bl
    jne .not_equal          ; Not equal
    cmp al, 10
    je .equal               ; Equal
    jmp .L2                 ; Continue



; ========================== Paper cmp ==========================

.paper_cmp:
    push rbp
    mov rbp, rsp
    mov rsi, paper          ; Paper template
    mov rdi, [rbp + 0x10]   ; User's input
    xor rdx, rdx            ; Index
.L3:
    mov al, [rsi + rdx]     ; Char from string 1 at offset rdx
    mov bl, [rdi + rdx]     ; Char from string 2 at offset rdx
    inc rdx
    cmp al, bl
    jne .not_equal          ; Not equal
    cmp al, 10
    je .equal               ; Equal
    jmp .L3                 ; Continue



; ========================== Cases ==========================

.equal:             ; Strings equal ( ret 0 )
    xor rax, rax
    pop rbp
    ret

.not_equal:         ; Strings not equal ( ret 1 )
    mov rax, 1
    pop rbp
    ret



; ========================== Results ==========================

.equal_res:             ; Equal results 
    push equal
    push equal_len
    call .print  
    pop rbx
    pop rbx
    push nothing
    push 20
    call .get     
    jmp _start

.first_res:             ; First player win
    push one_win
    push one_win_len
    call .print    
    pop rbx
    pop rbx
    push nothing        
    push 20
    call .get       
    jmp _start

.second_res:            ; Second player win
    push two_win
    push two_win_len
    call .print       
    pop rbx
    pop rbx
    push nothing
    push 20
    call .get        
    jmp _start         



; ========================== General ==========================

.get:           ; Get input
    push rbp
    mov rbp, rsp
    mov rax, 0
    mov rdi, 0
    mov rsi, [rbp + 0x18]   ; rsi = string
    mov rdx, [rbp + 0x10]   ; rdx = length
    syscall
    pop rbp
    ret

.print:         ; Print string
    push rbp
    mov rbp, rsp
    mov rax, 1
    mov rdi, 1
    mov rsi, [rbp + 0x18]   ; rsi = string
    mov rdx, [rbp + 0x10]   ; rdx = length
    syscall
    pop rbp
    ret

.exit:          ; Exit program
    call .clear
    mov rax, 60
    mov rdi, 1
    syscall

.clear:
    push clear
    push clear_len
    call .print
    pop rbx
    pop rbx
    ret

