;			.include "kernel_def.asm"

;вход: Z-адрес пункта меню в словах
;выход: Z-адрес запрошенного элемента меню в словах (для процедуры CopyStr нужно умножить с пом. MUL2 z)
MenuGetCaption:		adiw		zl,1
MenuGetNext:		adiw		zl,1
MenuGetPrevious:	adiw		zl,1
MenuGetChild:		adiw		zl,1
MenuGetParent:		adiw		zl,1	

MenuGetType:		MUL2		z		;умножаем на 2 т.к. lpm работает с байтами
			lpm		OSRG,z+
			lpm		ACC,z
			mov		zl,OSRG
			mov		zh,ACC
			ret

;загружает в Z текущее значение Menu_Pos
MenuLoadZ:		
			
;MenuGetType1:		clc			;умножаем на 2 т.к. lpm работает с байтами
;			rol		zl
;			rol		zh
;			
;			lpm		OSRG,z+
;			lpm		ACC,z
;			clc				;умножаем прочитанное на 2
;			rol		OSRG		;умножаем прочитанное на 2
;			rol		ACC		;умножаем прочитанное на 2 т.к в программной памяти адреса в виде слов
;			mov		zl,OSRG
;			mov		zh,ACC
;			ret

			

MenuMoveBegin:		LDZ		MI1
			rjmp 		Loc_Menu_Move_Save		;в Menu_Pos - адрес 1го пункта меню

MenuMoveNext:		MENU_LOAD_POS	z
;			lds		zl,Menu_Pos
;			lds		zh,Menu_Pos+1
			rcall 		MenuGetNext
			rjmp 		Loc_Menu_Move_Save

MenuMovePrevious:	MENU_LOAD_POS	z
;			lds		zl,Menu_Pos
;			lds		zh,Menu_Pos+1
			rcall 		MenuGetPrevious
			rjmp 		Loc_Menu_Move_Save

MenuMoveChild:		MENU_LOAD_POS	z
;			lds		zl,Menu_Pos
;			lds		zh,Menu_Pos+1
			rcall 		MenuGetChild
			rjmp 		Loc_Menu_Move_Save

MenuMoveParent:		MENU_LOAD_POS	z
;		lds		zl,Menu_Pos
;			lds		zh,Menu_Pos+1
			rcall 		MenuGetParent

;Loc_Menu_Move_Save:	
;			clc						;делим на 2 т.к. на выходе ф-й MenuGet* - адрес в байтах,
;			lsr		zh				;а в Menu_Pos должен быть адрес в словах
;			ror		zl
Loc_Menu_Move_Save:	sts		Menu_Pos,zl
			sts		Menu_Pos+1,zh			;в Menu_Pos - адрес соседнего пункта меню
			ret
			