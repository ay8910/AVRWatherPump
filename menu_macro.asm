;TYPE,PARENT,CHILD,PREVIOUS,NEXT,CAPTION - АДРЕСА
;TYPE=0-ROOT ITEM 1-SUBITEM 2-ACTION ITEM
;
	.MACRO MENU_ITEM
	    .dw		@0	; 0-root item 1 -subitem 2-action item
	    .dw		@1	;parent item
	    .dw		@2	;child item	
	    .dw		@3	;previous item
	    .dw		@4	;next item
	    .dw		@5	;caption
	.ENDMACRO
	
	.MACRO MENU_LOAD_POS ;загузка в X Y Z текущего Menu_Pos
		lds		@0l,Menu_Pos
		lds		@0h,Menu_Pos+1
	.ENDMACRO