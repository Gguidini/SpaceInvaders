.data

.text
	#a0: nota| a1: duracao| a2: instrumento| a3: volume
	
	#som de tiro do personagem

	li $a0, 67
	li $a1, 300
	li $a2, 127
	li $a3, 80
	li $v0, 33	#dar inicio a chamada de som, MIDI (espera o som terminar)
	syscall
	
	#som de explosão do personagem
	
	li $a0, 48
	li $a1, 420
	li $a2, 127
	li $a3, 120
	li $v0, 33	#dar inicio a chamada de som, MIDI (espera o som terminar)
	syscall
	
	#som explosão dos inimigos
	
	li $a0, 58
	li $a1, 250
	li $a2, 120
	li $a3, 100
	li $v0, 33	#dar inicio a chamada de som, MIDI (espera o som terminar)
	syscall

	#som tiro inimigo

	li $a0, 100
	li $a1, 250
	li $a2, 118
	li $a3, 80
	li $v0, 33	#dar inicio a chamada de som, MIDI (espera o som terminar)
	syscall
	
	#som de movimentação do personagem
	
	li $a0, 10
	li $a1, 200
	li $a2, 13
	li $a3, 80
	li $v0, 33	#dar inicio a chamada de som, MIDI (espera o som terminar)
	syscall