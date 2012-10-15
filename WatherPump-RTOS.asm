			.include "/usr/share/avra/includes/m16def.inc"	; ���������� ATMega16
			.include "kernel_def.asm"
			.include "define.asm"	; ���� ��� ����������� ���������� ���
			.include "macro.asm"	; ��� ������� � ��� ���


;			.include "./Math/hex2ascii.asm"
			.include "kernel_macro.asm"
			.include "./WH/lcd4_macro.inc"

			.include "menu_macro.asm"

;============SSEG=============================================================
			.DSEG
Mode:		.byte					1		; ���������� ������ �����������
;		
		.equ	m_Normal			=1		; ����� ��������
		.equ	m_Terminal			=2		; ����� �������������
		.equ	m_ADC				=3		; ����� ������ ���
		.equ	m_Button			=4		; ����� ����� ������� ������
		.equ	m_Menu				=5		; ����� ����
		.equ	m_Action			=6		; 
		
		.equ	btn_Times			=5		;���������� ������ btn_Push_Pop_Delay, ������� ����� ��������� ���������� ������ � ���������� ������������ ����������
		.equ	btn_Push_Pop_Delay		=200		;�������� � �� �� ����������� ������� �� ������ ����������� ���������� ������
		.equ	btn_Scan_Delay			=100		;�������� ������� ������������ ������ 
		.equ	ON_OFF_WIDTH			=3		;����� ������ ON ��� OFF

BTN_PUSHED_CNT:	.byte					1		; ������� ���-�� �������, ������� ����� ������� ���� ���� � ������� �-� ScanButtonsForPop 
									; ��� ����������� ����������. ���� �� ��� ���-�� ������� �-�� ���������� ������ 
									; ���������� �� �������, �� ���������� ������� ����������. ���� ���-�� ������� � ���� ScanButtonsForPop

ClockLow:	.byte					1		;
ClockHigh:	.byte					1		;

ADC_Data:	.byte					1		; ��� ������������ ������ ���
ADC_OLD:	.byte					1		; ��� �������� ���������� �������� ������ ���

ADC_DIG0:	.byte					1		; � ���� ���� ������� �������� ASCII ����
ADC_DIG1:	.byte					1		; ������ �� ���, �������������� � ������ �� �����
ADC_DIG2:	.byte					1		; 

Pressed_B:	.byte					1		; � ���� ���������� �������� ��� ��������� ������� �������

UDR_I:		.byte					1		; �������� ���� 

BreakLoop:	.byte					3		; ����� ������ �� ����� �������?

RX_CURR:	.byte					1		; ��������� ������� ���������

TextLine1:	.byte					DWIDTH	; �����������. ����� �� ������� �� ������ ������
TextLine2:	.byte					DWIDTH	; ������ ������� � lcd4_macro.inc, � ����� �����.

ScrlBeg1:	.byte					0	; ������� ������ ������� � ������ 1
ScrlEnd1:	.byte					15	; ������� ����� ������� � ������ 1

ScrlBeg2:	.byte					0	; ������� ������ ������� � ������ 2
ScrlEnd2:	.byte					15	; ������� ����� ������� � ������ 2

;PWM_L_V:	.byte					1
;PWM_L_V2:	.byte					1

Menu_Pos:	.byte					2	;����� ���������� � ������ ������ ������ ����, ���� 0000 - ���� �� �������
Action_Addrr:	.byte					2	;����� ���������� � ������ ������ Action�
Action_Draw_Addrr:	.byte				2	;����� ��������� ��������� ������ ��� �������� ���������� Actiona
;UART_Text:	.byte					10		; ������ �����. �� ������������.

;bcd5:		.byte					5	; 5 �������� ����������� ����� ��� ������ ��� �� ����� ��.���� - ��.�������� ������

; ������� ������������ �������
		.equ TaskQueueSize 			= 10		; ������ ������� �����
TaskQueue: 	.byte					TaskQueueSize 	; ����� ������� ����� � SRAM
			
		.equ TimersPoolSize 			= 10		; ���������� ��������
TimersPool:	.byte 					TimersPoolSize*3; ������ ���������� � �������� (�������)


;===========CSEG==============================================================
			.cseg
			.include "vectors.asm"	; ��� ������� ���������� �������� � ���� �����

			
			.ORG	INT_VECTORS_SIZE		; ����� ������� ����������


;=============================================================================!
; Interrupts procs ===========================================================!
;=============================================================================!
; Output Compare 2 interrupt 
; Main Timer Service - ������ �������� ���� ���� - ���������� ����������

OutComp2Int:		push		OSRG
			in 		OSRG,SREG			; Save Sreg
			push 		OSRG				; ���������� �������� OSRG � �������� ��������� SREG
			push 		ZL	
			push 		ZH				; ���������� �������� Z
			push 		Counter				; ���������� �������� Counter
	
ocL01:			TimerService				; ������ ������� RTOS 

			pop 		Counter				; ��������������� ����������
			pop 		ZH
			pop 		ZL

			pop 		OSRG				; ��������������� ��������
			out 		SREG,OSRG
			pop		OSRG

			
			
;			rcall		IncClock
			RETI					; ������� �� ����������
;.............................................................................

; ���������� �� ���. �� ��� ������ ������� �� ������, ������ ���������� ������
; � ������ ������ ���
ADC_INT:		PUSH	OSRG				; ��������� ������ �������
	
			IN		OSRG,ADCH			; ����� ������ �� ���
			STS		ADC_Data,OSRG		; ������������� �� � ���

			POP		OSRG				; ��������������� ������� �������
			RETI						; ����� �� ����������


;.............................................................................

;���������� �� ���������� ����� � UART
RX_OK:			reti			;���������
			PUSH 	OSRG
			IN 		OSRG,SREG			; Save Sreg
			PUSH 	OSRG

			IN		OSRG,UDR
			STS		UDR_I,OSRG

			SetTask			TS_Terminal

			POP 	OSRG				; ��������������� ��������
			OUT 	SREG,OSRG			; 
			POP 	OSRG
			RETI						; ������� �� ����������


;=============================================================================!
; Main code ==================================================================!
;=============================================================================!
Reset:			OUTI 	SPL,low(RAMEND) 		; ������ ����� �������������� ����
			OUTI	SPH,High(RAMEND)								

			.include "init.asm"				; ��� ������������� ���.


; ������ ������� ���������
Background:		rcall	ScanADC				; ������������ ���
;			RCALL	Send				; ����� ���� � UART 
			rcall	Fill				; ����������� ������

;		RCALL	CheckADC			; �������� ��������� ��� �� ���������
			
;			RCALL	SetDefMode			; ����� ������ ����������� � ��������� ��������� ������ ����� �� �����
			rcall	MenuMoveBegin
			STSI	Mode,m_Normal			
			SetTask	TS_Draw	

			rcall	ScanButtonsForPush			; ������������ ������.
			rcall	IncClock			; ��������� �������� ������

Main:			SEI				; ��������� ����������.

			wdr				; Reset Watch DOG (���� �� "���������" "������". �� ��� ������� ����� ����� � ���� 	; reset ��� ����������)
			rcall 	ProcessTaskQueue	; ��������� ������� ���������
			rcall 	Idle			; ������� ����
											
			rjmp 	Main			; �������� ���� ��������� ����



;=============================================================================
;Tasks
;=============================================================================
Idle:			RET					; ������� ����. �� ������������

IncClock:		SetTimerTask	TS_IncClock,1000	;���������� ��������� ����� (2 �����, �������) 
			LDZ		ClockLow		;����� ��. ������� - � Z
			ld		OSRG,Z			;��.���� - � OSRG
			inc		OSRG			;����������� ��.����
			st		Z+,OSRG			;(Z) = OSRG, Z = Z + 1
			brne		icL0			;Branch if Z!=1
			ld		OSRG,Z
			inc		OSRG
			st		Z,OSRG			;
icL0:			ret

;-----------------------------------------------------------------------------
; ������ ������������ ���. ��� � 10�� ����������� ��� � ����� ��������.
ScanADC:	SetTimerTask	TS_ScanADC,10	; ��������������� ������ ����� ��������� �������

			OUTI	ADCSRA,(1<<ADEN)|(1<<ADIE)|(1<<ADSC)|(1<<ADATE)|(3<<ADPS0)	; ��������� ����������� ��������������
			RET									; �� ���� ������ ���������

;-----------------------------------------------------------------------------
; ������ ������� ������ ����� ��������. ��� � 50�� ���� ���� ������� ������� ���
Send:		SetTimerTask	TS_Send,50		; ��������������� ������ ����� ��������� ��������

			LDS		OSRG,ADC_Data			; ��������� ���� �� ���������� ADC_DATA
			OUT		UDR,OSRG				; ��������� ��� ����� USART 
			RET
;-----------------------------------------------------------------------------
; ������ ���������� ������ �������. ������� ����������� 5 ��� � �������, ������ 200��
; ������ ������� �� ����������� � ����� ������������ � ���������� HD44780
Fill:		SetTimerTask	TS_Fill,200		; ���������������� ������ ����� ��������� ��������

			LCDCLR				; ������� �������

			LDZ	TextLine1		; ����� � ������ Z ����� ������ �����������
			ADIW	r24,0

			LDI	Counter,DWIDTH		; ��������� ������� ������ �������� � ������

Filling1:		LD	OSRG,Z+			; ����� ��������������� ����� �� �����������, ���������� ������ Z
			RCALL	DATA_WR			; � ���������� �� �������

			DEC	Counter			; ��������� �������. 
			BRNE	Filling1		; ���� �� ����� 0 (������ �� ���������) - ���������

			LCD_COORD 0,1			; ��� �������� ������ - ��������� ������ � �������

			LDI	Counter,DWIDTH	; ����� ��������� ������� ������

Filling2:		LD	OSRG,Z+			; ����� ������ ������ ����������� ��������� �� ���� - ��� ���� ���� �� ������ 
			RCALL	DATA_WR			; � ����� �� ������� ������ ������ ������ �� �����������

			DEC	Counter			; ��������� �������
			BRNE	Filling2		; ���� ������ �� ��������� - ����������.
	
			RET
;-----------------------------------------------------------------------------
; ������ ���������� ������.����� ������ - � Z
; 
Scroll:			LDZ	TextLine1
			ret


;-----------------------------------------------------------------------------
; ��� ������� ��������� � �����������. �������� � ����������� �� ������ �����������
; ������� �� ������ f_Button, f_Normal, f_Terminal, f_ADC �� ������ �� �����. ����� �� 
; ������ DRAW �� RET � ����� ������ ������.

Draw:			LDS	OSRG,Mode		; ����� ������� �������� ������

			CPI	OSRG,m_Normal		; � ���������� ����� ��
			BREQ	f_Normal		; ���� ���������� ����� - ��������� � ����

;			CPI	OSRG,m_Terminal		; ���� ������������ - �� � ������ ���������
;			BREQ	f_Terminal
			
			cpi	OSRG,m_Menu
			breq	f_Menu

			CPI	OSRG,m_ADC		; ����������, �� � ������ ���
;			BREQ	f_ADC

			cpi	OSRG,m_Action
			breq	f_Action

			ret

;..............................................................................
; ���������� �����. � ���� ������. �� ����� ��������� ������ �����. ������ ������� ��� ���� �� �����
f_Normal:
;f_Menu:
			LDI		Counter,DWIDTH		; ����������� � ������ ������ ����������� ������� "Pinboard v1.0"
			LDZ		t_Normal1*2
			LDY		TextLine1
			RCALL		CopySTR

			LDY		ClockLow
			ld		ACC,Y+			; ACC		= r16	=	fbinL
			ld		OSRG,Y			; OSRG 		= r17	=	fbinH
			rcall 		bin16BCD5

			LDZ		TextLine2
			rcall		bcd52line
	
			SetTimerTask		TS_Draw,10
;			LDI		Counter,5		; ����������� �� ������ ������ ����������� ������� "by DI HALT 2009"
;			LDZ		t_Normal2*2		; ������ ��� ������������� � ����� ���������. 
;			LDY		TextLine2
;			RCALL		CopySTR
	
			RET

;f_Normal:
f_Menu:			MENU_LOAD_POS	Z			;��������� � Z ������� ��������� � ����
			rcall		MenuGetType		;��� �������� ������ ���� - � OSRG
			cpi		OSRG,ROOT_ITEM
			brne		loc_menu_2		;��������� - ��� ��� ���
			LDZ		t_RootMenu_Cap*2	;���� ���, �� � z ��������� ����� ��������� �������� ������� ����
			rjmp		loc_menu_1
loc_menu_2:		MENU_LOAD_POS	Z			;���� �� ���, �� ��������������� � Z ������� ������� � ����
			rcall		MenuGetParent		;� �������� ��������� ������������� ������ ��� ������ 
			rcall		MenuGetCaption		;� 1� ������ ����������
			MUL2		Z			;�������� �� 2 �.�. � ��������� ���� ������ � ������,
loc_menu_1:		LDI		Counter,DWIDTH		;� ��� �-�� CopySTR ����� ����� � ������
			LDY		TextLine1		;� Y - ����� ������ � ���
			RCALL		CopySTR			

			MENU_LOAD_POS	Z			;������ 2 ����������. ��������������� ������� � ����
			rcall 		MenuGetCaption		;�������� ����� ������ � ��������� ������ ���� � ������
			MUL2		Z			;����������� � ����� ��� �-�� CopySTR
			LDI		Counter,DWIDTH
			LDY		TextLine2
			RCALL		CopySTR

			ret

f_Action:		lds		zl,Action_Addrr		;��������� � Z ����� ����������� ������ �������� Actiona
			lds		zh,Action_Addrr+1
			adiw		zl,1			;��������� ����� - ���������� ������ ����� Actiona
			ijmp					;����� �����������
			ret

;.............................................................................
; ����������� ���������. ��� �� �������� �� ����� � ����������� ������ ������ ������. ������
; ������ ��� �������� ���������� ���������� �� UART
;f_Terminal: 		LDI		Counter,DWIDTH		; 
;			LDZ		t_Terminal*2
;			LDY		TextLine1
;			RCALL		CopySTR
	
;			RET
;.............................................................................
; ����������� ������ ���. 
f_ADC:			LDI		Counter,DWIDTH			; ������� ����� �������� ������ �����������
			LDZ		t_ADC1*2		; ����� ����� �� ����� ������ ������ � ���� ��������
			LDY		TextLine1		; �� � ������ ������ �����������.
			RCALL		CopySTR
			
			LDS		OSRG,ADC_DIG2		; �� ������ ������ �� ������� ��������� �������� ����
			STS		TextLine2,OSRG		; ������� ���������� ��� ������ Convert 

			LDS		OSRG,ADC_DIG1		; ��� �������� ������ � ���. ������ ��������, ��� �����
			STS		TextLine2+1,OSRG	; ��������� ������ ��������� �� ������ ������ ������ �����������
			
			LDS		OSRG,ADC_DIG0
			STS		TextLine2+2,OSRG

			LDI		Counter,DWIDTH-3	; � �����, �������� ��� ��������� �����. ������ "- ��������"
			LDZ		t_ADC2*2			; �.�. ��� ������� �� ��� ��������, �� ������� ����� �������� �� 3
			LDY		TextLine2+3
			RCALL		CopySTR
			

EX_F:			RET					; ����� �� ������



CopySTR:		LPM		OSRG,Z+			; ��������� ����������� �� ����� � ���
			ST		Y+,OSRG			; ����� ���� �� ������� Z � ������ ��� � ������
			DEC		Counter			; �� ������� Y. ��� ���� ��������� ���������������� ������
			BRNE		CopySTR			; � ������� ������� ������ � �������� Counter 
			RET

;-----------------------------------------------------------------------------
; ������ ������ � ������ ������ 5 ������ �����������
SetDefMode:		
;			SetTimerTask	TS_SetDefMode,5000 		; ���������������� ������ ����� ��������� ��������
			STSI	Mode,m_Normal				; ����� ������ � 0 - ���������� �����, ����� ��������
			SetTask	TS_Draw					; ���������� �� ������� ������ ����������� ������
			RET
;-----------------------------------------------------------------------------

; ������ �������� ��������� �������� ��� - �� ���������� ��?
CheckADC:	SetTimerTask	TS_CheckADC,100		; ������� �������������� �� 100��

			LDS		OSRG,ADC_OLD				; ����� ���������� �������� ���
			LDS		ACC,ADC_DATA				; ����� ��������� �������� ���

			ANDI		ACC,0b11110000				; �������� ����� ���������� ������� ����. ��� ����� ������ ������� ���������
			STS		ADC_OLD,ACC				; � ������� ���������� �������� ���������� � ������ ��������

			CP		ACC,OSRG				; ���������� ������� �������� � ������� ������ ������.

			BREQ		EX_CA					; ���� �������� �� ����������, �� �������.	

			SetTask		TS_Convert				; � ���� ����������, �� ��������� ������ ����������� ��������� ���

EX_CA:			RET
;-----------------------------------------------------------------------------
; ��� ������ ����� ���� ��������� ��� � ���������� ��� � ��� ����� ASCII ����� ��������� ��� ������ �� �������
Convert:		LDS		R16,ADC_DATA		; ����� �� ����� ��������

			RCALL		Hex2Ascii		; �������� ������� ����������� (��� � ����� Math\hex2ascii.asm)
			
			STS		ADC_DIG0,R16		; � ��������� ����� � ���������� ��������, ������� ����� ��������
			STS		ADC_DIG1,R17		; ������ DRAW
			STS		ADC_DIG2,R18

			STSI		Mode,m_ADC		; ������� ������� ��� �� ��������� 2������� � ��� ����� ���

;			SetTimerTask	TS_SetDefMode,2000	; ������� ����� � ��������� �����
			SetTask		TS_Draw			; � ������� ����� ��������� ���������� �����������

			RET


;�������������� ������������ ������ �� �������. ��� ����������� ������� � ������� � ��������� �������� ������ 
;����������� ���������� (��� ���������� ��������)
ScanButtonsForPush:
			rcall 		ScanButtons
			cpi		OSRG,0				
			brne		loc_pressed_1
			SetTimerTask	TS_ScanButtonsForPush,btn_Scan_Delay	; ���� �� ���� ������ �� ������, �� ����� ������ � ������� ����� ScanButtonsForPush  
			ret

loc_pressed_1:		
			sts		Pressed_B,OSRG					; � ���� ������, �� ��������� ����� ������ � ���
			SetTimerFirstTask	TS_ScanButtonsForPop,btn_Push_Pop_Delay		; ������ � ������� ������ �������� ���������� ������ ����� btn_Push_Pop_Delay �� 
			ret

;������ ����� ��������� ������������ ������ - �������� ���������� ������.
ScanButtonsForPop:	
			rcall		ScanButtons
			cpi		OSRG,0
			brne		loc_not_released1

			SetTimerTask	TS_ScanButtonsForPush,btn_Scan_Delay	;����, ������ ��������, ������ ����� ��������� ����� ������������ ������ ����� btn_Scan_Delay ��
			rcall 		ProcessKeyStroke
			SetTimerTask	TS_ScanButtonsForPush,btn_Scan_Delay
			ret
			
loc_not_released1:	SetTimerTask	TS_ScanButtonsForPop,btn_Push_Pop_Delay	;��� ���� ���� �������� ���������� ������ ���� ������ �������� �� ����
			ret

;������ ��������� ������, ��������� � OSRG ����� ������� ������, ��� 0, ���� �� ������ �� �����. ������������ ������ �� ScanButtonsForPop �
;ScanButtonsForPush, ������� �������� �� ��������.
ScanButtons:
			clr		osrg

			sbis		BTD_N,BTD		; � ��������� ���� ������
			ldi		OSRG,'F'		; ���� ������ ������, �� ���������� � OSRG

			sbis		BTA_N,BTA		; � ��������� ���� ������
			ldi		OSRG,'U'		; ���� ������ ������, �� ���������� � OSRG

			sbis		BTB_N,BTB
			ldi		OSRG,'B'

			sbis		BTC_N,BTC
			ldi		OSRG,'D'
			
			ret

;��������� ���� ������� ������: �������� NormalModeKeysHandler, MenuModeKeysHandler ��� ActionModeKeysHandler
;� ����������� �� ��������� � ������ ������ ������ �������
ProcessKeyStroke:	SetTimerTask	TS_SetDefMode,60000
			lds		acc,Mode
			cpi		acc,m_Normal		;������� �����?
			brne		loc_sb_not_normal	;��� - �������
			rcall		NormalModeKeysHandler
			ret

loc_sb_not_normal:	cpi		acc,m_Menu		;����� ����?
			brne		loc_sb_not_menu		;��� - ���������
			rcall		MenuModeKeysHandler	
			ret

loc_sb_not_menu:	cpi		acc,m_Action		;Action-�����?
			brne		loc_sb_not_action		;��� - ���������
			rcall		ActionModeKeysHandler	
loc_sb_not_action:	ret
			



NormalModeKeysHandler:	
			lds		OSRG,Pressed_B
			cpi		OSRG,'B'
			brne		loc_no_menu		;�������, ���� ������ �� ������� "�����"
			
			STSI		Mode,m_Menu		;���������� ����� "����"
			rcall		MenuMoveBegin
			SetTask		TS_Draw			; �������������� �����������.
loc_no_menu:		ret


MenuModeKeysHandler:	
			lds		OSRG,Pressed_B
			cpi		OSRG,'B'
			brne		loc_MMKH_next_1		;��������� ������
			MENU_LOAD_POS	z			;� Z - ������� ������� � ����
			rcall 		MenuGetType		;������ ������ "�����", �������� � OSRG ��� �������� ������ ����
			cpi		OSRG,ROOT_ITEM		;������� ����� ���� ��������?
			brne		loc_MMKH_next_2		;���, �� ��������

;			SetTimerTask	SetDefMode,5
			STSI		Mode,m_Normal		;� ���� ��������, ���������� ���������� �����
			SetTask		TS_Draw			; �������������� �����������.
			ret
loc_MMKH_next_2:						;���� ��������, ���� ������ ������ "�����" � ������� ����� ���� �� ��������
			rcall		MenuMoveParent
			SetTask		TS_Draw			; �������������� �����������.
			ret

loc_MMKH_next_1:	cpi		OSRG,'F'
			brne		loc_MMKH_next_3		;��������� ������
			MENU_LOAD_POS	z			
			rcall		MenuGetType
			cpi		OSRG,ACTION_ITEM
			brne		loc_MMKH_next_6		;���� �� ACTION_ITEM, �� ������ ������� �� ���������� ����� ����
			MENU_LOAD_POS	z			;���� ������ ������ "�����" �� ������ ���� � ����� ACTION_ITEM
			rcall		MenuGetChild		;� Z - ����� �� ��������� ������ ��� ����� ������ ����
			sts		Action_Addrr,zl		;��������� � Action_Addrr ����� ����������� ������
			sts		Action_Addrr+1,zh
			STSI		Mode,m_Action		;���������� ����� Action
			SetTask		TS_Draw			; �������������� �����������.
			ret					;

loc_MMKH_next_6:	rcall		MenuMoveChild
			SetTask		TS_Draw			; �������������� �����������.
			ret

loc_MMKH_next_3:	cpi		OSRG,'U'
			brne		loc_MMKH_next_4		;��������� ������
			rcall		MenuMovePrevious
			SetTask		TS_Draw			; �������������� �����������.
			ret

loc_MMKH_next_4:	cpi		OSRG,'D'
			brne		loc_MMKH_next_5		;������ ������ ���, �������
			rcall		MenuMoveNext
			SetTask		TS_Draw			; �������������� �����������.
loc_MMKH_next_5:	ret



ActionModeKeysHandler:	lds		zl,Action_Addrr		;��������� � Z ����� ����������� ������ �������� Actiona
			lds		zh,Action_Addrr+1
			ijmp	
;-----------------------------------------------------------------------------
; ��������� ���������.
Terminal:		LDS		Counter,RX_CURR		; ����� � ������� ������� �������� ��������� ������� � �����������
			CPI		Counter,DWIDTH		; ���������� � ����� �����������
			BREQ		RX_OVF			; ���� ������������ �� ���� ���������� ���

Load_T:			LDZ		TextLine2		; ��������� � Z ����� ������ ������ �����������

			ADD		ZL,Counter		; ���������� ��� � �������� ����� �������
			ADC		ZH,Zero			; ��������� � ����� ����� ����������� ������ ������
	
			INC		Counter			; ����������� (�������� ������)
			STS		RX_CURR,Counter		; � ��������� ��� ��� ���

			LDS		OSRG,UDR_I		; �����, ������� ��, ������ ���������  �� UART

			ST		Z,OSRG			; ��������� �� � ����� ������ ��� ������.

			STSI	Mode,m_Terminal			; ���������� ����� "��������", ������� � ���������� ��������

			SetTask			TS_Draw		; ������ � ������� ������ �� ����������� ������
;			SetTimerTask	TS_SetDefMode,5000	; ����������� �� 5��� ����� ������ � ������.

			RET									

RX_OVF:			CLR		Counter			; ���������� ������� (������)
			RJMP		Load_T			; ������������ � ������ � �����������



;=============================================================================
; RTOS Here
;=============================================================================
; ��� ������� ����������� ������� � �������� �����. ������� ������ ���� ����������, �� �����
; �������� ������� ������ ��

			.include "kernel_def.asm"	; ���������� ��������� ����
			.include "kernel.asm"		; ���������� ���� ��
			.include "menu.asm"
			.include "actions.asm"
			.include "./Math/hex2ascii.asm"
			.include "./WH/lcd4.asm"
			.include "./Math/bin16bcd5.asm"
; ������� (������) �����.
			.equ TS_Idle 			= 0		 
			.equ TS_ScanADC		 	= 1		 
			.equ TS_Send 			= 2		 
			.equ TS_Fill	 		= 3		 
			.equ TS_Draw	 		= 4		
			.equ TS_SetDefMode		= 5		
			.equ TS_CheckADC	 	= 6		 
			.equ TS_Convert	 		= 7		
			.equ TS_ScanButtons		= 8		
			.equ TS_Terminal 		= 9
			.equ TS_ScanButtonsForPush	= 10
			.equ TS_ScanButtonsForPop	= 11
			.equ TS_IncClock		= 12

; � ��� �� ������ �� �����. �� ������� ����������� �������� � ������� ������� � ���������� 
; ������� � ������
TaskProcs: 		.dw Idle			; [00] 
			.dw ScanADC			; [01] 
			.dw Send			; [02] 
			.dw Fill			; [03] 
			.dw Draw 			; [04] 
			.dw SetDefMode			; [05] 
			.dw CheckADC			; [06] 
			.dw Convert			; [07] 
			.dw ScanButtons			; [08]
			.dw Terminal			; [09]
			.dw ScanButtonsForPush
			.dw ScanButtonsForPop
			.dw IncClock
; ���������� ���������� ������ � �������� � �������������� ������
;			.include "WH\lcd4.asm"

; ������ ������� ������. �� ��� �� ��������� ������� ��� ����, � �� ������� �� ������ - ������
; ��������. �.�. ������� ������� HD44780 � ASCII � ������� ����� �� ���������.
t_Normal1:		.db "  Normal mode   "
t_Normal2:		.db "     Page 1     "

t_Normal3:		.db "N o r m a l mode"
t_Normal4:		.db " * P a g e - 2 *"

t_Terminal:		.db	66,179,111,227,32,99,32,191,101,112,188,184,189,97,187,97

t_Button1:		.db 72,97,182,97,191,97,32,186,189,111,190,186,97,32,32,32
t_Button2:		.db 45,72,111,188,101,112,32,186,189,111,190,186,184,32,32,0

t_ADC1:			.db 65,225,168,44,32,186,97,189,97,187,32,48,32,32,32,32
t_ADC2:			.db 32,45,32,164,189,97,192,101,189,184,101,32,32,32

t_RootMenu_Cap:		.db	"     ROOT       "

t_Root_Item1_Cap:	.db	"1. Controls     "
t_Root_Item2_Cap:	.db	"2. Calibrate    "
t_Root_Item3_Cap:	.db	"3. Settings     "

t_Item11_Cap:		.db	"1.Pump On/Off   "
t_Item12_Cap:		.db	"2.Heater On/Off "
t_Item13_Cap:		.db	"3.Somebody OnOff"

t_Item21_Cap:		.db	"root it2 item1  "
t_Item22_Cap:		.db	"root it2 item2  "
t_Item23_Cap:		.db	"root it2 item3  "

t_Item31_Cap:		.db	"root it3 item1  "
t_Item32_Cap:		.db	"root it3 item2  "
t_Item33_Cap:		.db	"root it3 item3  "

t_Action1_l1:		.db	"Pump status:    " 
t_Action1_l2:		.db	"up=ON down=OFF  "

t_On:			.db	"ON "
t_Off:			.db	"OFF"

			.equ ROOT_ITEM=1
			.equ SUBITEM=2
			.equ ACTION_ITEM=3

;		  	TYPE,		PARENT,	CHILD,	PREV.,	NEXT,	CAPTION; TYPE=0-ROOT ITEM 1-SUBITEM 2-ACTION ITEM
MI1:	MENU_ITEM	ROOT_ITEM,	0,	MI11,	MI3,	MI2,	t_Root_Item1_Cap 
MI2:	MENU_ITEM	ROOT_ITEM,	0,	MI21,	MI1,	MI3,	t_Root_Item2_Cap 
MI3:	MENU_ITEM	ROOT_ITEM,	0,	MI31,	MI2,	MI1,	t_Root_Item3_Cap 

MI11:	MENU_ITEM	ACTION_ITEM,	MI1,	Action1_KeysHandler,	MI13,	MI12,	t_Item11_Cap
MI12:	MENU_ITEM	SUBITEM,	MI1,	MI12,	MI11,	MI13,	t_Item12_Cap
MI13:	MENU_ITEM	SUBITEM,	MI1,	MI13,	MI12,	MI11,	t_Item13_Cap

MI21:	MENU_ITEM	SUBITEM,	MI2,	MI21,	MI23,	MI22,	t_Item21_Cap
MI22:	MENU_ITEM	SUBITEM,	MI2,	MI22,	MI21,	MI23,	t_Item22_Cap
MI23:	MENU_ITEM	SUBITEM,	MI2,	MI23,	MI22,	MI21,	t_Item23_Cap

MI31:	MENU_ITEM	SUBITEM,	MI3,	MI31,	MI33,	MI32,	t_Item31_Cap
MI32:	MENU_ITEM	SUBITEM,	MI3,	MI32,	MI31,	MI33,	t_Item32_Cap
MI33:	MENU_ITEM	SUBITEM,	MI3,	MI33,	MI32,	MI31,	t_Item33_Cap
			