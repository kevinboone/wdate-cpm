;------------------------------------------------------------------------
;  romwbw.asm 
;  See romwbw.inc for descriptions
;  Copyright (c)2023 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------

 	.Z80

	include conio.inc

	; ROMWBW stores a pointer to a magic number at 0xFFFE.
	RWBW_MAGIC_PTR	equ 0fffeH
	; And these are the two magic numbers:
	RWBW_MAGIC_1	equ 057H
	RWBW_MAGIC_2	equ 0A8H

	; Code for the 'Get RTC' API call
	RWBW_GRTC	equ 20H
	; Code for the 'Put RTC' API call
	RWBW_PRTC	equ 21H

	global rwbw_chk
	global rwbw_getrtc, rwbw_putrtc

;------------------------------------------------------------------------
; rwbw_chk
; Check whether we are running on a ROMWBW machine 
;------------------------------------------------------------------------
rwbw_chk:
	PUSH	HL
	LD	HL, (RWBW_MAGIC_PTR) 
	LD	A, (HL)
	CP	RWBW_MAGIC_1 
	JR	NZ, .notrwbw
	INC	HL
	LD	A, (HL)
	CP	RWBW_MAGIC_2 
	JR	NZ, .notrwbw
	INC	HL
	LD	A, (HL)
	POP	HL
	RET

.notrwbw:
	POP	HL
	LD	A, 0
	RET

;------------------------------------------------------------------------
; rwbw_invoke
;------------------------------------------------------------------------
rwbw_invoke:
	; We can also invoke ROMWBW using 'RST 8'. I'm not sure when to
	;   prefer one approach over the other
	CALL	0FFF0h
	RET

;------------------------------------------------------------------------
; .bcd2bin 
; A helper function for doing BCD->binary, on the 8-bit value in A.
; Other registers are preserved
;------------------------------------------------------------------------
.bcd2bin:
	PUSH	BC	
	LD	C,A
	AND	0F0H
	SRL	A
	LD	B,A
	SRL	A
	SRL	A
	ADD	A,B
	LD	B,A
	LD	A,C
	AND	0FH
	ADD	A,B
	POP	BC
	RET

;------------------------------------------------------------------------
; .bin2bcd
; A helper function for doing binary->BCD, on the 8-bit value in A.
; Other registers are preserved
;------------------------------------------------------------------------
.bin2bcd:
	PUSH	BC
	LD	B, 10
	LD	C, -1
div10:	INC	C
	SUB	B
	JR	NC, div10
	ADD	A, B
	LD	B, A
	LD	A, C
	ADD	A, A
	ADD	A, A
	ADD	A, A
	ADD	A, A
	OR	B
	POP	BC
	RET

;------------------------------------------------------------------------
; rwbw_putrtc
;------------------------------------------------------------------------
rwbw_putrtc:

	; First, let's check that we're actually on ROMWBW. The next 
	;  steps will cause a crash if we're not.
	LD 	A, -1 
        CALL	rwbw_chk
	OR	A
	JR	Z, .nortc1	

	PUSH	HL
	PUSH	DE
	PUSH 	BC
	LD	DE, tmprtc

	; HL points to buffer of six values in _binary_
	; ROMWBW needs these values in BCD

	LD	A, (HL)
	CALL	.bin2bcd
	LD	(DE), A
	INC	HL
	INC	DE
	LD	A, (HL)
	CALL	.bin2bcd
	LD	(DE), A
	INC	HL
	INC	DE
	LD	A, (HL)
	CALL	.bin2bcd
	LD	(DE), A
	INC	HL
	INC	DE
	LD	A, (HL)
	CALL	.bin2bcd
	LD	(DE), A
	INC	HL
	INC	DE
	LD	A, (HL)
	CALL	.bin2bcd
	LD	(DE), A
	INC	HL
	INC	DE
	LD	A, (HL)
	CALL	.bin2bcd
	LD	(DE), A
	INC	HL
	INC	DE

	LD	HL, tmprtc 
	LD	B, RWBW_PRTC ; Put RTC API -- input buffer is in HL
        CALL	rwbw_invoke

	POP	BC	
	POP	DE
	POP	HL
	; Leave A register containing error code
	RET
.nortc1:
	LD 	A, -1 
	RET

;------------------------------------------------------------------------
; rwbw_getrtc
;------------------------------------------------------------------------
rwbw_getrtc:

	; First, let's check that we're actually on ROMWBW. The next 
	;  steps will cause a crash if we're not.
	LD 	A, -1 
        CALL	rwbw_chk
	OR	A
	JR	Z, .nortc	

	; ROMWBW docs say that no registers are preserved in API 
        ;  calls
	PUSH	HL
	PUSH	DE
	PUSH 	BC
	LD	B, RWBW_GRTC ; Get RTC API -- output buffer is in HL
        CALL	rwbw_invoke
	POP	BC	
	POP	DE
	POP	HL

	PUSH	HL
	PUSH	AF

	; The GETRTC API writes six values at HL to HL+5, and all are in BCD.
	; We need to convert them into ordinary binary. Maybe some sort of
 	;   loop might be in order ;)
	LD	A, (HL)
	CALL	.bcd2bin
	LD	(HL), A;
	INC	HL
	LD	A, (HL)
	CALL	.bcd2bin
	LD	(HL), A;
	INC	HL
	LD	A, (HL)
	CALL	.bcd2bin
	LD	(HL), A;
	INC	HL
	LD	A, (HL)
	CALL	.bcd2bin
	LD	(HL), A;
	INC	HL
	LD	A, (HL)
	CALL	.bcd2bin
	LD	(HL), A;
	INC	HL
	LD	A, (HL)
	CALL	.bcd2bin
	LD	(HL), A;
	INC	HL

	; The value of AF we pop here should be the value that was pushed after the
	;   call to rwbw_invoke, and should contain an error code. However, I've 
        ;   found that sometimes the error code is zero even when there's no
	;   hardware
	POP	AF
	POP	HL

 	RET

.nortc:
	LD 	A, -1 
	RET

tmprtc: db 0, 0, 0, 0, 0, 0

end

