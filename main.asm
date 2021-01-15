;**********************************************************************************************
; Sleizsa Trio v0.2 - Fairchild Channel F Music routine
; by utz 2017 * irrlichtproject.de
;**********************************************************************************************
; Copyright (c) 2017-2020, utz/irrlicht project
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;     * Redistributions of source code must retain the above copyright
;       notice, this list of conditions and the following disclaimer.
;     * Redistributions in binary form must reproduce the above copyright
;       notice, this list of conditions and the following disclaimer in the
;       documentation and/or other materials provided with the distribution.
;     * Neither the name of irrlicht project nor the
;       names of its contributors may be used to endorse or promote products
;       derived from this software without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL IRRLICHT PROJECT BE LIABLE FOR ANY
; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;**********************************************************************************************

	processor f8
	include	"ves.h"		;standard ChannelF header

prog_size	= 62		;program size in kilobytes (minimum 2, increase if necessary)

duty1		= $20		;duty cycle settings (should be <= $40)
duty2		= $20
duty3		= $20

	org $800

cartridge.init			;init bla
	CARTRIDGE_START
	CARTRIDGE_INIT

;**********************************************************************************************
;scratchpad register use
;r0,1 - divider ch1
;r2,3 - accu ch1
;r4,5 - divider ch2
;r6,7 - accu ch2
;r8,9 - divider ch3
;r10,11 - accu ch3
;r12-13 (K) length counter (speed)
;r14-15 (Q) temp
;r16 (via ISAR) - output state


main
	;di				;disable interrupts if any
	lisl 0				;point ISAR to r16
	lisu 2

	dci musicData			;point DC0 to start of music data
	xdc

.readSeq
	xdc				;swap in DC0
	lm				;read addr hi-byte and inc DC0
	ci $ff				;if hi-byte = $ff, end of sequence reached
	bnz .cont

	dci musicLoop			;point DC0 to loop point
	br .readSeq+1


;*******************************************************************************
.drum
	lr h,dc				;backup data pointer
	dci 0				;point to beginning of ram

.drumlp1
	li $c0				;load output mask to A
	nm				;& with memory and increment data pointer
	outs 5

	lr q,dc				;save data pointer in Q
	lr a,qu				;read hi byte of Q
	ci 2				;compare against 3 (stop reading at $200)
	bnz .drumlp1			;otherwise loop

.drumexit
	lr dc,h				;restore data pointer

	li $c8				;adjust speed counter

.drumexit2
	lr Kl,a

	clr				;stop sound
	outs 5

	br .drumReturn			;return to main routine

.drum2
	lis $f				;r4-5 is length/delay counter (actual = $f100 loops)
	lr 4,a
	clr
	lr 5,a
	lr 3,a				;accu
	lr 2,a
	lr 1,a				;divider
	lis $1
	lr 0,a

.drumlp2
	lr a,1				;r0-1 += r2-3
	as 3
	lr 3,a
	lr a,0
	lnk
	as 2
	lr 2,a
	bnc .noUpd			;if carry, update divider

	li $80				;r2-3 -= 127
	as 1
	lr 1,a

	clr
	lnk
	com
	inc
	as 0
	lr 0,a

.noUpd
	lr a,2				;fetch hi-byte of accu (will generate 50:50 square wave)
	ni $40
	outs 5

	clr
	ds 5				;update length counter lo-byte
	lnk				;update length counter hi-byte
	as 4
	lr 4,a
	bnz .drumlp2

	li $88

	br .drumexit2


;*******************************************************************************
.cont					;sequence parsing, cont'd.
	lr 10,a				;pattern addr -> DC1
	lm
	lr 11,a

	xdc
	lr dc,h


;*******************************************************************************
.readPtn
	clr
	am				;read length byte
	bz .readSeq			;if 0, end of pattern reached

	lr Ku,a

	bm .drum			;if bit 7 set -> noise drum
	ci $40				;if bit 6 set -> kick
	bnc .drum2

	clr
	lr Kl,a				;clear length counter lo-byte

.drumReturn
	lr a,Ku				;mask out drum bits and negate
	ni $3f
	com
	inc
	lr Ku,a

	clr
	lr 2,a				;clear channel accus
	lr 3,a
	lr 6,a
	lr 7,a
	lr 10,a
	lr 11,a


	lm				;load note byte ch1

	xdc
	lr q,dc				;backup sequence pointer
	dci .noteTab
	adc				;add note byte as offset to table pointer
	lm				;set note divider
	lr 0,a
	lm
	lr 1,a


	xdc
	lm				;note byte ch2

	xdc
	dci .noteTab
	adc
	lm
	lr 4,a
	lm
	lr 5,a

	xdc
	lm				;note byte ch3

	xdc

	lr 8,a				;if bit 0 of note byte ch3 is set,
	ni 1				;enable noise mode
	bnz .loadNoise

	lr a,8
	ni $fe

	dci .noteTab
	adc
	lm
	lr 8,a
	lm
	lr 9,a

	lr dc,q				;retrieve sequence pointer
	xdc


;*******************************************************************************
.playNote

	li $3f			;2.5	;reset output state
	lr s,a			;1

	lr a,1			;1	;ch1, add divider to accu
	as 3			;1
	lr 3,a			;1
	lr a,0			;1
	lnk			;1
	as 2			;1
	lr 2,a			;1

	ai duty1		;2.5	;if accu hi-byte + $20 > $ff switch output state on
	lr a,s			;1
	lnk			;1
	lr s,a			;1


	lr a,5			;1	;ch2
	as 7			;1
	lr 7,a			;1
	lr a,4			;1
	lnk			;1
	as 6			;1
	lr 6,a			;1

	ai duty2		;2.5
	lr a,s			;1
	lnk			;1
	lr s,a			;1


	lr a,9			;1	;ch3
	as 11			;1
	lr 11,a			;1
	lr a,8			;1
	lnk			;1
	as 10			;1
	lr 10,a			;1

	nop			;1	;timing correction (see .playNoteNoise)
	nop			;1
	nop			;1

	ai duty3		;2.5
	lr a,s			;1
	lnk			;1


 	ni $40			;2.5	;calculate output state (0 = off, $40 = on)


	outs 5			;4	;output to port


	lr a,Kl			;1	;update length counter (speed)
	inc			;1
	lr Kl,a			;1
	lr a,Ku			;1
	lnk			;1
	lr Ku,a			;1

	bnz .playNote		;3.5
				;59

	br .readPtn


;*******************************************************************************
.loadNoise
	lr a,8
	ni $fe

	dci .noteTab
	adc
	lm
	lr 8,a
	lm
	lr 9,a

	lr dc,q				;retrieve sequence pointer
	xdc

;*******************************************************************************
.playNoteNoise

	li $3f			;2.5	;reset output state
	lr s,a			;1

	lr a,1			;1	;ch1, add divider to accu
	as 3			;1
	lr 3,a			;1
	lr a,0			;1
	lnk			;1
	as 2			;1
	lr 2,a			;1

	ai duty1		;2.5	;if accu hi-byte + $20 > $ff switch output state on
	lr a,s			;1
	lnk			;1
	lr s,a			;1


	lr a,5			;1	;ch2
	as 7			;1
	lr 7,a			;1
	lr a,4			;1
	lnk			;1
	as 6			;1
	lr 6,a			;1

	ai duty2		;2.5
	lr a,s			;1
	lnk			;1
	lr s,a			;1


	lr a,9			;1	;ch3
	as 11			;1
	lr 11,a			;1
	lr a,8			;1
	lnk			;1
	as 10			;1
	lr 10,a			;1

	as 10			;1	;a simple PRNG to generate noise
	lnk			;1
	lr 10,a			;1

	ai duty3		;2.5
	lr a,s			;1
	lnk			;1


 	ni $40			;2.5	;calculate output state (0 = off, $40 = on)


	outs 5			;4	;output to port


	lr a,Kl			;1	;update length counter (speed)
	inc			;1
	lr Kl,a			;1
	lr a,Ku			;1
	lnk			;1
	lr Ku,a			;1

	bnz .playNoteNoise	;3.5
				;59

	jmp .readPtn


;**********************************************************************************************
.noteTab		;A-0 - B-5
	.word $0
	.word $1db, $1f8, $215, $235, $257, $27a, $2a0, $2c8, $2f2, $31f, $34f, $381
	.word $3b7, $3ef, $42b, $46a, $4ae, $4f5, $540, $590, $5e5, $63f, $69e, $702
	.word $76d, $7de, $856, $8d5, $95b, $9ea, $a81, $b21, $bca, $c7d, $d3b, $e05
	.word $eda, $fbc, $10ac, $11aa, $12b7, $13d3, $1501, $1641, $1794, $18fb, $1a77, $1c0a
	.word $1db5, $1f79, $2158, $2353, $256d, $27a7, $2a03, $2c82, $2f28, $31f5, $34ee, $3814
	.word $3b69, $3ef2, $42b0

        if [prog_size > 7]
        org $3000
        endif

musicData
 	include	"music.asm"		;song data
