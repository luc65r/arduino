/*  -*- Mode: Asm -*-  */
/* Copyright (C) 1998-2021 Free Software Foundation, Inc.
   Contributed by Denis Chertykov <chertykov@gmail.com>

This file is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any
later version.

This file is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

Under Section 7 of GPL version 3, you are granted additional
permissions described in the GCC Runtime Library Exception, version
3.1, as published by the Free Software Foundation.

You should have received a copy of the GNU General Public License and
a copy of the GCC Runtime Library Exception along with this program;
see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see
<http://www.gnu.org/licenses/>.  */

/*******************************************************
       Division 16 / 16 => (result + remainder)
*******************************************************/
#define	r_remL	r26	/* remainder Low */
#define	r_remH	r27	/* remainder High */

/* return: remainder */
#define	r_arg1L	r24	/* dividend Low */
#define	r_arg1H	r25	/* dividend High */

/* return: quotient */
#define	r_arg2L	r22	/* divisor Low */
#define	r_arg2H	r23	/* divisor High */
	
#define	r_cnt	r21	/* loop count */

.global __udivmodhi4
__udivmodhi4:   
	sub	r_remL,r_remL
	sub	r_remH,r_remH	; clear remainder and carry
	ldi	r_cnt,17	; init loop counter
	rjmp	__udivmodhi4_ep	; jump to entry point
__udivmodhi4_loop:
        rol	r_remL		; shift dividend into remainder
	rol	r_remH
        cp	r_remL,r_arg2L	; compare remainder & divisor
	cpc	r_remH,r_arg2H
        brcs	__udivmodhi4_ep	; remainder < divisor
        sub	r_remL,r_arg2L	; restore remainder
        sbc	r_remH,r_arg2H
__udivmodhi4_ep:
        rol	r_arg1L		; shift dividend (with CARRY)
        rol	r_arg1H
        dec	r_cnt		; decrement loop counter
        brne	__udivmodhi4_loop
	com	r_arg1L
	com	r_arg1H
; div/mod results to return registers, as for the div() function
	movw	r_arg2L, r_arg1L	; quotient
	movw	r_arg1L, r_remL		; remainder
	ret

__divmodhi4:
        .global _div
_div:
        bst     r_arg1H,7           ; store sign of dividend
        mov     r0,r_arg2H
        brtc    0f
        com     r0                  ; r0.7 is sign of result
        rcall   __divmodhi4_neg1    ; dividend negative: negate
0:
        sbrc    r_arg2H,7
        rcall   __divmodhi4_neg2    ; divisor negative: negate
        call    __udivmodhi4        ; do the unsigned div/mod
        sbrc    r0,7
        rcall   __divmodhi4_neg2    ; correct remainder sign
        brtc    __divmodhi4_exit
__divmodhi4_neg1:
        ;; correct dividend/remainder sign
        com     r_arg1H
        neg     r_arg1L
        sbci    r_arg1H,0xff
        ret
__divmodhi4_neg2:
        ;; correct divisor/result sign
        com     r_arg2H
        neg     r_arg2L
        sbci    r_arg2H,0xff
__divmodhi4_exit:
        ret

#undef r_remH
#undef r_remL

#undef r_arg1H
#undef r_arg1L

#undef r_arg2H
#undef r_arg2L
             	
#undef r_cnt
