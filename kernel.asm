EEPROMRead:
ERL01:		sbic	EECR,EEWE	;if EEWE not clear
		rjmp	ERL01		; wait more 

		out	EEARH, ZH	;output address 
		out	EEARL, ZL	;output address 

		sbi	EECR, EERE	;set EEPROM Read strobe
		in	OSRG, EEDR	;get data
		ret
	
EEPROMWrite:
EWL01:		sbic	EECR,EEWE	;if EEWE not clear
		rjmp	EWL01		;    wait more
	
		out	EEARH, ZH	
		out	EEARL, ZL	

		out	EEDR,OSRG	;output data
		sbi	EECR,EEMWE	;set EEPROM Master Write Enable
		sbi	EECR,EEWE	;set EEPROM Write strobe
		ret

ClearTaskQueue:
		push ZL
		push ZH

		ldi ZL, low(TaskQueue)
		ldi ZH, high(TaskQueue)

		ldi OSRG, $FF		
		ldi Counter, TaskQueueSize

CEQL01: 	st Z+, OSRG		;
		dec Counter		;
		brne CEQL01		; Loop

		pop ZH
		pop ZL
		ret
	
ClearTimers:
		push ZL
		push ZH

		ldi ZL, low(TimersPool)
		ldi ZH, high(TimersPool)

		ldi Counter, TimersPoolSize
		ldi OSRG, $FF		; Empty 
		ldi Tmp2, $00

CTL01:		st Z+, OSRG		; Event
		st Z+, Tmp2		; Counter Lo
		st Z+, Tmp2		; Counter Hi

		dec Counter		;
		brne CTL01		; Loop
	
		pop ZH
		pop ZL
		ret	
;------------------------------------------------------------------------------
; Процедура выполнения задач из очереди TaskQueue
; выполняется в бесконечном цикле Main

ProcessTaskQueue:
		ldi ZL, low(TaskQueue)
		ldi ZH, high(TaskQueue)

		ld 	OSRG, Z				; В OSRG - номер 1й задачи из очереди
		cpi	OSRG, $FF			; FF - конец очереди (нет задач на выполнение??)
		breq	PTQL02				; возврат
	
		clr 	ZH				;очищаем старшую половину Z
		lsl 	OSRG				;умножаем номер задачи на 2 (так как номер задачи = смещению в таблице, а смещение в словах в 2 раза меньше, чем в байтах)
		mov 	ZL, OSRG			;в мл. половине Z - смещение в байтах

		subi 	ZL, low(-TaskProcs*2)		;складываем это смещение с началом таблицы задач, также умноженным на 2
		sbci 	ZH, high(-TaskProcs*2)  	; 
	
		lpm					; через r0 загружаем адрес задачи,
		mov 	OSRG, r0
		ld 	r0, Z+				; который попадает
		lpm	
		mov 	ZL, OSRG			; в конце концов в Z
		mov 	ZH, r0
	
		push 	ZL				; сохраняем полученный адрес на стеке
		push 	ZH

							; после того, как адрес задачи для выполнения получен сдвигаем очередь 
		ldi 	Counter, TaskQueueSize-1	; началом на номер этой задачи
		ldi 	ZL, low(TaskQueue)		; в Z - адрес очереди
		ldi 	ZH, high(TaskQueue)		; в Counter - длина очереди, уменьшенная на 1
	
		cli					; прерывания запрещены
	
PTQL01:		ldd 	OSRG, Z+1 			; в OSRG - номер следующей задачи в очереди
		st 	Z+, OSRG			; сохраняем номер следующей задачи в текущем адресе очереди
;		cpi OSRG, $FF		;
;		breq PTQL02		; For Long Queues
		dec 	Counter				;
		brne 	PTQL01				; цикл по счётчику в Counter 
		ldi 	OSRG, $FF			; в конец очереди вставляем FF
		st 	Z+, OSRG			; в конец очереди вставляем FF
	
		sei					; разрешаем прерывания

		pop 	ZH				; восстанавливаем сохранённый перед сдвигом очереди адрес 
		pop 	ZL				; задачи в Z

		ijmp 					; и переходим по этому адресу в Z
	
PTQL02:		ret	


;-------------------------------------------------------------------------
; ставит задачу с номером в OSRG в конец очереди TaskQueue 
SendTask:
		push ZL
		push ZH
		push Tmp2
		push Counter

		ldi ZL, low(TaskQueue)
		ldi ZH, high(TaskQueue)

		ldi Counter, TaskQueueSize

SEQL01: 	ld Tmp2, Z+

		cpi Tmp2, $FF
		breq SEQL02

		dec Counter		;
		breq SEQL03		; Loop
		rjmp SEQL01

SEQL02: 	st -Z, OSRG		; Store EVENT



SEQL03:					; EXIT
		pop Counter
		pop Tmp2
		pop ZH
		pop ZL
		ret	


;------------------------------------------------------------------------	
; Ставит задачу с номером из OSRG в первую позицию очереди с задержкой запуска, заданной в Х
; Для этого сначала сдвигает очередь, устанавливая первым байтом очереди номер задачи из OSRG, а потом просто вызывает SetTimer, 
; чтобы тот установил нужное время задержки
; OSRG - Timer Event (номер задачи)
; X - Counter	(задержка в кол-ве прерываний)
SetTimerFirst:
			ldi 	ZL, low(TimersPool)		;в Z - адрес очереди задач с задержками выполнения
			ldi 	ZH, high(TimersPool)
			ldi 	Counter, TimersPoolSize

stfL02: 		ld 	Tmp2, Z						; проверяем - совпадает ли номер задачи, переданной в к-ве параметра
			cp 	Tmp2, OSRG					; с номером задачи, на который указывает в текущий момент Z
			breq 	stfL03						; если номера совпадают - переход на установку в эту позицию FF т.к. эта задача 
										; будет поставлена на 1е место в очереди
			clc
			subi 	ZL, Low(-3)					; если номера НЕ совпадают, то пропускаем значение задержки
			sbci 	ZH, High(-3)					; в очереди для перехода к следующему номеру задачи

			dec 	Counter						;
			breq 	stfL04						; выход из цикла если задач с таким номером не найдено на сдвиг очереди
			rjmp 	stfL02						; продолжаем цикл для следующей позиции

stfL03:			ldi	Tmp2,255					; 
			st	Z,Tmp2

stfL04:			ldi ZL, low(TimersPool+TimersPoolSize*3-3)		;в Z - адрес предпоследнего элемента очереди задач с задержками выполнения
			ldi ZH, high(TimersPool+TimersPoolSize*3-3)
			ldi Counter, TimersPoolSize-3

stfL01:			ld	Tmp2,Z
			std	Z+3,Tmp2
			clc
			subi 	ZL,1
			sbci 	ZH,1
			dec 	Counter						; сдвигаем очередь 
			brne	stfL01
	
			st	Z,OSRG						; в 1й байт очереди ставим номер задачи, после этого вызывается SetTimer, 
			rcall	SetTimer					; который установит нужное к-во циклов задержки для этой задачи
			ret

;------------------------------------------------------------------------	
; Ставит задачу с номером из OSRG в очередь с задержкой запуска, заданной в Х
; OSRG - Timer Event (номер задачи)
; X - Counter	(задержка в кол-ве прерываний)
SetTimer:
;		push ZL
;		push ZH
;		push Tmp2
;		push Counter

		ldi ZL, low(TimersPool)		;в Z - адрес очереди задач с задержками выполнения
		ldi ZH, high(TimersPool)

		ldi Counter, TimersPoolSize
	
STL01: 		ld Tmp2, Z			; проверяем - совпадает ли номер задачи, переданной в к-ве параметра
		cp Tmp2, OSRG			; с номером задачи, на который указывает в текущий момент Z
		breq STL02			; если номера совпадают - переход
	
		clc
		subi ZL, Low(-3)		; если номера НЕ совпадают, то пропускаем значение задержки
		sbci ZH, High(-3)		; в очереди для перехода к следующему номеру задачи

		dec Counter			;
		breq STL03			; Loop
		rjmp STL01
	
STL02:		;cli				;если номер задачи, переданный в к-ве аргумента уже есть в очереди, то просто ставим ему в очереди новое значение задержки
		std Z+1, XL			; Critical Section
		std Z+2, XH			; Update Counter
		;sei				; leave Critical Section
		rjmp	STL06			; Exit

STL03:		ldi ZL, low(TimersPool)		;в Z - адрес очереди задач с задержками выполнения
		ldi ZH, high(TimersPool)
		ldi Counter, TimersPoolSize
	
STL04:		ld Tmp2, Z			; Проверяем содержимое памяти по адресу в Z на равенство FF
		cpi Tmp2, $FF			; Search for Empty Timer
		breq STL05			; если FF, то переходим 
	
		subi ZL, Low(-3)		; если НЕ FF, то переходим к следующему элементу очереди
		sbci ZH, High(-3)		; 

		dec Counter			; уменьшаем счетчик 
		breq STL06			; а вот если он =0, то задача в очередь поставлена не будет (очередь переполнена)
		rjmp STL04
	
STL05:		cli
		st Z, OSRG			; по адресу из Z лежит FF - значит по адресу в Z пишем номер постанавливаемой в очередь задачи 
		std Z+1, XL			; и далее - счётчик задержки
		std Z+2, XH
		sei

STL06:
;		pop Counter
;		pop Tmp2
;		pop ZH
;		pop ZL
		ret	


RAND:	
;		ldi OSRG, 17		; MUL RND,17
;		clr Tmp2
;MULLoop:add Tmp2, RND
;		dec OSRG
;		brne MULLoop		; 4

		mov	Tmp2, RND	; x1
		lsl	Tmp2		; x2
		lsl	Tmp2		; x4
		lsl	Tmp2		; x8
		lsl	Tmp2		; x16
		add	Tmp2, RND	; x(16+1) = 0b00010001

	
		subi Tmp2, -53	; -(-53) = +53
		mov RND,Tmp2	; RND = (RNDi * 17 + 53) {MOD 256}
		ret

;===========================================================================
;RAM 	Lib
;===========================================================================

SaveRAM:	PUSH	ZH
		PUSH	ZL
			
		MOV		ZH,OSRG
		MOV		ZL,OSRG

		POP		ZL


