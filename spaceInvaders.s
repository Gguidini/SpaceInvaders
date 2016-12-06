###################################
# SPACE INVADERS - ASSEMBLY MIPS  #
###################################

.data 
FILE: 	.asciiz "space_open.bin"
LIT:	.asciiz "enter.bin"
LVL: 	.asciiz "lvl.bin"
SPRITE:	.asciiz "sprites.bin"
INIMIGO: .asciiz "inimigo.bin"
ENEMY:	.word 0xFF000F0A, 0xFF000F33, 0xFF000F5B, 0xFF000F83, 0xFF000FAB, 0xFF000FD3, 0xFF000FFB, 0xFF001023, 0xff00320a

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
	la $a0,FILE
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
	move $a0,$s1
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
############ ABRE A TELA INICIAL DE JOGO #####################################
# primeiro lê e mostra o background 
ABERTURA: 	la $a0, LVL
		jal ABRE
		move $s0, $v0 #salva file descriptor em $S0
		
	# mostrando background na tela 	
	move $a0,$s0
	la $a1,0xFF000000
	li $a2,76800
	li $v0,14
	syscall
	
	# fechando arquivo do background
	move $a0, $s0
	jal FECHA
	
	# consistency check				# remover depois
	li $a0, 2000
	jal SLEEP
### salvando o design dos inimigos pra stack
	# abre space na stack
	addi $sp, $sp, -880
	
	# abre o arquivo com os sprites
	la $a0, SPRITE
	jal ABRE
	move $s7, $v0 # salva file descriptor no $s7
	
	# lendo os arquivos na stack
	move $a0, $s7
	move $a1, $sp # conforme le aumenta os memory address, mas a stack diminui. Entao a imagem vai ficar invertida.
	li $a2,880 # bytes para leitura
	li $v0,14
	syscall
	
	#fechando o arquivo dos sprites
	move $a0, $s7
	jal FECHA
	
	# carregando positions iniciais dos inimigos e player
	addi $s6, $zero, 0xFF000000 # primeiro address da memoria VGA
	addi $s6, $s6, 64792 # primeiro address do player na tela
	
	la $s1, ENEMY # salva o address do vetor de inimigos em $s1
	li $t0, 3846
	addi $t0, $t0, 0xFF000000 # VGA address do primeiro inimigo
	li $t3, 8 # numero de inimigos por linha
	li $t2, 4 # linhas de inimigos
LINHA:	beq $t2, $zero, SAI # se encher todas as linhas, sai
	li $t1, 0 # vai incrementar em cada linha até virar 8
	
COLUNA: beq $t1, $t3, ADJUST #sai quando completar uma linha
	sw $t0, 0($s1) # salva endereço do inimigo
	addi $t0, $t0, 40 # address do proximo inimigo na linha
	addi $s1, $s1, 4 # proximo inteiro de enemy 
	addi $t1, $t1, 1 # incrementa contador
	j COLUNA
	
ADJUST: addi $t0, $t0, 20 # prepara pra proxima linha
	addi $t2, $t2, -1
	j LINHA

	# mostrar player e inimigos na tela
SAI:	jal MPLAYA #mostra player
	
	# abre arquivo com os sprites dos inimigos
	la $a0, INIMIGO
	jal ABRE
	move $s0, $v0
	# le os inimigos pra tela
	move $a0, $s0
	li $a1, 0xFF000000 # conforme le aumenta os memory address, mas a stack diminui. Entao a imagem vai ficar invertida.
	li $a2, 38400 # bytes para leitura
	li $v0,14
	syscall
	# fecha arquivo dos inimigos
	move $a0, $s0
	jal FECHA
	# para mostrar inimigos ler arquivo de inimigos começando na posição correta (which God knows what is)
	j FIM
############################################## FUNCTIONS #########################################################
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
	j ABERTURA	# vai pro começo do jogo... when ready. por enquanto encerra
PULA:	jr $ra

### Abre arquivos no meio do jogo
ABRE:	# colocar em $a0 o address do arquivo a ser lido
	li $a1,0
	li $a2,0
	li $v0,13
	syscall
	jr $ra
### Fecha arquivos no meio do jogo
FECHA: 	# colocar em $a0 o file descriptor
	li $v0,16
	syscall
	jr $ra
	
### mostrar o sprite do player
MPLAYA:	move $t4, $sp # guarda o endereço da stack em t4
	li $t6, 8 # sao 8 linhas
	li $t7, 5 #sao 5 words por linha do player
P:	lw $t8, 0($t4) # carrega primeiro word do sprite player
	sw $t8, 0($s6)
	addi $t4, $t4, 4 # proximo word do player
	addi $s6, $s6, 4 # proximo address para mostrar na tela
	addi $t7, $t7, -1 # diminui uma word
	bne $t7, $zero, P
	
	addi $s6, $s6, 300 # frist address, next line
	addi $t6, $t6, -1
	li $t7, 5
	bne $t6, $zero, P
	jr $ra
### Finaliza o programa		
FIM:	li $v0,10
	syscall
