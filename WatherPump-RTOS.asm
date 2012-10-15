			.include "/usr/share/avra/includes/m16def.inc"	; Используем ATMega16
			.include "kernel_def.asm"
			.include "define.asm"	; Наши все определения переменных тут
			.include "macro.asm"	; Все макросы у нас тут


;			.include "./Math/hex2ascii.asm"
			.include "kernel_macro.asm"
			.include "./WH/lcd4_macro.inc"

			.include "menu_macro.asm"

;============SSEG=============================================================
			.DSEG
Mode:		.byte					1		; Переменная режима отображения
;		
		.equ	m_Normal			=1		; Показ логотипа
		.equ	m_Terminal			=2		; Показ минитерминала
		.equ	m_ADC				=3		; Показ данных АЦП
		.equ	m_Button			=4		; Показ имени нажатой кнопки
		.equ	m_Menu				=5		; Показ меню
		.equ	m_Action			=6		; 
		
		.equ	btn_Times			=5		;количество циклов btn_Push_Pop_Delay, которое будет ожидаться отпускание кнопки в процедурах сканирования клавиатуры
		.equ	btn_Push_Pop_Delay		=200		;задержка в мс от обнаружения нажатия до начала обнаружения отпускания кнопки
		.equ	btn_Scan_Delay			=100		;интервал вызовов сканирования кнопок 
		.equ	ON_OFF_WIDTH			=3		;длина строки ON или OFF

BTN_PUSHED_CNT:	.byte					1		; счётчик кол-ва вызовов, которое будет ставить сама себя в очередь ф-я ScanButtonsForPop 
									; для обнаружения отпускания. Если за это кол-во вызовов ф-ии отпускание кнопки 
									; обнаружить не удалось, то предыдущее нажатие отменяется. Само кол-во задаётся в теле ScanButtonsForPop

ClockLow:	.byte					1		;
ClockHigh:	.byte					1		;

ADC_Data:	.byte					1		; Тут складируются данные АЦП
ADC_OLD:	.byte					1		; Тут хранится предыдущее значение данных АЦП

ADC_DIG0:	.byte					1		; В этих трех ячейках хранятся ASCII коды
ADC_DIG1:	.byte					1		; данных из АЦП, подготовленные к выводу на экран
ADC_DIG2:	.byte					1		; 

Pressed_B:	.byte					1		; В этой переменной хранится имя последней нажатой клавиши

UDR_I:		.byte					1		; Принятый байт 

BreakLoop:	.byte					3		; Байты выхода из цикла дисплея?

RX_CURR:	.byte					1		; Положение курсора терминала

TextLine1:	.byte					DWIDTH	; Видеопамять. Длина ее зависит от ширины экрана
TextLine2:	.byte					DWIDTH	; Ширина указана в lcd4_macro.inc, в самом конце.

ScrlBeg1:	.byte					0	; Позиция начала скролла в строке 1
ScrlEnd1:	.byte					15	; Позиция конца скролла в строке 1

ScrlBeg2:	.byte					0	; Позиция начала скролла в строке 2
ScrlEnd2:	.byte					15	; Позиция конца скролла в строке 2

;PWM_L_V:	.byte					1
;PWM_L_V2:	.byte					1

Menu_Pos:	.byte					2	;адрес выбранного в данный момент пункта меню, если 0000 - меню не активно
Action_Addrr:	.byte					2	;адрес выбранного в данный момент Actionа
Action_Draw_Addrr:	.byte				2	;адрес процедуры отрисовки экрана для текущего выбранного Actiona
;UART_Text:	.byte					10		; Буффер уарта. Не используется.

;bcd5:		.byte					5	; 5 разрядов десятичного числа для вывода его на экран мл.байт - мл.значащий разряд

; Очереди операционной системы
		.equ TaskQueueSize 			= 10		; Размер очереди задач
TaskQueue: 	.byte					TaskQueueSize 	; Адрес очереди задач в SRAM
			
		.equ TimersPoolSize 			= 10		; Количество таймеров
TimersPool:	.byte 					TimersPoolSize*3; Адреса информации о таймерах (очередь)


;===========CSEG==============================================================
			.cseg
			.include "vectors.asm"	; Все вектора прерываний спрятаны в этом файле

			
			.ORG	INT_VECTORS_SIZE		; Конец таблицы прерываний


;=============================================================================!
; Interrupts procs ===========================================================!
;=============================================================================!
; Output Compare 2 interrupt 
; Main Timer Service - Служба Таймеров Ядра РТОС - Обработчик прерывания

OutComp2Int:		push		OSRG
			in 		OSRG,SREG			; Save Sreg
			push 		OSRG				; Сохранение регистра OSRG и регистра состояния SREG
			push 		ZL	
			push 		ZH				; сохранение Регистра Z
			push 		Counter				; сохранение Регистра Counter
	
ocL01:			TimerService				; Служба таймера RTOS 

			pop 		Counter				; восстанавливаем переменные
			pop 		ZH
			pop 		ZL

			pop 		OSRG				; Восстанавливаем регистры
			out 		SREG,OSRG
			pop		OSRG

			
			
;			rcall		IncClock
			RETI					; выходим из прерывания
;.............................................................................

; Прерывание от АЦП. Мы тут ничего особого не делаем, только складываем данные
; в ячейку памяти ОЗУ
ADC_INT:		PUSH	OSRG				; Сохраняем рабчий регистр
	
			IN		OSRG,ADCH			; Берем данные из АЦП
			STS		ADC_Data,OSRG		; Перекладываем их в ОЗУ

			POP		OSRG				; Восстанавливаем рабочий регистр
			RETI						; Выход из прерывания


;.............................................................................

;Прерывания от пришедшего байта в UART
RX_OK:			reti			;отключено
			PUSH 	OSRG
			IN 		OSRG,SREG			; Save Sreg
			PUSH 	OSRG

			IN		OSRG,UDR
			STS		UDR_I,OSRG

			SetTask			TS_Terminal

			POP 	OSRG				; Восстанавливаем регистры
			OUT 	SREG,OSRG			; 
			POP 	OSRG
			RETI						; Выходим из прерывания


;=============================================================================!
; Main code ==================================================================!
;=============================================================================!
Reset:			OUTI 	SPL,low(RAMEND) 		; Первым делом инициализируем стек
			OUTI	SPH,High(RAMEND)								

			.include "init.asm"				; Все инициализации тут.


; Запуск фоновых процессов
Background:		rcall	ScanADC				; Сканирование АЦП
;			RCALL	Send				; Отсыл байт в UART 
			rcall	Fill				; Перерисовка экрана

;		RCALL	CheckADC			; Проверка показаний АЦП на изменение
			
;			RCALL	SetDefMode			; Сброс режима отображения в дефолтное состояние спустя какое то время
			rcall	MenuMoveBegin
			STSI	Mode,m_Normal			
			SetTask	TS_Draw	

			rcall	ScanButtonsForPush			; Сканирование кнопок.
			rcall	IncClock			; инкремент счётчика секунд

Main:			SEI				; Разрешаем прерывания.

			wdr				; Reset Watch DOG (Если не "погладить" "собаку". то она устроит конец света в виде 	; reset для процессора)
			rcall 	ProcessTaskQueue	; Обработка очереди процессов
			rcall 	Idle			; Простой Ядра
											
			rjmp 	Main			; Основной цикл микроядра РТОС



;=============================================================================
;Tasks
;=============================================================================
Idle:			RET					; Простой ядра. Не используется

IncClock:		SetTimerTask	TS_IncClock,1000	;увеличение системных часов (2 байта, секунды) 
			LDZ		ClockLow		;адрес мл. разряда - в Z
			ld		OSRG,Z			;мл.байт - в OSRG
			inc		OSRG			;увеличиваем мл.байт
			st		Z+,OSRG			;(Z) = OSRG, Z = Z + 1
			brne		icL0			;Branch if Z!=1
			ld		OSRG,Z
			inc		OSRG
			st		Z,OSRG			;
icL0:			ret

;-----------------------------------------------------------------------------
; Задача сканирования АЦП. Раз в 10мс запускается АЦП и берет значение.
ScanADC:	SetTimerTask	TS_ScanADC,10	; Самозацикливаем задачу через диспетчер таймера

			OUTI	ADCSRA,(1<<ADEN)|(1<<ADIE)|(1<<ADSC)|(1<<ADATE)|(3<<ADPS0)	; Запускаем ОДНОКРАТНОЕ Преобразование
			RET									; На этом задача завершена

;-----------------------------------------------------------------------------
; Задача отсылки данных через терминал. Раз в 50мс шлет байт который считало АЦП
Send:		SetTimerTask	TS_Send,50		; Самозацикливаем задачу через диспетчер таймеров

			LDS		OSRG,ADC_Data			; Загрузить байт из переменной ADC_DATA
			OUT		UDR,OSRG				; Отправить его через USART 
			RET
;-----------------------------------------------------------------------------
; Задача обновления экрана дисплея. Дисплей обновляется 5 раз в секунду, каждые 200мс
; данные берутся из видеопамяти и фоном записываются в контроллер HD44780
Fill:		SetTimerTask	TS_Fill,200		; Самозацикливание задачи через диспетчер таймеров

			LCDCLR				; Очистка дисплея

			LDZ	TextLine1		; Взять в индекс Z адрес начала видеопамяти
			ADIW	r24,0

			LDI	Counter,DWIDTH		; Загрузить счетчик числом символов в строке

Filling1:		LD	OSRG,Z+			; Брать последовательно байты из видеопамяти, увеличивая индекс Z
			RCALL	DATA_WR			; И передавать их дисплею

			DEC	Counter			; Уменьшить счетчик. 
			BRNE	Filling1		; Пока не будет 0 (строка не кончилась) - повторять

			LCD_COORD 0,1			; Как кончится строка - перевести строку в дисплее

			LDI	Counter,DWIDTH	; Опять загрузить длинной строки

Filling2:		LD	OSRG,Z+			; Адрес второй строки видеопамяти указывать не надо - они идут друг за другом 
			RCALL	DATA_WR			; И таким же макаром залить вторую строку из видеопамяти

			DEC	Counter			; Уменьшаем счетчик
			BRNE	Filling2		; Если строка не кончилась - продолжаем.
	
			RET
;-----------------------------------------------------------------------------
; Задача скроллинга строки.Номер строки - в Z
; 
Scroll:			LDZ	TextLine1
			ret


;-----------------------------------------------------------------------------
; Это функция рисования в видеопамять. Работает в зависимости от режима отображения
; Разбита на секции f_Button, f_Normal, f_Terminal, f_ADC по секции на режим. Выход из 
; задачи DRAW по RET в конце каждой секции.

Draw:			LDS	OSRG,Mode		; Берем текущее значение режима

			CPI	OSRG,m_Normal		; И определяем какое из
			BREQ	f_Normal		; Если Нормальный режим - переходим к нему

;			CPI	OSRG,m_Terminal		; Если термниальный - то в секцию терминала
;			BREQ	f_Terminal
			
			cpi	OSRG,m_Menu
			breq	f_Menu

			CPI	OSRG,m_ADC		; Аналогично, но в секцию АЦП
;			BREQ	f_ADC

			cpi	OSRG,m_Action
			breq	f_Action

			ret

;..............................................................................
; Нормальный режим. В этом режиме. На экран выводится логтип платы. Просто берется как есть из флеша
f_Normal:
;f_Menu:
			LDI		Counter,DWIDTH		; Скопировать в первую строку видеопамяти надпись "Pinboard v1.0"
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
;			LDI		Counter,5		; Скопировать во вторую строку видеопамяти надпись "by DI HALT 2009"
;			LDZ		t_Normal2*2		; Строки эти располагаются в конце программы. 
;			LDY		TextLine2
;			RCALL		CopySTR
	
			RET

;f_Normal:
f_Menu:			MENU_LOAD_POS	Z			;загружаем в Z текущее положение в меню
			rcall		MenuGetType		;тип текущего пункта меню - в OSRG
			cpi		OSRG,ROOT_ITEM
			brne		loc_menu_2		;проверяем - РУТ или нет
			LDZ		t_RootMenu_Cap*2	;если РУТ, то в z загружаем адрес заголовка рутового раздела меню
			rjmp		loc_menu_1
loc_menu_2:		MENU_LOAD_POS	Z			;если НЕ РУТ, то восстанавливаем в Z текущюю позицию в меню
			rcall		MenuGetParent		;и получаем заголовок родительского пункта для вывода 
			rcall		MenuGetCaption		;в 1ю строку индикатора
			MUL2		Z			;умножаем на 2 т.к. в структуре меню адреса в словах,
loc_menu_1:		LDI		Counter,DWIDTH		;а для ф-ии CopySTR нужен адрес в байтах
			LDY		TextLine1		;в Y - адрес буфера в ОЗУ
			RCALL		CopySTR			

			MENU_LOAD_POS	Z			;строка 2 индикатора. Восстанавливаем позицию в меню
			rcall 		MenuGetCaption		;получаем адрес строки с названием пункта меню в словах
			MUL2		Z			;преобразуем в байты для ф-ии CopySTR
			LDI		Counter,DWIDTH
			LDY		TextLine2
			RCALL		CopySTR

			ret

f_Action:		lds		zl,Action_Addrr		;загружаем в Z адрес обработчика кнопок текущего Actiona
			lds		zh,Action_Addrr+1
			adiw		zl,1			;следующее слово - обработчик экрана этого Actiona
			ijmp					;вызов обработчика
			ret

;.............................................................................
; Отображение терминала. Тут мы копируем из флеша в видеопамять только первую строку. Вторую
; строку нам нарисует обработчик прерывания от UART
;f_Terminal: 		LDI		Counter,DWIDTH		; 
;			LDZ		t_Terminal*2
;			LDY		TextLine1
;			RCALL		CopySTR
	
;			RET
;.............................................................................
; Отображение режима АЦП. 
f_ADC:			LDI		Counter,DWIDTH			; Вначале берем значение ширины видеопамяти
			LDZ		t_ADC1*2		; Потом берем из флеша первую строку и тупо копируем
			LDY		TextLine1		; Ее в первую строку видеопамяти.
			RCALL		CopySTR
			
			LDS		OSRG,ADC_DIG2		; Во вторую строку мы вначале вписываем значения цифр
			STS		TextLine2,OSRG		; которые сформирует нам задача Convert 

			LDS		OSRG,ADC_DIG1		; Это величина снятая с АЦП. Обрати внимание, что байты
			STS		TextLine2+1,OSRG	; Заносятся просто смещением от начала второй строки видеопамяти
			
			LDS		OSRG,ADC_DIG0
			STS		TextLine2+2,OSRG

			LDI		Counter,DWIDTH-3	; А потом, забиваем наш статичный текст. Строка "- значение"
			LDZ		t_ADC2*2			; Т.к. три символа мы уже написали, то счетчик сразу уменьшим на 3
			LDY		TextLine2+3
			RCALL		CopySTR
			

EX_F:			RET					; Выход из задачи



CopySTR:		LPM		OSRG,Z+			; Процедура копирования из флеша в ОЗУ
			ST		Y+,OSRG			; Берет байт по индексу Z и грузит его в ячейки
			DEC		Counter			; По индексу Y. При этом автоматом инкрементируется индекс
			BRNE		CopySTR			; И вручную счетчик байтов в регистре Counter 
			RET

;-----------------------------------------------------------------------------
; ЗАдача сброса в дефолт спустя 5 секунд бездействия
SetDefMode:		
;			SetTimerTask	TS_SetDefMode,5000 		; Самозацикливание задачи через диспетчер таймеров
			STSI	Mode,m_Normal				; Сброс режима в 0 - нормальный режим, показ заставки
			SetTask	TS_Draw					; Постановка на конвеер задачи перерисовки экрана
			RET
;-----------------------------------------------------------------------------

; Задача проверки состояния значений АЦП - не изменились ли?
CheckADC:	SetTimerTask	TS_CheckADC,100		; Вначале самозациклимся на 100мс

			LDS		OSRG,ADC_OLD				; Берем предыдущее значение АЦП
			LDS		ACC,ADC_DATA				; Берем последнее значение АЦП

			ANDI		ACC,0b11110000				; Отрезаем вечно меняющиеся младшие биты. Нам нужны только крупные изменения
			STS		ADC_OLD,ACC				; И текущее обрезанное значение записываем в старое значение

			CP		ACC,OSRG				; Сравниваем текущее значение с заранее взятым старым.

			BREQ		EX_CA					; Если значение не изменилось, то выходим.	

			SetTask		TS_Convert				; А если изменилось, то запускаем задачу конвертации показаний АЦП

EX_CA:			RET
;-----------------------------------------------------------------------------
; Эта задача берет байт показаний АЦП и превращает его в три байта ASCII кодов пригодных для вывода на дисплей
Convert:		LDS		R16,ADC_DATA		; Берем то самое значение

			RCALL		Hex2Ascii		; Вызываем функцию конвертации (она в файле Math\hex2ascii.asm)
			
			STS		ADC_DIG0,R16		; И результат нычим в переменные разрядов, которые потом загребет
			STS		ADC_DIG1,R17		; задача DRAW
			STS		ADC_DIG2,R18

			STSI		Mode,m_ADC		; Попутно обьявим что на ближайшие 2секунды у нас режим АЦП

;			SetTimerTask	TS_SetDefMode,2000	; отложим сброс в дефолтный режим
			SetTask		TS_Draw			; И вызовем через диспетчер обновление видеопамяти

			RET


;первоначальное сканирование кнопок на нажатие. При обнаружении нажатия в очередь с задержкой ставится задача 
;обнаружения отпускания (для устранения дребезга)
ScanButtonsForPush:
			rcall 		ScanButtons
			cpi		OSRG,0				
			brne		loc_pressed_1
			SetTimerTask	TS_ScanButtonsForPush,btn_Scan_Delay	; Если ни одна кнопка не нажата, то снова ставим в очередь задач ScanButtonsForPush  
			ret

loc_pressed_1:		
			sts		Pressed_B,OSRG					; А если нажата, то сохраняем букву кнопки в ОЗУ
			SetTimerFirstTask	TS_ScanButtonsForPop,btn_Push_Pop_Delay		; ставим в очередь задачу ожидания отпускания кнопки через btn_Push_Pop_Delay мс 
			ret

;вторая часть алгоритма сканирования кнопок - ожидание отпускания кнопки.
ScanButtonsForPop:	
			rcall		ScanButtons
			cpi		OSRG,0
			brne		loc_not_released1

			SetTimerTask	TS_ScanButtonsForPush,btn_Scan_Delay	;итак, кнопка отпущена, первым делом назначаем новое сканирование клавиш через btn_Scan_Delay мс
			rcall 		ProcessKeyStroke
			SetTimerTask	TS_ScanButtonsForPush,btn_Scan_Delay
			ret
			
loc_not_released1:	SetTimerTask	TS_ScanButtonsForPop,btn_Push_Pop_Delay	;ещё один цикл ожидания отпускания кнопки если кнопка отпущена не была
			ret

;просто сканирует кнопки, возвращая в OSRG букву нажатой кнопки, или 0, если не нажато ни одной. Используется только из ScanButtonsForPop и
;ScanButtonsForPush, которые защищают от дребезга.
ScanButtons:
			clr		osrg

			sbis		BTD_N,BTD		; И проверяем биты кнопок
			ldi		OSRG,'F'		; Если нажата кнопка, то записываем в OSRG

			sbis		BTA_N,BTA		; И проверяем биты кнопок
			ldi		OSRG,'U'		; Если нажата кнопка, то записываем в OSRG

			sbis		BTB_N,BTB
			ldi		OSRG,'B'

			sbis		BTC_N,BTC
			ldi		OSRG,'D'
			
			ret

;Диспетчер кода нажатой кнопки: вызывает NormalModeKeysHandler, MenuModeKeysHandler или ActionModeKeysHandler
;в зависимости от активного в данный момент режима дисплея
ProcessKeyStroke:	SetTimerTask	TS_SetDefMode,60000
			lds		acc,Mode
			cpi		acc,m_Normal		;Обычный режим?
			brne		loc_sb_not_normal	;нет - переход
			rcall		NormalModeKeysHandler
			ret

loc_sb_not_normal:	cpi		acc,m_Menu		;Режим меню?
			brne		loc_sb_not_menu		;нет - переходим
			rcall		MenuModeKeysHandler	
			ret

loc_sb_not_menu:	cpi		acc,m_Action		;Action-режим?
			brne		loc_sb_not_action		;нет - переходим
			rcall		ActionModeKeysHandler	
loc_sb_not_action:	ret
			



NormalModeKeysHandler:	
			lds		OSRG,Pressed_B
			cpi		OSRG,'B'
			brne		loc_no_menu		;переход, если нажата не клавиша "назад"
			
			STSI		Mode,m_Menu		;выставляем режим "Меню"
			rcall		MenuMoveBegin
			SetTask		TS_Draw			; Перерисовываем видеопамять.
loc_no_menu:		ret


MenuModeKeysHandler:	
			lds		OSRG,Pressed_B
			cpi		OSRG,'B'
			brne		loc_MMKH_next_1		;следующая кнопка
			MENU_LOAD_POS	z			;в Z - текущая позиция в меню
			rcall 		MenuGetType		;нажата кнопка "Назад", получаем в OSRG тип текущего пункта меню
			cpi		OSRG,ROOT_ITEM		;текущий пункт меню корневой?
			brne		loc_MMKH_next_2		;нет, не корневой

;			SetTimerTask	SetDefMode,5
			STSI		Mode,m_Normal		;а если корневой, выставляем нормальный режим
			SetTask		TS_Draw			; Перерисовываем видеопамять.
			ret
loc_MMKH_next_2:						;сюда попадаем, если нажата кнопка "Назад" и текущий пункт меню НЕ корневой
			rcall		MenuMoveParent
			SetTask		TS_Draw			; Перерисовываем видеопамять.
			ret

loc_MMKH_next_1:	cpi		OSRG,'F'
			brne		loc_MMKH_next_3		;следующая кнопка
			MENU_LOAD_POS	z			
			rcall		MenuGetType
			cpi		OSRG,ACTION_ITEM
			brne		loc_MMKH_next_6		;если НЕ ACTION_ITEM, то просто переход на подчинённый пункт меню
			MENU_LOAD_POS	z			;если нажата кнопка "Вперёд" на пункте меню с типом ACTION_ITEM
			rcall		MenuGetChild		;в Z - адрес пп обработки кнопок для этого пункта меню
			sts		Action_Addrr,zl		;сохраняем в Action_Addrr адрес обработчика кнопок
			sts		Action_Addrr+1,zh
			STSI		Mode,m_Action		;выставляем режим Action
			SetTask		TS_Draw			; Перерисовываем видеопамять.
			ret					;

loc_MMKH_next_6:	rcall		MenuMoveChild
			SetTask		TS_Draw			; Перерисовываем видеопамять.
			ret

loc_MMKH_next_3:	cpi		OSRG,'U'
			brne		loc_MMKH_next_4		;следующая кнопка
			rcall		MenuMovePrevious
			SetTask		TS_Draw			; Перерисовываем видеопамять.
			ret

loc_MMKH_next_4:	cpi		OSRG,'D'
			brne		loc_MMKH_next_5		;больше кнопок нет, выходим
			rcall		MenuMoveNext
			SetTask		TS_Draw			; Перерисовываем видеопамять.
loc_MMKH_next_5:	ret



ActionModeKeysHandler:	lds		zl,Action_Addrr		;загружаем в Z адрес обработчика кнопок текущего Actiona
			lds		zh,Action_Addrr+1
			ijmp	
;-----------------------------------------------------------------------------
; Обработка терминала.
Terminal:		LDS		Counter,RX_CURR		; Берем в Каунтер текущее значение положения курсора в видеопамяти
			CPI		Counter,DWIDTH		; Сравниваем с краем видеопамяти
			BREQ		RX_OVF			; Если переполнение то идем исправлять его

Load_T:			LDZ		TextLine2		; Загружаем в Z адрес второй строки видеопамяти

			ADD		ZL,Counter		; Складываем его с курсором таким образом
			ADC		ZH,Zero			; вычисляем в какое место видеопамяти писать символ
	
			INC		Counter			; Увеличиваем (сдвигаем курсор)
			STS		RX_CURR,Counter		; И сохраняем его где был

			LDS		OSRG,UDR_I		; Берем, Наконец то, данные пришедшие  из UART

			ST		Z,OSRG			; Сохраняем их в видео памяти где курсор.

			STSI	Mode,m_Terminal			; Выставляем режим "терминал", записав в переменную значение

			SetTask			TS_Draw		; Ставим в очередь задачу на перерисовку экрана
;			SetTimerTask	TS_SetDefMode,5000	; Откладываем на 5сек сброс режима в Нормал.

			RET									

RX_OVF:			CLR		Counter			; Сбрасываем счетчик (курсор)
			RJMP		Load_T			; Возвращаемся к печати в видеопамять



;=============================================================================
; RTOS Here
;=============================================================================
; Это область определения адресов и индексов задач. Порядок должен быть одинаковым, от этого
; критично зависит работа ОС

			.include "kernel_def.asm"	; Подключаем настройки ядра
			.include "kernel.asm"		; Подклчюаем ядро ОС
			.include "menu.asm"
			.include "actions.asm"
			.include "./Math/hex2ascii.asm"
			.include "./WH/lcd4.asm"
			.include "./Math/bin16bcd5.asm"
; Индексы (номера) задач.
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

; А это их адреса во флеше. ПО индексу вычисляется смещение в таблице адресов и происходит 
; Переход к задаче
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
; Подключены библиотеки работы с дисплеем и преобразования всякие
;			.include "WH\lcd4.asm"

; Тексты режимов работы. Те что по английски пишутся как есть, а те которые по русски - кодами
; символов. Т.к. кодовая таблица HD44780 и ASCII в русском языке не совпадают.
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
			