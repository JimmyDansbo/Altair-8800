;-----------------------------------------------------------------------------
; KITT for Altair front panel.
; Jan 2024, Jimmy Dansbo
;
; Simulates KITT's front lights from Knight Rider on the Altair front panel
; The speed of the running lights can be set by the top 8 toggles (A15-A8)
;-----------------------------------------------------------------------------
		org	0000h
		lxi	b, 0000h	; Zero out BC
		lxi	sp, stack
		lxi	d, 0100h
		jmp	left

;-----------------------------------------------------------------------------
; ledout - Write D to LEDs A15-A8.
; Loop accessing the address in DE which causes the proper LED
; to light on the address lights. This routine is placed low
; in memory so that address light A7-A5 remain off to make
; A15-A8 look better.
;-----------------------------------------------------------------------------
ledout:		lxi	h, 0000h	; HL=16 bit counter
ledloop:	ldax	d		; Display bit pattern on upper
		ldax	d		; 8 address lights
		ldax	d
		ldax	d
		dad	b		; increment display counter
		jnc	ledloop
		ret

;-----------------------------------------------------------------------------
; getspeed - Get speed indicator from top 8 toggles (A15-A8).
; Store the speec in C - higher number = faster
; If all toggles are set to 0, speed is set to 1
;-----------------------------------------------------------------------------
getspeed:
		in	0ffh		; A=front panel switches
		mov	c,a		; C=front panel switches
		cpi	00h		; If not 0
		rnz			; return
		inr	a		; A was 0, now it is 1
		mov	c,a
		ret

;-----------------------------------------------------------------------------
left:		call	getspeed
		call	ledout
		mov	a,d	
		cpi	07h		; If A<7, carry bit is set
		ral
		mov	d,a		; Store new bit pattern
		cpi	80h		; Only 1 bit at the far left
		jnz	left		; If not, continue left
right:		call	getspeed
		call	ledout
		mov	a,d
		cpi	80h		; If bit pattern is less than 80h
		jc	notop3
		cmc			; Set Carry
		rar			; Rotate right with carry
		cpi	0f0h		; If the new value is not 0f0h
		jnz	setbit		; We can use it
		ani	70h		; else reset top bit (b7)
		jmp	setbit
notop3:		cmc			; Clear Carry
		rar			; Rotate right with carry
setbit:		mov	d,a		; Store new bit pattern
		cpi	01h		; only 1 bit at the far right
		jnz	right		; If not continue right
		jmp	left		; Else start going left
		ds	2
stack		equ	$
