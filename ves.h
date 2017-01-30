;====================================================================
; VES.H
; Fairchild Channel F Header File
; 20041030
; by Kevin Lipe
;====================================================================

VESH_VERSION = 101

; THIS IS A PRELIMINARY RELEASE OF *THE* "STANDARD" VES.H
;
; This file defines memory mapping and BIOS calls for the
; Fairchild Channel F, and also standardized Macros. 

;====================================================================
; E Q U A T E S
;====================================================================

;------------------------
; BIOS Calls
;------------------------
clrscrn         =       $00d0                                   ;uses r31
delay           =       $008f
pushk           =       $0107                                   ;used to allow more subroutine stack space
popk            =       $011e
drawchar        =       $0679

;------------------------
; Colors
;------------------------
red             =       $40
blue            =       $80
green           =       $00
bkg             =       $C0
clear		=	$FF

;------------------------
; Schach RAM
;------------------------
ram		=	$2800					;location of RAM available in Schach cartridge

;===================================================================
; M A C R O S
;===================================================================

;-------------------------
; CARTRIDGE_START
; Original Author: Sean Riddle
; Inserts the $55 that signals a valid Channel F cartridge and an
; unused byte, which places the VES at the cartridge entry point, $802.

	MAC CARTRIDGE_START
	.byte	$55, $00					; valid cart indicator, unused byte
	ENDM

;-------------------------
; CARTRIDGE_INIT
; Original Author: Sean Riddle
; Initalizes the hardware and clears the complement flag.

	MAC CARTRIDGE_INIT
	; initalize the hardware
	lis	0
	outs	1
	outs	4
	outs	5
	outs	0

	; clear the complement flag (r32)
	lisu	4
	lisl	0
	lr	S, A
	ENDM

;-------------------------
; PROMPTS_NO_T
; Original Author: Sean Riddle
; This code functions the same as the "prompts" section of the BIOS,
; but this code doesn't have a "T?" prompt, so it's useful in games that
; don't have time limits or settings.

                MAC PROMPTS_NOT
prompts         SUBROUTINE
                LR   K,P                 ; 
                PI   pushk               ; 
.prompts2:      LI   $85                 ; red 5 (S)
                LR   $0,A                ; 
                PI   prompt              ; 
                LR   A,$4                ; 
                CI   $08                 ; is it button 4, Start?
                BF   $4,.notbut4         ; no, check others
.notbut2:
                PI   popk                ; yes, return
                PK                       ; 
                
.notbut4:       CI   $02                 ; is it button 2, Mode?
                BF   $4,.notbut2         ; 
                LI   $8e                 ; red M
                LR   $0,A                ; 
                PI   prompt              ; 
                LISU 3                   ; 
                LISL 6                   ; 
                LR   A,(IS)              ; 
                as      4                                       ;add the mode to the game #
                LR   (IS),A              ; 
                BF   $0,.prompts2        ; 
                ENDM
	
;-------------------------
; SETISAR
; Original Author: Blackbird
; Sets the ISAR to a register number, using lisu and lisl

	MAC SETISAR
	lisu	[[{1}] >> 3]
	lisl	[[{1}] & %111]
	ENDM