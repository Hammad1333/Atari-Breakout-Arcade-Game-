[org 0x0100]

jmp start

; ======================== DATA SECTION ========================

title:      db ' Atari Breakout Arcade Game  ', 0
menu1:      db '1. PLAY', 0
menu2:      db '2. INSTRUCTIONS', 0
menu3:      db '3. QUIT', 0
prompt:     db 'Select an option (1-3) : ', 0

instructions: db 'INSTRUCTIONS :', 0
inst1:      db 'Use LEFT and RIGHT Arrow Keys To Move Paddle.', 0
inst2:      db 'Press SPACE To Launch Ball.', 0
inst3:      db 'Break All Bricks To Win The Game.', 0
inst4:      db 'Do Not Let The Ball Fall Down.', 0
inst5:      db 'Press ESC To Exit Game.', 0
inst6:      db '', 0
inst7:      db 'BRICK SCORING :', 0
inst8:      db 'Purple Brick: 4 hits = 15 points.', 0
inst9:      db 'Red Brick: 3 hits = 10 points.', 0
inst10:     db 'Yellow Brick: 2 hits = 5 points.', 0
inst11:     db 'Blue Brick: 1 hit = 2 points.', 0
inst12:     db 'Press any key to return to menu...', 0

gameTitle:  db 'Press SPACE To Start.', 0
scoreText:  db 'Score : ', 0
healthText: db 'Lives : ', 0
gameOverMsg: db 'GAME OVER!', 0
winMsg:      db 'YOU WIN! ALL BRICKS DESTROYED!', 0

; Game variables

paddlex:    dw 38
paddley:    dw 22
paddlelen:  dw 8
ballx:      dw 42
bally:      dw 21
balldx:     dw 1
balldy:     dw -1
ballactive: dw 0
score:      dw 0
lives:      dw 3
delaycounter: db 0
oldisr:     dd 0

bricks:     times 280 dw 0
brickcount: dw 40

; ======================== KEYBOARD ISR ========================

kbisr:      
	push ax
	push bx
	push cx
	
	in al, 0x60
	cmp al, 0x4B
	je isrleft
	cmp al, 0x4D
	je isrright
	jmp isrexit
	
isrleft:   
	cmp word [paddlex], 2
	jle isrexit
	cmp word [ballactive], 0
	jne skipballleft
	call clearBall
	dec word [ballx]
	call drawBall
skipballleft:
	call clearPaddle
	dec word [paddlex]
	call drawPaddle
	jmp isrexit
	
isrright:  
	mov ax, [paddlex]
	add ax, [paddlelen]
	cmp ax, 77
	jge isrexit
	cmp word [ballactive], 0
	jne skipballright
	call clearBall
	inc word [ballx]
	call drawBall
skipballright:
	call clearPaddle
	inc word [paddlex]
	call drawPaddle
	
isrexit:   
	mov al, 0x20
	out 0x20, al
	pop cx
	pop bx
	pop ax
	jmp far [cs:oldisr]

; ======================== SOUND ========================

beep:
	push ax
	push cx
	in al, 0x61
	or al, 3
	out 0x61, al
	mov cx, 4000
beeploop:
	loop beeploop
	in al, 0x61
	and al, 252
	out 0x61, al
	pop cx
	pop ax
	ret

; ======================== CLEAR SCREEN ========================

clrscr:
	push es
	push ax
	push di
	push cx
	mov ax,0xB800
	mov es,ax
	xor di,di
	mov cx,2000
	mov ax,0x0720
	cld
	rep stosw
	pop cx
	pop di
	pop ax
	pop es
	ret

; ======================== PRINT STRING ========================

printstr:   
	push bp
	mov bp, sp
	push es
	push ax
	push cx
	push si
	push di
	push ds
	pop es
	mov di, [bp+4]
	mov cx, 0xffff
	xor al, al
	repne scasb
	mov ax, 0xffff
	sub ax, cx
	dec ax
	jz exitprint
	mov cx, ax
	mov ax, 0xb800
	mov es, ax
	mov al, 80
	mul byte [bp+8]
	add ax, [bp+10]
	shl ax, 1
	mov di, ax
	mov si, [bp+4]
	mov ah, [bp+6]
nextchar:   
	lodsb
	stosw
	loop nextchar
exitprint: 
	pop di
	pop si
	pop cx
	pop ax
	pop es
	pop bp
	ret 8

; ======================== PRINT NUMBER ========================

printnum:   
	push bp
	mov bp, sp
	push es
	push ax
	push bx
	push cx
	push dx
	push di
	mov ax, 0xb800
	mov es, ax
	mov al, 80
	mul byte [bp+8]
	add ax, [bp+10]
	shl ax, 1
	mov di, ax
	mov ax, [bp+4]
	mov bx, 10
	mov cx, 0
digitloop: 
	mov dx, 0
	div bx
	add dl, 0x30
	push dx
	inc cx
	cmp ax, 0
	jnz digitloop
printdigit:
	pop dx
	mov dh, [bp+6]
	mov [es:di], dx
	add di, 2
	loop printdigit
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	pop bp
	ret 8

; ======================== DRAW BOUNDARY ========================

drawBoundary:
	push es
	push ax
	push cx
	push di
	mov ax, 0xb800
	mov es, ax
	mov di, 320
	mov cx, 80
	mov ax, 0x0FCD
topBorder:  
	mov [es:di], ax
	add di, 2
	loop topBorder
	mov di, 3840
	mov cx, 80
bottomBorder:
	mov [es:di], ax
	add di, 2
	loop bottomBorder
	mov di, 480
	mov cx, 21
leftBorder: 
	mov word [es:di], 0x0FBA
	add di, 160
	loop leftBorder
	mov di, 638
	mov cx, 21
rightBorder:
	mov word [es:di], 0x0FBA
	add di, 160
	loop rightBorder
	mov word [es:320], 0x0FC9
	mov word [es:478], 0x0FBB
	mov word [es:3840], 0x0FC8
	mov word [es:3998], 0x0FBC
	pop di
	pop cx
	pop ax
	pop es
	ret

; ======================== INITIALIZE BRICKS ========================

initBricks: 
	push ax
	push bx
	push cx
	push si
	push dx
	mov si, bricks
	mov cx, 0
	mov bx, 0
purplelayer:
	cmp bx, 10
	je redlayerstart
	mov ax, bx
	mov dx, 7
	mul dx
	add ax, 3
	mov [si], ax
	mov word [si+2], 4
	mov word [si+4], 6
	mov word [si+6], 0x05
	mov word [si+8], 0x05
	mov word [si+10], 4
	mov word [si+12], 1
	add si, 14
	inc bx
	inc cx
	jmp purplelayer
redlayerstart:
	mov bx, 0
redlayer:  
	cmp bx, 10
	je yellowlayerstart
	mov ax, bx
	mov dx, 7
	mul dx
	add ax, 3
	mov [si], ax
	mov word [si+2], 6
	mov word [si+4], 6
	mov word [si+6], 0x0C
	mov word [si+8], 0x0C
	mov word [si+10], 3
	mov word [si+12], 1
	add si, 14
	inc bx
	inc cx
	jmp redlayer
yellowlayerstart:
	mov bx, 0
yellowlayer:
	cmp bx, 10
	je bluelayerstart
	mov ax, bx
	mov dx, 7
	mul dx
	add ax, 3
	mov [si], ax
	mov word [si+2], 8
	mov word [si+4], 6
	mov word [si+6], 0x0E
	mov word [si+8], 0x0E
	mov word [si+10], 2
	mov word [si+12], 1
	add si, 14
	inc bx
	inc cx
	jmp yellowlayer
bluelayerstart:
	mov bx, 0
bluelayer: 
	cmp bx, 10
	je initdone
	mov ax, bx
	mov dx, 7
	mul dx
	add ax, 3
	mov [si], ax
	mov word [si+2], 10
	mov word [si+4], 6
	mov word [si+6], 0x09
	mov word [si+8], 0x09
	mov word [si+10], 1
	mov word [si+12], 1
	add si, 14
	inc bx
	inc cx
	jmp bluelayer
initdone:  
	mov [brickcount], cx
	pop dx
	pop si
	pop cx
	pop bx
	pop ax
	ret

; ======================== CLEAR SINGLE BRICK ========================

clearBrick: 
	push bp
	mov bp, sp
	push es
	push ax
	push bx
	push cx
	push di
	mov ax, 0xb800
	mov es, ax
	mov si, [bp+4]
	mov ax, [si+2]
	mov bl, 80
	mul bl
	add ax, [si]
	shl ax, 1
	mov di, ax
	mov cx, [si+4]
	mov ax, 0x0720
clearbrickloop:
	mov [es:di], ax
	add di, 2
	loop clearbrickloop
	pop di
	pop cx
	pop bx
	pop ax
	pop es
	pop bp
	ret 2

; ======================== DRAW BRICKS ========================

drawBricks: 
	push es
	push ax
	push bx
	push cx
	push dx
	push di
	push si
	mov ax, 0xb800
	mov es, ax
	mov si, bricks
	mov cx, 40
drawloop:  
	push cx
	cmp word [si+12], 0
	je skipbrick
	mov ax, [si+2]
	mov bl, 80
	mul bl
	add ax, [si]
	shl ax, 1
	mov di, ax
	mov ah, [si+8]
	mov cx, [si+4]
drawbrick:
	mov al, 0xDB
	mov [es:di], ax
	add di, 2
	loop drawbrick
skipbrick: 
	add si, 14
	pop cx
	loop drawloop
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	ret

; ======================== DRAW PADDLE ========================

drawPaddle: 
	push es
	push ax
	push bx
	push cx
	push di
	mov ax, 0xb800
	mov es, ax
	mov ax, [paddley]
	mov bl, 80
	mul bl
	add ax, [paddlex]
	shl ax, 1
	mov di, ax
	mov cx, [paddlelen]
	mov ax, 0x0BDB
drawpaddleloop:
	mov [es:di], ax
	add di, 2
	loop drawpaddleloop
	pop di
	pop cx
	pop bx
	pop ax
	pop es
	ret

; ======================== CLEAR PADDLE ========================

clearPaddle:
	push es
	push ax
	push bx
	push cx
	push di
	mov ax, 0xb800
	mov es, ax
	mov ax, [paddley]
	mov bl, 80
	mul bl
	add ax, [paddlex]
	shl ax, 1
	mov di, ax
	mov cx, [paddlelen]
	mov ax, 0x0720
clearpaddleloop:
	mov [es:di], ax
	add di, 2
	loop clearpaddleloop
	pop di
	pop cx
	pop bx
	pop ax
	pop es
	ret

; ======================== DRAW/CLEAR BALL ========================

drawBall:   
	push es
	push ax
	push bx
	push di
	mov ax, 0xb800
	mov es, ax
	mov ax, [bally]
	mov bl, 80
	mul bl
	add ax, [ballx]
	shl ax, 1
	mov di, ax
	mov word [es:di], 0x0F4F
	pop di
	pop bx
	pop ax
	pop es
	ret

clearBall:  
	push es
	push ax
	push bx
	push di
	mov ax, 0xb800
	mov es, ax
	mov ax, [bally]
	mov bl, 80
	mul bl
	add ax, [ballx]
	shl ax, 1
	mov di, ax
	mov word [es:di], 0x0720
	pop di
	pop bx
	pop ax
	pop es
	ret

; ======================== MOVE BALL ========================

moveBall:   
	push ax
	push bx
	call clearBall
	mov ax, [ballx]
	add ax, [balldx]
	cmp ax, 2
	jle bouncex
	cmp ax, 77
	jge bouncex
	jmp updatex
bouncex:   
	neg word [balldx]
	mov ax, [ballx]
	add ax, [balldx]
updatex:   
	mov [ballx], ax
	mov ax, [bally]
	add ax, [balldy]
	cmp ax, 3
	jle bouncey
	cmp ax, 23
	jge balllost
	jmp updatey
bouncey:   
	neg word [balldy]
	mov ax, [bally]
	add ax, [balldy]
	jmp updatey
balllost:  
	call beep
	dec word [lives]
	mov word [ballactive], 0
	mov ax, [paddlex]
	add ax, 4
	mov [ballx], ax
	mov word [bally], 21
	jmp movedone
updatey:   
	mov [bally], ax
	call drawBall
movedone:  
	pop bx
	pop ax
	ret

; ======================== CHECK PADDLE COLLISION ========================

checkPaddleCollision:
	push ax
	push bx
	mov ax, [bally]
	cmp ax, 21
	jne nopaddlehit
	mov ax, [ballx]
	mov bx, [paddlex]
	cmp ax, bx
	jl nopaddlehit
	mov bx, [paddlex]
	add bx, [paddlelen]
	cmp ax, bx
	jge nopaddlehit
	neg word [balldy]
	call beep
nopaddlehit:
	pop bx
	pop ax
	ret

; ======================== CHECK BRICK COLLISION ========================

checkBrickCollision:
	push ax
	push bx
	push cx
	push dx
	push si
	mov si, bricks
	mov cx, 40
checkbrickloop:
	cmp word [si+12], 0
	je near nextbrick
	
	mov ax, [bally]
	mov bx, [si+2]       
	cmp ax, bx
	jl near nextbrick   
	mov bx, [si+2]
	inc bx             
	cmp ax, bx
	jg near nextbrick   
	
checkxcollision:
	mov ax, [ballx]
	mov bx, [si]     
	cmp ax, bx
	jl near nextbrick  
	mov bx, [si]
	add bx, [si+4]       
	cmp ax, bx
	jge near nextbrick   
	
	push si
	call clearBrick
	call beep
	dec word [si+10]
	cmp word [si+10], 0
	je brickdestroyed
	cmp word [si+10], 3
	jne checktwohits
	mov word [si+8], 0x0C
	neg word [balldy]
	jmp checkdone
checktwohits:
	cmp word [si+10], 2
	jne checkonehit
	mov word [si+8], 0x0E
	neg word [balldy]
	jmp checkdone
checkonehit:
	cmp word [si+10], 1
	jne nextbrick
	mov word [si+8], 0x09
	neg word [balldy]
	jmp checkdone
brickdestroyed:
	mov word [si+12], 0
	mov bx, [si+6]
	cmp bx, 0x05
	je waspurple
	cmp bx, 0x0C
	je wasred
	cmp bx, 0x0E
	je wasyellow
	add word [score], 2
	jmp finishdestroy
waspurple:
	add word [score], 15
	jmp finishdestroy
wasred:
	add word [score], 10
	jmp finishdestroy
wasyellow:
	add word [score], 5
finishdestroy:
	dec word [brickcount]
	neg word [balldy]
	jmp checkdone
nextbrick:
	add si, 14
	dec cx
	jnz checkbrickloop
checkdone:
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

; ======================== DRAW UI ========================

drawUI:     
	push ax
	push es
	push di
	push cx
	mov ax, 2
	push ax
	mov ax, 0
	push ax
	mov ax, 0x0F
	push ax
	mov ax, scoreText
	push ax
	call printstr
	mov ax, 9
	push ax
	mov ax, 0
	push ax
	mov ax, 0x0F
	push ax
	mov ax, [score]
	push ax
	call printnum
	mov ax, 69
	push ax
	mov ax, 0
	push ax
	mov ax, 0x0F
	push ax
	mov ax, healthText
	push ax
	call printstr
	mov ax, 0xb800
	mov es, ax
	mov di, 154
	mov cx, 6
	mov ax, 0x0720
clearhearts:
	mov [es:di], ax
	add di, 2
	loop clearhearts
	mov di, 154
	mov cx, [lives]
	cmp cx, 0
	jle heartsdone
	mov ax, 0x0C03
drawhearts:
	mov [es:di], ax
	add di, 2
	dec cx
	jnz drawhearts
heartsdone:
	pop cx
	pop di
	pop es
	pop ax
	ret

; ======================== PLAY GAME ========================

playGame:   
	push bp
	mov bp, sp
	call clrscr
	mov word [score], 0
	mov word [lives], 3
	mov word [paddlex], 38
	mov word [ballx], 42
	mov word [bally], 21
	mov word [ballactive], 0
	mov byte [delaycounter], 0
	
	xor ax, ax
	mov es, ax
	mov ax, [es:9*4]
	mov [oldisr], ax
	mov ax, [es:9*4+2]
	mov [oldisr+2], ax
	
	cli
	mov word [es:9*4], kbisr
	mov [es:9*4+2], cs
	sti
	
	call initBricks
	call drawBoundary
	call drawBricks
	call drawPaddle
	call drawBall
	call drawUI
	mov ax, 30
	push ax
	mov ax, 1
	push ax
	mov ax, 0x0E
	push ax
	mov ax, gameTitle
	push ax
	call printstr
gameLoop:   
	call drawBricks
	call drawUI
	call drawBall
	cmp word [lives], 0
	je near gameover
	cmp word [brickcount], 0
	je near gamewon
	cmp word [ballactive], 0
	je skipballmove
	inc byte [delaycounter]
	cmp byte [delaycounter], 10
	jl skipballmove
	mov byte [delaycounter], 0
	call moveBall
	call checkPaddleCollision
	call checkBrickCollision
skipballmove:
	mov cx, 0x8000
delayloop:  
	loop delayloop
	mov ah, 0x01
	int 0x16
	jz gameLoop
	mov ah, 0x00
	int 0x16
	cmp ah, 0x01
	je near exitgame
	cmp al, 32
	jne gameLoop
	cmp word [ballactive], 0
	jne gameLoop
	mov word [ballactive], 1
	jmp gameLoop
gameover:   
	xor ax, ax
	mov es, ax
	cli
	mov ax, [oldisr]
	mov [es:9*4], ax
	mov ax, [oldisr+2]
	mov [es:9*4+2], ax
	sti
	
	call clrscr
	mov ax, 35
	push ax
	mov ax, 10
	push ax
	mov ax, 0x0C
	push ax
	mov ax, gameOverMsg
	push ax
	call printstr
	mov ax, 35
	push ax
	mov ax, 13
	push ax
	mov ax, 0x0E
	push ax
	mov ax, scoreText
	push ax
	call printstr
	mov ax, 42
	push ax
	mov ax, 13
	push ax
	mov ax, 0x0A
	push ax
	mov ax, [score]
	push ax
	call printnum
	mov ah, 0
	int 0x16
	jmp exitgame
gamewon:    
	xor ax, ax
	mov es, ax
	cli
	mov ax, [oldisr]
	mov [es:9*4], ax
	mov ax, [oldisr+2]
	mov [es:9*4+2], ax
	sti
	
	call clrscr
	mov ax, 25
	push ax
	mov ax, 10
	push ax
	mov ax, 0x0A
	push ax
	mov ax, winMsg
	push ax
	call printstr
	mov ax, 35
	push ax
	mov ax, 13
	push ax
	mov ax, 0x0E
	push ax
	mov ax, scoreText
	push ax
	call printstr
	mov ax, 42
	push ax
	mov ax, 13
	push ax
	mov ax, 0x0A
	push ax
	mov ax, [score]
	push ax
	call printnum
	mov ah, 0
	int 0x16
exitgame:   
	pop bp
	ret

; ======================== SHOW INSTRUCTIONS ========================

showInstructions:
	push bp
	mov bp, sp
	call clrscr
	
	mov ax, 34
	push ax
	mov ax, 2
	push ax
	mov ax, 0x0E
	push ax
	mov ax, instructions
	push ax
	call printstr
	
	mov ax, 10
	push ax
	mov ax, 5
	push ax
	mov ax, 0x0F
	push ax
	mov ax, inst1
	push ax
	call printstr
	
	mov ax, 10
	push ax
	mov ax, 6
	push ax
	mov ax, 0x0F
	push ax
	mov ax, inst2
	push ax
	call printstr
	
	mov ax, 10
	push ax
	mov ax, 7
	push ax
	mov ax, 0x0F
	push ax
	mov ax, inst3
	push ax
	call printstr
	
	mov ax, 10
	push ax
	mov ax, 8
	push ax
	mov ax, 0x0F
	push ax
	mov ax, inst4
	push ax
	call printstr
	
	mov ax, 10
	push ax
	mov ax, 9
	push ax
	mov ax, 0x0F
	push ax
	mov ax, inst5
	push ax
	call printstr
	
	mov ax, 32
	push ax
	mov ax, 11
	push ax
	mov ax, 0x0E
	push ax
	mov ax, inst7
	push ax
	call printstr
	
	mov ax, 22
	push ax
	mov ax, 13
	push ax
	mov ax, 0x05
	push ax
	mov ax, inst8
	push ax
	call printstr
	
	mov ax, 23
	push ax
	mov ax, 14
	push ax
	mov ax, 0x0C
	push ax
	mov ax, inst9
	push ax
	call printstr
	
	mov ax, 22
	push ax
	mov ax, 15
	push ax
	mov ax, 0x0E
	push ax
	mov ax, inst10
	push ax
	call printstr
	
	mov ax, 24
	push ax
	mov ax, 16
	push ax
	mov ax, 0x09
	push ax
	mov ax, inst11
	push ax
	call printstr
	
	mov ax, 22
	push ax
	mov ax, 20
	push ax
	mov ax, 0x0A
	push ax
	mov ax, inst12
	push ax
	call printstr
	
	mov ah, 0
	int 0x16
	pop bp
	ret

; ======================== DISPLAY MENU ========================

displayMenu:
	push bp
	mov bp, sp
	call clrscr
	mov ax, 24
	push ax
	mov ax, 5
	push ax
	mov ax, 0x0E
	push ax
	mov ax, title
	push ax
	call printstr
	mov ax, 35
	push ax
	mov ax, 10
	push ax
	mov ax, 0x0F
	push ax
	mov ax, menu1
	push ax
	call printstr
	mov ax, 35
	push ax
	mov ax, 12
	push ax
	mov ax, 0x0F
	push ax
	mov ax, menu2
	push ax
	call printstr
	mov ax, 35
	push ax
	mov ax, 14
	push ax
	mov ax, 0x0F
	push ax
	mov ax, menu3
	push ax
	call printstr
	mov ax, 28
	push ax
	mov ax, 18
	push ax
	mov ax, 0x0A
	push ax
	mov ax, prompt
	push ax
	call printstr
	pop bp
	ret

; ======================== MAIN PROGRAM ========================

start:      
mainLoop:   
	call displayMenu
	mov ah, 0
	int 0x16
	cmp al, '1'
	je option1
	cmp al, '2'
	je option2
	cmp al, '3'
	je option3
	jmp mainLoop
option1:    
	call playGame
	jmp mainLoop
option2:    
	call showInstructions
	jmp mainLoop
option3:    
	call clrscr
	mov ax, 0x4c00
	int 0x21