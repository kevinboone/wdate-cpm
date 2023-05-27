;------------------------------------------------------------------------
;  clargs.inc
;  Copyright (c)2022-3 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------

; This module implements a very simple command-line argument parser. 
; The caller calls clinit first, to set the parser up. Then it calls
;   clnext until clnext returns with the zero flag set. At this point,
;   there is nothing left to parse.
; If the Z flag is not set, clinit returns a number in A. If this number
;   is non-zero, then it is the ASCII value of a switch character.
; Switches can be introduced using "/" or "-"; they can be combined into
;   the same argument. If clinit returns with A set to zero, then HL
;   points to a particular argument. 
; If A is zero, then HL points to a zero-terminated argument that is not
;   a switch
; There is no support for switches that themselves take arguments, or for
;   arguments that contain spaces. The only whitespace recognized is
;   a plain ASCII space (' ').
; Callers should protect the HL and AF registers if necessary; other
;   registers should be unaffected.
; Note that this function copies the command-line buffer to working memory,
;   and therefore adds a little over 128 bytes to the program size. It's
;   probably safe, in CP/M to overwrite the command-line buffer itself,
;   which would be both quicker and less memory-hungry. It just seems a
;   bit ... eeew.

	.Z80

external clinit
external clnext

