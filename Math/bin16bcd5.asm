

;*******************************************************************
;1. ����� ��������� "bin16BCD5"- �������������� 16-������� ���������
;�������� � ����������� BCD ������
;*******************************************************************
;* ���������� ���� ����            :25 + �������
;* ���������� ������               :25/176 (���/����) + �������
;* �������������� ������� �������� :���
;* �������������� ������� �������� :4(fbinL,fbinH/tBCD0,tBCD1,tBCD2)
;* �������������� ���������        :���
;*******************************************************************

;***** ����������� ���������� ������������

.def    fbinL   =r16            ;�������� ��������, ������� ����
.def    fbinH   =r17            ;�������� ��������, ������� ����
.def    tBCD0   =r17            ;BCD ��������, ����� 1 � 0
.def    tBCD1   =r18            ;BCD ��������, ����� 3 � 2
.def    tBCD2   =r19            ;BCD ��������, ����� 4
;����������: ���������� fbinH � tBCD0 ������ ����������� � �����
;��������.

;***** ���

bin16BCD5:
		ldi     tBCD2, -1
bin16BCD5_loop_1:
		inc     tBCD2
		subi    fbinL, low(10000)
		sbci    fbinH, high(10000)
		brsh    bin16BCD5_loop_1
		subi    fbinL, low(-10000)
		sbci    fbinH, high(-10000)
		ldi     tBCD1, -0x11
bin16BCD5_loop_2:
		subi    tBCD1, -0x10
		subi    fbinL, low(1000)
		sbci    fbinH, high(1000)
		brsh bin16BCD5_loop_2
		subi    fbinL, low(-1000)
		sbci    fbinH, high(-1000)
bin16BCD5_loop_3:
		inc     tBCD1
		subi    fbinL, low(100)
		sbci    fbinH, high(100)
		brsh bin16BCD5_loop_3
		subi    fbinL, -100
		ldi     tBCD0, -0x10
bin16BCD5_loop_4:
		subi    tBCD0, -0x10
		subi    fbinL, 10
		brsh bin16BCD5_loop_4
		subi    fbinL, -10
		add     tBCD0, fbinL
		ret


;������� 5 ascii �������� ����� tBCD0 tBCD1 tBCD2 � ������ �� ������ �� Z
;Z = ������� ������ �����, ... Z+4 = ������� ������
bcd52line:	
		mov	fbinL,tBCD2		;fbinL - ������� �������
		andi	fbinL,0x0f		;��������� ������ ��. ���� (������� �����)
		ori	fbinL,0x30		;�������� � ascii
		st	Z+,fbinL		;���������

		mov	fbinL,tBCD1		;
		lsr	fbinL			;����� �������� ������ �� ����� ������
		lsr	fbinL
		lsr	fbinL
		lsr	fbinL
		ori	fbinL,0x30		;�������� � ascii
		st	Z+,fbinL		;���������		

		mov	fbinL,tBCD1		;fbinL - ������� �������
		andi	fbinL,0x0f		;��������� ������ ��. ���� (�����)
		ori	fbinL,0x30		;�������� � ascii
		st	Z+,fbinL		;���������

		mov	fbinL,tBCD0		;
		lsr	fbinL			;����� �������� ������ �� ����� ������
		lsr	fbinL
		lsr	fbinL
		lsr	fbinL
		ori	fbinL,0x30		;�������� � ascii
		st	Z+,fbinL		;���������		

		mov	fbinL,tBCD0		;fbinL - ������� �������
		andi	fbinL,0x0f		;��������� ������ ��. ���� (�������)
		ori	fbinL,0x30		;�������� � ascii
		st	Z+,fbinL		;���������

		ret

