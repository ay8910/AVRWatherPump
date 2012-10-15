; в этом файле - выполняемые команды меню

Action1_KeysHandler:		rjmp		loc_A1KH

Action1_Draw:			LDI		Counter,DWIDTH		; Скопировать во 2ю строку видеопамяти надпись из t_Action2_l1
				LDZ		t_Action1_l2*2
				LDY		TextLine2
				RCALL		CopySTR

				ldi		Counter,ON_OFF_WIDTH
				LDY		TextLine1+DWIDTH-ON_OFF_WIDTH
				sbic		PMP1_N,PMP1
				rjmp		loc_A1D1		;переход, если состояние "включён"
				LDZ		t_Off*2
				rjmp		loc_A1D2
loc_A1D1:			LDZ		t_On*2
loc_A1D2:			rcall		CopySTR
				LDY		TextLine1
				LDZ		t_Action1_l1*2
				ldi		Counter,DWIDTH-ON_OFF_WIDTH
				rcall 		CopySTR
				ret
				





				
				LDI		Counter,DWIDTH		; Скопировать в первую строку видеопамяти надпись из t_Action1_l2
				LDZ		t_Action1_l2*2
				LDY		TextLine2
				RCALL		CopySTR

loc_A1KH:			lds		OSRG,Pressed_B
				cpi		OSRG,'B'
				brne		loc_A1KH1		;если нажата кнопка "B" то 
				STSI		Mode,m_Menu		;выставляем режим "Меню"
				SetTask		TS_Draw			; Перерисовываем видеопамять.				
				ret

loc_A1KH1:			cpi		OSRG,'U'		
				brne		loc_A1KH2		;если нажата кнопка "U", то
				sbi		PMP1_P,PMP1		;включаем насос
				SetTask		TS_Draw			; Перерисовываем видеопамять.		
				ret

loc_A1KH2:			cpi		OSRG,'D'		
				brne		loc_A1KH3		;если нажата кнопка "U", то
				cbi		PMP1_P,PMP1		;выключаем насос
				SetTask		TS_Draw			; Перерисовываем видеопамять.		
				ret
			

loc_A1KH3:			ret