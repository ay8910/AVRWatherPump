;-----------------------------------------------
; HEX TO ASCII
;-----------------------------------------------
;I think, this was the smallest (only 10 words). 

;input: R16 = 8 bit value 0 ... 255 
;output: R18, R17, R16 = digits 
;bytes: 20 
                 
Hex2Ascii:	ldi	 	r18,-1+'0' 
_bcd1:		inc 		r18
		subi 		r16,100 
		brcc		_bcd1 
		ldi		r17,10+'0' 
_bcd2:		dec		r17 
		subi 		r16,-10 
		brcs 		_bcd2 
		sbci 		r16,-'0' 
		ret

;переводит 2х байтовую величину из Х в строку
Hex162Ascii:

;вычитание X=X-Y 0x2710 = 10000
sub16:		sub		xl,yl
		sbc		xh,yh
		ret