###################################
# SPACE INVADERS - ASSEMBLY MIPS  #
###################################

.data 
FILE: .asciiz "space_open.bin"
LIT:	.asciiz "enter.bin"

.text
########### ABRE A TELA DE INICIO #################
# Preenche a tela de preto	#aberto a modificações e melhorias. Ex: musica de entrada... frase de impacto
	li $t1,0xFF012C00	#last bitmap address
	li $s2,0xFF000000	#first bitmap address
	li $s1,0x00000000	# black, 4 bits
LOOP: 	beq $s2,$t1,FORA
	sw $s1,0($s2)
	addi $s2,$s2,4
	j LOOP
FORA:

# Abre o arquivo do space_open
ABRE:	la $a0,FILE
	li $a1,0
	li $a2,0
	li $v0,13
	syscall

	
# Le o arquivo para a memoria VGA
	move $a0,$v0
	la $a1,0xFF000000
	li $a2,76800
	li $v0,14
	syscall

#Fecha o arquivo
FECHA:	move $a0,$s1
	li $v0,16
	syscall
########### PISCA O ENTER E AGUARDA TECLA PARA INICIO ##############
# fazendo o ENTER piscar
TEC:	jal ECHO2	# pula pra ver checar o teclado

PISCA:	li $s1,0x00000000 # cor preta 4 bits
	li $s2,0xFF000000 # endereco video posicao 0,0
	addi $s2, $s2, 0xD4F0 # vai para o endereco inicial do enter
	addi $t1, $s2, 52 # endereço final da primeira linha do enter
	li $t7, 12 #numero de linhas
# apaga o ENTER colocando preto por cima
APAGA:	beq $s2,$t1, OK # preenche cada linha de preto
	sw $s1,0($s2)
	addi $s2,$s2,4
	j APAGA
	
OK:	addi $t7, $t7, -1 # uma linha concluida
	addi $s2, $s2, 268 # inicio prox linha
	addi $t1, $t1, 320 # fim prox linha
	bne $t7, $zero, APAGA #fica apagando enquanto houver linhas para serem apagadas
# acabou de apagar
	li $a0, 1000 # espera 1s depois de apagar	
	jal SLEEP
	jal ECHO2 # checa de novo se alguma tecla foi pressionada 
# preparando para colocar o enter de volta na tela
	li $s2,0xFF000000
	addi $s2, $s2, 0xD4F0	# primeiro address do ENTER

	# reabrindo o enter
	la $a0,LIT
	li $a1,0
	li $a2,0
	li $v0,13
	syscall
	
	#lendo linha por linha
	move $t7, $v0	#salva o file descriptor em $t7
	addi $t1, $zero, 12 # numero de linhas
		
FILL:	beq $t1, $zero, DONE #vai pra DONE quando todas as linhas forem lidas
	move $a0,$t7
	move $a1, $s2		
	li $a2,52
	li $v0,14 # syscall de ler do arquivo
	syscall
	addi $t1, $t1, -1 # prox linha
	addi $s2, $s2, 320 # primeiro address da prox linha
	j FILL
	
DONE:	#fecha o arquivo
	move $a0,$t7
	li $v0,16
	syscall				
	li $a0, 1000 # espera 1s depois do recolocar o ENTER 
	jal SLEEP
	j PISCA # faz todo o processo de novo
#facilitando a chamada do sleep. $a0 deve conter o delay em milissegundos
SLEEP:	li $v0, 32
	syscall
	jr $ra
	
### Apenas verifica se há tecla apertada
ECHO2:	la $t1,0xFF100000
	lw $t0,0($t1)
	andi $t0,$t0,0x0001		# Le bit de Controle Teclado
   	beq $t0,$zero,PULA   	   	# Se não há tecla pressionada PULA
  	lw $t2,4($t1)  		# Tecla lida
	j FIM	# vai pro começo do jogo... when ready. por enquanto encerra
PULA:	jr $ra

			
FIM:	li $v0,10
	syscall
