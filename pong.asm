;---------------------------------------------------------------
; PONG for Altair front panel.
; May 2014, Mike Douglas
;
; Left player quickly toggles A15 to hit the "ball." Right
; player toggles A8. Score is kept in memory locations
; 80h and 81h (left and right). Score is missed balls, so
; the lower number wins.
;---------------------------------------------------------------
; Parameters:
; SPEED determines how fast the ball moves. Higher values
; move faster. Speed can easily be patched at address 1.
;
; HITMSK, HITEDG determines how easy it is to hit the ball.
; These are best changed by re-assembling the program.
; Frankly, even the medium setting is too easy. Probably
; best to stick with "hard" and change difficulty by
; adjusting SPEED.
;					(HITEDGL)
; DEMO mode can be set by patching 35h and 65h to zero
; and raising A15 and A8.	(HITEDGR)

SPEED		equ     0eh         ;higher value is faster
HITMSKR		equ     01h         ;01h=hard, 03h=med, 07h=easy
HITEDGR		equ     02h         ;02h=hard, 04h=med, 08h=easy
                                ;00h=demo with A15,A8 up
HITMSKL		equ     10h         ;10h=hard, 18h=med, 1ch=easy
HITEDGL		equ     08h         ;08h=hard, 04h=med, 02h=easy
                                ;00h=demo with A15,A8 up

;----------------------------------------------------------------
; Initialize
;----------------------------------------------------------------
		org	0

		lxi	b,SPEED		;BC=adder for speed
		lxi	sp,stack	;init stack pointer
		lxi	h,0		;zero the score
		shld	scoreL
		lxi	d,8000h		;D=ball bit, E=switch status
		jmp	rLoop		;begin moving right

;------------------------------------------------------------------
; ledOut - Write D to LEDs A15-A8.
; Loop accessing the address in DE which causes the proper LED
; to light on the address lights. This routine is placed low
; in memory so that address light A7-A5 remain off to make
; A15-A8 look better.
;------------------------------------------------------------------
ledOut:		lxi	h,0		;HL=16 bit counter
ledLoop:	ldax	d		;display bit pattern on
		ldax	d		;...upper 8 address lights
		ldax	d
		ldax	d
		dad	b		;increment display counter
		jnc	ledLoop
		ret
            
;----------------------------------------------------------------
; Moving Right
;----------------------------------------------------------------
rLoop:		call	ledOut		;output to LEDs A15-A8 from D

	; Record the current right paddle state (A8) in the bit position
	; in E corresponding to the present ball position.
            
		in	0ffh		;A=front panel switches
		ani	01h		;get A8 alone
		jz	chkRt		;switch not up, bit already zero
		mov	a,d		;set bit in E corresponding to...
		ora	e		; the current ball position
		ani	1fh		;keep b7-b5 zero
		mov	e,a
            
	; See if at the right edge. If so, see if A8 "paddle" has a hit
            
chkRt:		mov	a,d		;is ball at right edge?
		ani	1
		jz	moveRt		;no, continue moving right
		mov	a,e		;switch state for each ball position
		ani	HITEDGR		;test edge for switch too early
		jnz	missRt		;hit too early
		mov	a,e		;test for hit
		ani	HITMSKR
		jnz	moveLfR		;have a hit, switch direction
            
	; missRt - right player missed the ball. Increment count
            
missRt:		lxi	h,scoreR	;increment right misses
		inr	m
            
	; moveRt - Move the ball right again.
            
moveRtR:	mvi	e,0		;reset switch state
moveRt:		mov	a,d		;move right again
		rrc
		mov	d,a
		jmp	rLoop

;----------------------------------------------------------------
; Moving left
;----------------------------------------------------------------
lLoop:		call	ledOut		;output to LEDs A15-A8 from D

	; Record the current left paddle state (A15) in the bit position
	; in E corresponding to the present ball position.
            
		in	0ffh		;A=front panel switches
		ani	80h		;get A15 alone
		jz	chkLft		;switch not up, bit already zero
		mov	a,d		;A=ball position
		rrc			;move b7..b3 to b4..b0
		rrc			; so LEDs A7-A5 stay off
		rrc
		ora	e		;form switch state in E
		ani	1fh		;keep b7-b5 zero
		mov	e,a
  
	; See if at the left edge. If so, see if A15 "paddle" has a hit
            
chkLft:		mov	a,d		;is ball at left edge?
		ani	80h
		jz	moveLf		;no, continue moving left
		mov	a,e		;switch state for each ball posistion
		ani	HITEDGL		;test edge for switch too early
		jn	missLf		;hit too early
		mov	a,e		;test for hit
		ani	HITMSKL
		jnz	moveRtR		;have a hit, switch direction
            
	; missLf - left player missed the ball. Increment count
        
missLf:		lxi	h,scoreL	;increment left misses
		inr	m

	; moveLf - Move the ball left again.
        
moveLfR:	mvi	e,0		;reset switch state
moveLf:		mov	a,d		;move right again
		rlc
		mov	d,a
		jmp	lLoop
            
;------------------------------------------------------------------
; Data Storage
;------------------------------------------------------------------
		ds	2		;stack space
stack		equ	$

		org	80h		;put at 80h and 81h
scoreL		ds	1		;score for left paddle
scoreR		ds	1		;score for right paddle
		end
