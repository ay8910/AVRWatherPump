; ��� ����� ������� ============================================================

; �������� ����� � ����
			.MACRO 	OUTI			; ��� �������� �������. ����� ��� outi ���������� � ����, �� ���������� �� 
			LDI 	R17,@1 			; ���� ����� ����, ������ @0,@1 ��� ���������, ��� ��������� ���������� �����������
			OUT 	@0,R17 			; �������. ������ ������ ���� �������� ��������� ����� ������� � ������� R16, � �� ���� 
			.ENDMACRO	


