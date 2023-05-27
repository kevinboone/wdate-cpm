;------------------------------------------------------------------------
; 
;  WDATE utility
;
;  main.asm 
;
;  Copyright (c)2023 Kevin Boone, GPL v3.0
;
;------------------------------------------------------------------------

	.Z80

	ORG    0100H

	include conio.inc
	include clargs.inc
	include intmath.inc
	include date.inc
	include string.inc
	include romwbw.inc

	JP	main

;------------------------------------------------------------------------
;  prthelp 
;  Print the help message
;------------------------------------------------------------------------
prthelp:
	PUSH	HL
	LD 	HL, us_msg
	CALL	puts
	LD 	HL, hlpmsg
	CALL	puts
	POP	HL
	RET

;------------------------------------------------------------------------
;  prtversion
;  Print the version message
;------------------------------------------------------------------------
prtversion:
	PUSH	HL
	LD 	HL, ver_msg
	CALL	puts
	POP	HL
	RET

;------------------------------------------------------------------------
;  abrtmsg: 
;  Prints the message indicated by HL, then exits. This function
;    does not return
;------------------------------------------------------------------------
abrtmsg:
	CALL	puts
	CALL	newline
	CALL	exit

;------------------------------------------------------------------------
;  abrtusmsg: 
;  Prints the message indicated by HL, then the usage message, then exits.
;  This function does not return
;------------------------------------------------------------------------
abrtusmsg:
	CALL	puts
	CALL	newline
	JP	abrtusage

;------------------------------------------------------------------------
;  putrtc: 
;  Sets the values in rtcbuf to the RTC. If there is a failure, this
;   function prints a message and exits -- it does not return
;------------------------------------------------------------------------
putrtc:
	PUSH	HL
	LD	HL, rtcbuf
	CALL 	rwbw_putrtc
	CP 	0
	JP NZ, 	abrtnortc ; Does not return
	; call dumprtcbuff
	POP	HL
	RET

;------------------------------------------------------------------------
;  abrtnortc 
;  Printf the 'no RTC' message and exits
;------------------------------------------------------------------------
abrtnortc:
	LD	HL, nortc_msg
	CALL	abrtmsg	

;------------------------------------------------------------------------
;  getrealrtc: 
;  Get the values from the RTC into rtcbuff. If this process fails,
;    don't return -- print a message and exit
;------------------------------------------------------------------------
getrealrtc:
	PUSH	HL
	LD	HL, rtcbuf
	CALL 	rwbw_getrtc
	CP 	0
	JP NZ, 	abrtnortc ; Does not return
	POP	HL
	RET

;------------------------------------------------------------------------
;  getdummyrtc: 
;  Fill the values at rtcbuf with dummy values. Only used when testing
;    on a machine with no RTC
;------------------------------------------------------------------------
getdummyrtc:
	PUSH	BC
	PUSH	HL
	LD 	HL, rtcbuf
	LD 	B, 6

.grc_nxt:
	LD 	A, B 
	LD	(HL), A
	INC	HL

	DEC	B
	LD	A, B
	CP	0
	JR 	NZ, .grc_nxt
	POP	HL
	POP	BC
	CALL 	newline
	LD	A, 0 ; Success

	RET

;------------------------------------------------------------------------
;  getrtc: 
;  Get the RTC values into rtcbuff. This function only exists to make
;    it easy to switch between getting real values, and dummy values
;    for testing
;------------------------------------------------------------------------
getrtc:
	;CALL	getdummyrtc
	CALL	getrealrtc
	RET

;------------------------------------------------------------------------
;  dumprtcbuff: 
;  For debugging only -- print the values (in hex) in the RTC buffer
;------------------------------------------------------------------------
dumprtcbuff:
	PUSH	BC
	PUSH	HL
	LD 	HL, rtcbuf 
	LD 	B, 6

.dmp_nxt:
	LD 	A, (HL)
	CALL	puth8
	CALL 	space	
	INC	HL
	DEC	B
	LD	A, B
	CP	0
	JR 	NZ, .dmp_nxt
	POP	HL
	POP	BC
	CALL 	newline
	RET

;------------------------------------------------------------------------
;  put2digits 
;  Print a number in the range 0-99, padding with a leading zero if
;    this number is < 10. This function is for printing hours, minutes,
;    and seconds, where conventionally we show two digits
;------------------------------------------------------------------------
put2digits:
	CP	10
	JR	NC, .p2_two
	PUSH	AF
	LD	A, '0'
	CALL	putch
	POP	AF
.p2_two:
	PUSH	DE
	LD	HL, numbuff
	LD	D, 0
	LD	E, A
	CALL	utoa
	CALL	puts
	POP	DE
	RET

;------------------------------------------------------------------------
;  putdow
;  Print the day of the week in A, where Sunday is zero
;  Note -- we don't check the value is in range, because it comes from
;    a computations, not from the RTC hardware. The computing can only
;    give results in the range 0-6
;------------------------------------------------------------------------
putdow:
	PUSH	HL
	CALL	dayname
	CALL	puts
	POP	HL
	RET

;------------------------------------------------------------------------
;  putmonth 
;  Prints the month in A, where January is 1. We must check that the 
;    value is in range, because it will come from the RTC hardware, which
;    might be set up wrongly
;------------------------------------------------------------------------
putmonth:
	PUSH	HL
	CP	0
	JR	Z, .badmonth
	CP	13
	JR	NC, .badmonth
	CALL 	monthname
	CALL	puts
	POP	HL
	RET
.badmonth:
	PUSH	AF
	LD	A, '?'
	CALL	putch
	POP	AF
	POP	HL
	RET

;------------------------------------------------------------------------
;  abrtrange 
;  Print an out-of-range message for the number in A, and exit
;------------------------------------------------------------------------
abrtrange:
	LD	HL, numbuff
	LD	D, 0
	LD	E, A
	CALL	utoa
	CALL	puts
	LD	A, ':'
	CALL	putch
	CALL	space
	LD	HL, range_msg
	JP	abrtmsg

;------------------------------------------------------------------------
;  checkrange 
;  Checks that A is in the (inclusive) range B-C. 
;  If not, this function does not return -- it shows an error and
;    exits
;------------------------------------------------------------------------
checkrange:
	CP 	B
	JR 	NC, .minok
	CALL    abrtrange

.minok:
	INC	C
	CP	C
	JR	C, .maxok
	CALL    abrtrange

.maxok:
	RET

;------------------------------------------------------------------------
;  args_0 
;  No arguments on the command line -- show the current date and time
;------------------------------------------------------------------------
args_0:
	PUSH HL

	CALL	getrtc ; Does not return if no RTC

        LD	A, (rtcbuf + 2)
	LD	H, A
	LD	A, (rtcbuf + 1);
	LD	L, A

	PUSH	HL
	LD	A, (rtcbuf)
	LD 	L, A
	LD	H, 0
	LD	DE, 2000
	ADD	HL, DE	
	LD	D, H
	LD	E, L
	POP	HL

	CALL	day_of_week
	CALL	putdow
	CALL	space

        LD	A, (rtcbuf + 2)
	CALL	put2digits
	CALL	space

        LD	A, (rtcbuf + 1)
	CALL	putmonth
	CALL	space

	LD	A, (rtcbuf + 1);

	LD	A, (rtcbuf + 3)
	CALL	put2digits
	LD	A, ':' 
	CALL	putch
	LD	A, (rtcbuf + 4)
	CALL	put2digits
	LD	A, ':' 
	CALL	putch
	LD	A, (rtcbuf + 5)
	CALL	put2digits

	CALL	space

	LD	A, (rtcbuf)
	LD 	L, A
	LD	H, 0
	LD	DE, 2000
	ADD	HL, DE	
	LD	DE, numbuff	

	CALL 	putu16	
	CALL	newline

	POP HL
	RET

;------------------------------------------------------------------------
;  args_2 
;  Just two arguments: set hours from args0 and minute from args1
;------------------------------------------------------------------------
args_2:
	PUSH 	BC	
	PUSH	DE
	PUSH 	HL
	CALL 	getrtc

	LD	DE, argv
	LD	HL, rtcbuf

	INC	HL
	INC	HL
	INC	HL
	; HL now points to hours in rtc buff, DE to args0
	LD	A, (DE)
	LD	B, 0
	LD	C, 23
	CALL	checkrange

	LD	(HL), A
	INC HL
	INC DE
	; HL now points to minutes in rtc buff, DE to args1
	LD	A, (DE)
	LD	B, 0
	LD	C, 59 
	CALL	checkrange

	LD	(HL), A

	CALL   	putrtc 
	POP	HL
	POP	DE
	POP	BC
	RET

;------------------------------------------------------------------------
;  args_3: three arguments: hours, minues, seconds 
;------------------------------------------------------------------------
args_3:
	PUSH	DE
	PUSH 	HL
	CALL 	getrtc

	LD	DE, argv
	LD	HL, rtcbuf

	INC	HL
	INC	HL
	INC	HL
	; HL now points to hours
	LD	A, (DE)
	LD	B, 0
	LD	C, 23 
	CALL	checkrange
	LD	(HL), A
	INC HL
	; HL now points to minutes
	INC DE
	LD	A, (DE)
	LD	B, 0
	LD	C, 59 
	CALL	checkrange
	LD	(HL), A
	INC HL
	; HL now points to seconds
	INC DE
	LD	A, (DE)
	LD	B, 0
	LD	C, 59 
	CALL	checkrange
	LD	(HL), A

	CALL   	putrtc 
	POP	HL
	POP	DE

	RET

;------------------------------------------------------------------------
;  args_6: six arguments: all of year, month, day, hour, minute, second
;------------------------------------------------------------------------
args_6:
	PUSH 	BC
	PUSH	DE
	PUSH 	HL
	CALL 	getrtc

	LD	DE, argv
	LD	HL, rtcbuf

	LD	A, (DE) ; Year
	LD	B, 0
	LD	C, 99 
	CALL	checkrange
	LD	(HL), A
	INC HL
	INC DE
	LD	A, (DE) ; Month
	LD	B, 1
	LD	C, 12
	CALL	checkrange
	LD	(HL), A
	INC HL
	INC DE
	LD	A, (DE) ; Day
	LD	B, 1
	LD	C, 31 
	CALL	checkrange
	LD	(HL), A
	INC HL
	INC DE
	LD	A, (DE) ; Hour
	LD	B, 0
	LD	C, 23 
	CALL	checkrange
	LD	(HL), A
	INC HL
	INC DE
	LD	A, (DE) ; Minute
	LD	B, 0
	LD	C, 59 
	CALL	checkrange
	LD	(HL), A
	INC HL
	INC DE
	LD	A, (DE) ; Second
	LD	B, 0
	LD	C, 59 
	CALL	checkrange
	LD	(HL), A
	INC HL
	INC DE

	CALL   	putrtc 
	POP	HL
	POP	DE
	POP	BC
	RET

;------------------------------------------------------------------------
;  Start here 
;------------------------------------------------------------------------
main:
	; Initialize the command-line parser
	CALL	clinit
	LD	B, 0	; Arg count

	; Loop until all CL arguments have been seen
.nextarg:
	CALL	clnext
	JR	Z, .argsdone

	OR	A
	JR	Z, .notsw
	; A is non-zero, so this is a switch character 
	; The only switches we handle are /h, /v, and /s at present
	CP	'H'
	JR	NZ, .no_h
	CALL	prthelp
	JP	.done
.no_h:
	CP	'V'
	JR	NZ, .no_v
	CALL	prtversion
	JP	.done	
.no_v:
	JP	.badswitch

.notsw:
	; A was zero after clnext, so not a switch

        INC	B	; increment argument counter

	LD	A, B
	CP	7
	JR	C, .lt6args

	LD	HL, toomany_msg
	JP	abrtusmsg

.lt6args:
	; If we get here, we don't have too many args

	; HL points to the arg at this point
        CALL	atou
        ; Result is in DE; A=1 on success
	CP	1
	JR	Z, .good_num_arg

        ; Number arg did not convert -- print a message and stop
	PUSH	HL
	LD	HL, bnum_msg 
	CALL    puts
	POP 	HL	
	CALL    space 
	CALL    puts
	CALL   	newline 
	JP	abrtusage

.good_num_arg:
	; If we get here, the current arg is a number, although it
        ;    might not be in range
	LD	A, E ; Ignore MS byte -- all out numbers are < 60

	PUSH 	HL
	PUSH 	DE	

	LD	HL, argv
	LD	D, 0
	LD	E, B
	DEC	E	; B has already been incremented by this point

	ADD	HL, DE
	LD	(HL), A

	POP	DE
        POP 	HL

	JR	.nextarg

.argsdone:
	LD	A, B
	LD	(argc), A

	LD	A, (argc)
	CP	0
	JR	NZ, .not_0
	CALL	args_0
	JR	.done

.not_0:
	CP	2
	JR	NZ, .not_2
	CALL	args_2
	JR	.done

.not_2:
	CP	3
	JR	NZ, .not_3
	CALL	args_3
	JR	.done

.not_3:
	CP	6
	JR	NZ, .not_6
	CALL	args_6
	JR	.done

.not_6:
	LD	HL, us_msg ; TODO
        call    puts
	call    newline

.done:
	; ...and exit cleanly
	CALL	exit

;-------------------------------------------------------------------------
; abrtusage
; print usage message and exit
;-------------------------------------------------------------------------
abrtusage:
	LD	HL, us_msg
	CALL	abrtmsg

;-------------------------------------------------------------------------
; badswitch
; print "Bad option" message and exit. 
;-------------------------------------------------------------------------
.badswitch:
	LD	HL, bs_msg
	CALL	puts
	CALL	newline
	LD	HL, us_msg
	CALL	puts
	CALL	newline
	JR	.done


;------------------------------------------------------------------------
; Data 
;------------------------------------------------------------------------
blank:
	db "   "
	db 0

hlpmsg: 	
	db "/h show help text"
        db 13, 10
	db "/v show version"
        db 13, 10
	db 0

; Scratch area for converting integers to strings
numbuff:
	db "12345678"
	db 0

us_msg:
	db "Usage: wdate [/hv] [{year} {month} {day}] {hour} {minute} [second] "
        db 13, 10, 0

ver_msg:
	db "wdate 0.1a, copyright (c)2023 Kevin Boone, GPL v3.0"
        db 13, 10, 0

bnum_msg:
	db "Bad number: ", 0

bs_msg:
	db "Bad option.", 0 

toomany_msg:
	db "Too many arguments.", 0 

nortc_msg:
	db "No RTC", 0 

range_msg:
	db "Out of range", 0 

; Store month parsed from command line -- only one byte needed
month:
	db 0

; Store year parsed from command line -- this will need two bytes 
year:
	dw 0

; Flag to indicate user wants week to start on Sunday
wssun:	db 0

argv:   db 0, 0, 0, 0, 0, 0
argc:   db 0

; Six-byte buffer for date/time from the RTC. We can refer to the start of
;   this buffer as rtcbuf, and the individual elements as rtcmo, rtcda, etc.
rtcbuf:
rtcye:  ; year
	db 0
rtcmo:  ; month
	db 0
rtcda:  ; day
	db 0
rtchr:  ; hour
	db 0
rtcmi:  ; min
	db 0
rtcse:  ; sec
	db 0

foo0: db "Foo 0!", 0
foo2: db "Foo 2!", 0
foo3: db "Foo 3!", 0
foo6: db "Foo 6!", 0

end 

