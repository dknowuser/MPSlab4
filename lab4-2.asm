$MOD52

;"Бегущий огонь" реализован на выводах порта P1
; Слева-направо, горят 4 СИД
; Время свечения 0,5 с
; Режим 16-битного таймера
; Разрешение счёта обеспечивается битом GATE регистра TMOD
; INT0 - P3.2

LSB_POSITION EQU 30h
CALL_COUNT EQU 31h

CSEG
ORG 00h
	jmp initial_set_up; "Прыгаем" через таблицу векторов прерываний
	
ORG 03h
	mov P1, #55h
	reti

ORG 0Bh
	jmp timer0_handle

; Код настройки таймера T/C0 и соотвествующего прерывания
initial_set_up:
	;Стек растёт вверх - указатель указывает на первый байт после программы
	mov SP, #stack

	;Установка режима работы таймера T/C0
	mov TMOD, #01h
	
	;Устанавливаем высокий приоритет прерывания
	mov IP, #01h
	
	;Начальное значение таймера
	mov TL0, #0CFh
	mov TH0, #0CFh
	
	mov R0, #LSB_POSITION
	mov R1, #CALL_COUNT
	
	;Разрешение прерывания таймера T/C0
	mov IE, #83h	
	
	;Запуск таймера T/C0
	mov TCON, #10h
	
	;Конец основной программы
lp:
	jmp lp
	
timer0_handle:
	mov TCON, #00h; Запрещаем счёт
	
	push ACC
	push PSW

	;Перезагружаем значение таймера
	mov TL0, #0CFh
	mov TH0, #0CFh
	
	;Проверяем, сколько раз была вызвана подпрограмма
	mov A, @R1
	clr C
	subb A, #00h
	jz change
	inc @R1
	jmp handler_end

change:	
	mov @R1, #00h; Сбрасываем счётчик вызовов подпрограммы

	;Инкрементируем значение позиции младшего бита бегущего огня
	mov A, @R0
	clr C
	subb A, #07h
	jz loop_lsb_pos; Позиция младшего бита может лежать только в пределах от 0 до 7 
	inc @R0
	jmp switch
	
loop_lsb_pos:
	mov @R0, #00h
	
switch:
	;Ветвление в зависимости от позиции младшего бита бегущего огня	
	clr C
	mov A, @R0
	subb A,  #00h
	jz lsb_at_zero_pos
	
	clr C
	mov A, @R0
	subb A,  #01h
	jz lsb_at_first_pos
	
	clr C
	mov A, @R0
	subb A,  #02h
	jz lsb_at_second_pos
	
	clr C
	mov A, @R0
	subb A,  #03h
	jz lsb_at_third_pos
	
	clr C
	mov A, @R0
	subb A,  #04h
	jz lsb_at_fourth_pos
	
	clr C
	mov A, @R0
	subb A,  #05h
	jz lsb_at_fifth_pos
	
	clr C
	mov A, @R0
	subb A,  #06h
	jz lsb_at_sixth_pos
	
	clr C
	mov A, @R0
	subb A,  #07h
	jz lsb_at_seventh_pos	

	;В зависимости от полученного значения переключаем светодиоды
lsb_at_zero_pos:
	mov P1, #0Fh
	jmp handler_end
lsb_at_first_pos:
	mov P1, #87h
	jmp handler_end
lsb_at_second_pos:
	mov P1, #0C3h
	jmp handler_end
lsb_at_third_pos:
	mov P1, #0E1h
	jmp handler_end
lsb_at_fourth_pos:
	mov P1, #0F0h
	jmp handler_end
lsb_at_fifth_pos:
	mov P1, #78h
	jmp handler_end
lsb_at_sixth_pos:
	mov P1, #3Ch
	jmp handler_end
lsb_at_seventh_pos:
	mov P1, #1Eh
	
handler_end:
	;Приводим регистры в состояние до вызова обработчика прерывания
	pop PSW
	pop ACC
	
	mov TCON, #10h; Разрешаем счёт
	jmp timer0_handle

	reti;Выход из обработчика прерывания
	
stack:

END