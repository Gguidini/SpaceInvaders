###################################
# SPACE INVADERS - ASSEMBLY MIPS  #
###################################
.eqv maskD 100
.eqv maskA 97
.eqv maskSPACE 32
.eqv maskBLACK 0x00000000
.eqv shLimit 0xff000140
.eqv maskENEMY1 0xFBFBFBFB
.eqv maskENEMY2 0x000000FB
.eqv maskENEMY3 0xFB000000
.eqv maskENEMY4 0x00FB0000
.eqv maskENEMY5 0x0000FB00
.eqv flagENEMY 0x01010101

.eqv maskPLAYA1 0x4f4f4f4f
.eqv maskPLAYA2 0x0000004f
.eqv maskPLAYA3 0x4f000000
.eqv maskPLAYA4 0x004f0000
.eqv maskPLAYA5 0x00004f00

.eqv maskBARRIER1 0x37000000
.eqv maskBARRIER2 0x00000037

.data 
FILE: 	.asciiz "space_open.bin"
LIT:	.asciiz "enter.bin"
LVL: 	.asciiz "lvl.bin"
SPRITE:	.asciiz "sprites.bin"
INIMIGO: .asciiz "inimigo.bin"
GAMEOVER: .asciiz "gameover.bin"

ESHOT: .word 0, 0, 0, 0, 0
PSHOT:	.word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
INI: .word 0xFF000F04, 32

LIVES: .word 3
SCORE: .word 0
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
	

	# mostrar player e inimigos na tela
	jal MPLAYA #mostra player
	
	# abre arquivo com os sprites dos inimigos
	la $a0, INIMIGO
	jal ABRE
	move $s0, $v0
	# le os inimigos pra tela
	jal MENEMY
	# fecha arquivo dos inimigos
	move $a0, $s0
	jal FECHA
	
	la $s1, INI		#inicializa inimigos na posiçao correta
	li $t0, 0xFF000F04
	li $t1, 32
	sw $t0, 0($s1)
	sw $t1, 4($s1)
	# setting flags dos inimigos
	la $s1, INI # salva o address do vetor INI em $s1
	lw $t0, 0($s1) # address do inimigo 1
	li $t4, flagENEMY
	li $t3, 8 # numero de inimigos por linha
	li $t2, 4 # linhas de inimigos
LINHA:	beq $t2, $zero, SAI # se encher todas as linhas, sai
	li $t1, 0 # vai incrementar em cada linha até virar 8
	
COLUNA: beq $t1, $t3, ADJUST #sai quando completar uma linha
	sw $t4, 0($t0) # salva flag pro prox inimigo
	addi $t0, $t0, 40 # address do proximo inimigo na linha
	addi $t1, $t1, 1 # incrementa contador
	j COLUNA
	
ADJUST: addi $t0, $t0, 8640 # prepara pra proxima linha
	addi $t2, $t2, -1
	j LINHA

SAI:
	
	# mexendo o player
	#################################################################### AGORA A COISA RODA ####################

RESET:	li $s7, 0
	j CHECK
	
CHECK:	
	jal ECHO # ve se alguma tecla foi teclada
	jal MS # move tiros
	li $a0, 2000
	jal SLEEP
	move $s5, $t2 # salva a tecla em $s5
	move $a0, $s6 # salva onde o player esta em $a0
	beq $s5, maskA, ESQUERDA
	beq $s5, maskD, DIREITA
	beq $s5, maskSPACE, SHOOT
	jal MS # move tiros
	li $a0, 2000
	jal SLEEP
	j FOE
	
FOE:	# contador em $s7
	
	# vamos ver se algum inimigo atira
	li $a0, 0 	# nao sei o q isso faz
	li $a1, 10	# maior possibilidade de retorno
	li $v0, 42 	# syscall para gerar numeros aleatorios
	syscall
	
	slti $a0, $a0, 2 # chance de menos de 20% de sair um tiro inimigo
	beq $a0, 1, EFIRE
	li $a0, 2000
	jal SLEEP
EFIREBACK:	
	
	jal MES
	li $a0, 2000
	jal SLEEP
	# o andamento dos inimigos eh controlado por um ciclo. Eles andam a cada 5 movimentaçoes do player. 
	beq $s7, 0, M0
	beq $s7, 10, M1
	beq $s7, 20, M2
	beq $s7, 30, M3
	addi $s7, $s7, 1
	
	jal MES
	li $a0, 2000
	jal SLEEP
	j CHECK
	
	
M0:	jal MOVE_LINHA_DIREITA
	li $a0, 1000
	jal SLEEP
	addi $s7, $s7, 1
	j CHECK
	
M1:	jal MOVE_BAIXO
	li $a0, 1000
	jal SLEEP
	addi $s7, $s7, 1
	j CHECK
	
M2:	jal MOVE_LINHA_ESQUERDA
	li $a0, 1000
	jal SLEEP
	addi $s7, $s7, 1
	j CHECK
	
M3:	jal MOVE_BAIXO
	li $a0, 1000
	jal SLEEP
	addi $s7, $s7, 1
	j RESET


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
MPLAYA:	move $a0, $s6 # salva address em $a0 para poder mexer 
	move $t4, $sp # guarda o endereço da stack em t4
	li $t6, 8 # sao 8 linhas
	li $t7, 5 #sao 5 words por linha do player
P:	lw $t8, 0($t4) # carrega primeiro word do sprite player
	sw $t8, 0($a0)
	addi $t4, $t4, 4 # proximo word do player
	addi $a0, $a0, 4 # proximo address para mostrar na tela
	addi $t7, $t7, -1 # diminui uma word
	bne $t7, $zero, P
	
	addi $a0, $a0, 300 # frist address, next line
	addi $t6, $t6, -1
	li $t7, 5
	bne $t6, $zero, P
	jr $ra
	
### mostrar todos os inimigos na tela
MENEMY:	move $a0, $s0
	li $a1, 0xFF000000 # first VGA address
	li $a2, 38400 # bytes para leitura
	li $v0,14
	syscall
	jr $ra
	
### checando se alguma tecla foi apertada, e qual tecla foi essa
ECHO:	la $t1,0xFF100000
	lw $t0,0($t1)
	andi $t0,$t0,0x0001		# Le bit de Controle Teclado
   	beq $t0,$zero,NOKEY  	   	# Se não há tecla pressionada PULA
  	lw $t2,4($t1) # a tecla que foi apertada
  	jr $ra # return para a main fazer o control check
 NOKEY: li $t2, 0
 	jr $ra 	
### mexendo player para a esquerda
ESQUERDA:li $t0, 0x00000000 # preto
	addi $s6, $s6, 16 # ultima word do player em uma linha
	sw $t0, 0($s6) # repetetira 8 vezes - 1
	addi $s6, $s6, 320 # mesmo address, uma linha abaixo (nao tem problema por que uma copia do original esta em $a0 e este ($s6)sera atualizado
	sw $t0, 0($s6) # 2
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 3
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 4
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 5
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 6
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 7
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 8
	addi $s6, $s6, 320
	
	
	addi $a0, $a0, -4 # volta o player 4 bits
	move $s6, $a0 # salva novo address do player
	move $t4, $sp # guarda o endereço da stack em t4
	li $t6, 8 # sao 8 linhas
	li $t7, 5 #sao 5 words por linha do player
E:	lw $t8, 0($t4) # carrega primeiro word do sprite player
	sw $t8, 0($a0)
	addi $t4, $t4, 4 # proximo word do player
	addi $a0, $a0, 4 # proximo address para mostrar na tela
	addi $t7, $t7, -1 # diminui uma word
	bne $t7, $zero, E
	
	addi $a0, $a0, 300 # frist address, next line
	addi $t6, $t6, -1
	li $t7, 5
	bne $t6, $zero, E
	j CHECK
	
### mexendo player para a direita
DIREITA:#antes de voltar, apaga a parte que vai mexer
	li $t0, 0x00000000 # preto
	sw $t0, 0($s6) # repetetira 8 vezes - 1
	addi $s6, $s6, 320 # mesmo address, uma linha abaixo (nao tem problema por que uma copia do original esta em $a0 e este ($s6)sera atualizado
	sw $t0, 0($s6) # 2
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 3
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 4
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 5
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 6
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 7
	addi $s6, $s6, 320
	sw $t0, 0($s6) # 8
	addi $s6, $s6, 320


	addi $a0, $a0, 4 # volta o player 4 bits
	move $s6, $a0 # salva novo address do player
	move $t4, $sp # guarda o endereço da stack em t4
	li $t6, 8 # sao 8 linhas
	li $t7, 5 #sao 5 words por linha do player
D:	lw $t8, 0($t4) # carrega primeiro word do sprite player
	sw $t8, 0($a0)
	addi $t4, $t4, 4 # proximo word do player
	addi $a0, $a0, 4 # proximo address para mostrar na tela
	addi $t7, $t7, -1 # diminui uma word
	bne $t7, $zero, D
	
	addi $a0, $a0, 300 # frist address, next line
	addi $t6, $t6, -1
	li $t7, 5
	bne $t6, $zero, D
	j CHECK
	
### tiro do player
SHOOT:	la $t0, PSHOT
	li $t3, 10 # numero max de tiros
TFIRE:	lw $t1, 0($t0)
	beq $t1, $0, NEWFIRE # se um novo tiro puder ser alocado, faz isso
	addi $t0, $t0, 4 # checa se o prox tiro esta disponivel
	addi $t3, $t3, -1 # evita um loop infinito
	bne $t3, $0, TFIRE
	j CHECK # se chegar aqui, nao ha tiros disponiveis
	
NEWFIRE: 	# novo tiro
	addi $a0, $a0, 8
	move $v0, $a0
	# $a0 tem a position do tiro; $t0 tem o address do vetor para salvar
	li $t7, 0xFFFFFFFF #branco
	li $t6, 4
	addi $a0, $a0, -320
NB:	lw $t9, 0($a0)
	la $v1, NF
	bne $t9, maskBLACK, COLORTEST
NF:	sw $t7, 0($a0)
	addi $a0, $a0, -320
	addi $t6, $t6, -1
	bne $t6, $0, NB
	sw $a0, 0($t0)
	j CHECK
	
### Movendo os tiros
MS:	la $t0, PSHOT
	li $t3, 10
FC:	lw $t1, 0($t0)
	bne $t1, $0, ANDA
AR:	addi $t0, $t0, 4
	addi $t3, $t3, -1
	bne $t3, $0, FC
	jr $ra #acabou retorna
	
ANDA:	move $t9, $t1 # salva position do tiro
	li $t8, 0x00000000 # preto
	sw $t8, 0($t9) # pinta lugar em que o tiro esta de preto. as 4 positions - 1
	addi $t9, $t9, 320
	sw $t8, 0($t9) # 2
	addi $t9, $t9, 320
	sw $t8, 0($t9) # 3
	addi $t9, $t9, 320
	sw $t8, 0($t9) # 4
	addi $t9, $t9, 320
	sw $t8, 0($t9) # 4
	# ve se o tira nao acerta nada e desenha novo tiro
	
	li $t7, 0xFFFFFFFF #branco
	li $t6, 4
	addi $t1, $t1, -320 # tiro sobe
B:	lw $t9, 0($t1)
	la, $v1, F
	move $v0, $t1
	bne $t9, maskBLACK, COLORTEST
F:	sw $t7, 0($t1)
	addi $t1, $t1, -320
	addi $t6, $t6, -1
	bne $t6, $0, B
	li $t5, shLimit
	slt $t4, $t1, $t5
	bne $t4, $0, FIMTIRO
	sw $t1, 0($t0) #atualiza o vetor de tiros
	j AR

FIMTIRO:move $t9, $t1 # salva position do tiro
	li $t8, 0x00000000 # preto
	sw $t8, 0($t9) # pinta lugar em que o tiro esta de preto. as 4 positions - 1
	addi $t9, $t9, 320
	sw $t8, 0($t9) # 2
	addi $t9, $t9, 320
	sw $t8, 0($t9) # 3
	addi $t9, $t9, 320
	sw $t8, 0($t9) # 4
	addi $t9, $t9, 320
	sw $t8, 0($t9) # 4
	sw $0 ($t0) # termina o tiro. abre space pra outro
	jr $ra
### checa se acertou alguma coisa
COLORTEST: 
	# $t9 holds the color of whatever the shot hit # $v0 contem o address do inimigo atingido 
	# $t0 tem o address do tiro no vetor PSHOT
	move $s0, $t9
	andi $s0, maskENEMY1
	beq $s0, maskENEMY1, DHIT
	
	move $s0, $t9
	andi $s0, maskENEMY2
	beq $s0, maskENEMY2, LEFT
	
	move $s0, $t9
	andi $s0, maskENEMY3
	beq $s0, maskENEMY3, RIGHT
	
	move $s0, $t9
	andi $s0, maskENEMY4
	beq $s0, maskENEMY4, DHIT
	
	move $s0, $t9
	andi $s0, maskENEMY5
	beq $s0, maskENEMY5, DHIT

	# apagar o tiro
ERRTIR:	sw $0, 0($t0) # abre space no PSHOT
C:	sw $0, 0($t1) # apaga o tiro na grid
	addi $t6, $t6, 1
	addi $t1, $t1, 320
	bne $t6, 5, C

	j AR
	
BIP:	la $a1, INI # vetor com inimigo
	lw $a2, 4($a1) # inimigos ativos
	addi $a2, $a2, -1 # deduz inimigo atingido
	sw $a2, 4($a1) # atualiza no vetor
	# apagando o inimigo ... com margem de erro
	li $a1, 0x00000000
	li $a2, 10
	li $a3, 18

R:	sw $a1, 0($v0)
	addi $v0, $v0, -4
	addi $a2, $a2, -1
	bne $a2, $0, R
	
	li $a2, 10
	addi $a3, $a3, -1
	addi $v0, $v0, -280
	bne $a3, $0, R
	
	j ERRTIR
	
DHIT:	addi $v0, $v0, 20
	addi $v0, $v0, 1920
	
	# incrementa o score
	la $s1, SCORE
	lw $s2, 0($s1)
	addi $s2, $s2, 20
	sw $s2, 0($s1)
	# mostra o novo score
	
	  move $a0,$s2	# o score
	  li $a1,60	# coluna
	  li $a2,230	#linha
	  li $a3,0x71FB	# cores de frente(00) e fundo(FF) do texto
	  li $v0,101	# print int	
	  syscall	
	    
	j BIP
	
LEFT: 	addi $v0, $v0, 24
	addi $v0, $v0, 1920
	
	# incrementa o score
	la $s1, SCORE
	lw $s2, 0($s1)
	addi $s2, $s2, 10
	sw $s2, 0($s1)
	# mostra o novo score
	
	  move $a0,$s2	# o score
	  li $a1,60	# coluna
	  li $a2,230	#linha
	  li $a3,0x71FB	# cores de frente(00) e fundo(FF) do texto
	  li $v0,101	# print int	
	  syscall	
	    
	j BIP
	
RIGHT: 	addi $v0, $v0, 12
	addi $v0, $v0, 1920
	
	# incrementa o score
	la $s1, SCORE
	lw $s2, 0($s1)
	addi $s2, $s2, 10
	sw $s2, 0($s1)
	# mostra o novo score
	
	  move $a0,$s2	# o score
	  li $a1,60	# coluna
	  li $a2,230	#linha
	  li $a3,0x71FB	# cores de frente(00) e fundo(FF) do texto
	  li $v0,101	# print int	
	  syscall	
	    
	j BIP
	
### mexendo os inimigos - para a direita
MOVE_LINHA_DIREITA: 	la $t0, INI # abre info dos inimigos
		lw $t1, 0($t0) # abre address do enemy 1
		move $fp, $sp # achando o design correto
		addi $fp, $fp, 160 # design inimigo da linha de cima
		li $t3, 8 # inimigos por linha
		li $t4, 4 # linhas
A:		lw $t2, 0($t1) # abre flag do enemy 1
		
		
	
		bne $t2, $0, MOVEMOVE
BIRL:		addi $t1, $t1, 40
		addi $t3, $t3, -1
		bne $t3, $0, A
		
		li $t3, 8
		addi $fp, $fp, 180
		addi $t4, $t4, -1
		addi $t1, $t1, 8640
		bne $t4, $0, A
		
		#atualiza address em INI
		lw $t1, 0($t0)
		addi $t1, $t1, 8
		sw $t1, 0($t0)
		jr $ra
		
MOVEMOVE:	
	# primeiro pinta de preto onde o bichinho estava
	move $t5, $t1 #  salva address do bicho em $t5
	li $t6, 5 # words por linha
	li $t7, 10 # linhas
Q:	sw $0, 0($t5)		# apaga
	addi $t5, $t5, 4
	addi $t6, $t6, -1
	bne $t6, $0, Q
	
	li $t6, 5
	addi $t7, $t7, -1
	addi $t5, $t5, 300
	bne $t7, $0, Q
	
	# agora vamos criar novamente o garoto
	move $t5, $t1 # salva adress de novo
	addi $t5, $t5, 12 # novo address, 3 words pra frente
	li $t6, 5 # words por linha
	li $t7, 9 # linhas
Z:	lw $t8, 0($fp)
	sw $t8, 0($t5)
	addi $fp, $fp, 4
	addi $t5, $t5, 4
	addi $t6, $t6, -1
	bne $t6, $0, Z
	
	li $t6, 5
	addi $t7, $t7, -1
	addi $t5, $t5, 300
	bne $t7, $0, Z
	
	# volta o $fp 
	addi $fp, $fp, -180
	move $t5, $t1
	# e setar a flag dele
	addi $t5, $t5, 8
	li $t8, flagENEMY
	sw $t8, 0($t5)
	
	
	j BIRL
	
## mecendo os inimigos - uma vez para a esquerda
# ESSE vai do ultimo inimigo voltando ate o primeiro
MOVE_LINHA_ESQUERDA: 	la $t0, INI # abre info dos inimigos
		lw $t1, 0($t0) # abre address do enemy 1
		addi $t1, $t1, 27160 # address do ultimo inimigo
		move $fp, $sp # achando o design correto
		addi $fp, $fp, 700 # design inimigo da linha de baixo
		li $t3, 8 # inimigos por linha
		li $t4, 4 # linhas
K:		lw $t2, 0($t1) # abre flag do enemy 1
		
		
	
		bne $t2, $0, MOVEESQ
KARA:		addi $t1, $t1, -40
		addi $t3, $t3, -1
		bne $t3, $0, K
		
		li $t3, 8
		addi $fp, $fp, -180
		addi $t4, $t4, -1
		addi $t1, $t1, -8640	
		bne $t4, $0, K
		
		#atualiza address em INI
		lw $t1, 0($t0)
		addi $t1, $t1, -16
		sw $t1, 0($t0)
		jr $ra
		
MOVEESQ:	
	# primeiro pinta de preto onde o bichinho estava
	move $t5, $t1 #  salva address do bicho em $t5
	li $t6, 5 # words por linha
	li $t7, 10 # linhas
O:	sw $0, 0($t5)		# apaga
	addi $t5, $t5, 4
	addi $t6, $t6, -1
	bne $t6, $0, O
	
	li $t6, 5
	addi $t7, $t7, -1
	addi $t5, $t5, 300
	bne $t7, $0, O
	
	# agora vamos criar novamente o garoto
	move $t5, $t1 # salva adress de novo
	addi $t5, $t5, -12 # novo address, 3 words pra tras
	li $t6, 5 # words por linha
	li $t7, 9 # linhas
V:	lw $t8, 0($fp)
	sw $t8, 0($t5)
	addi $fp, $fp, 4
	addi $t5, $t5, 4
	addi $t6, $t6, -1
	bne $t6, $0, V
	
	li $t6, 5
	addi $t7, $t7, -1
	addi $t5, $t5, 300
	bne $t7, $0, V
	
	# volta o $fp 
	addi $fp, $fp, -180
	move $t5, $t1
	# e setar a flag dele
	addi $t5, $t5, -16
	li $t8, flagENEMY
	sw $t8, 0($t5)
	
	
	j KARA
	
### mexendo os inimigos - para baixo
MOVE_BAIXO: 	la $t0, INI # abre info dos inimigos
		lw $t1, 0($t0) # abre address do enemy 1
		move $fp, $sp # achando o design correto
		addi $fp, $fp, 160 # design inimigo da linha de cima
		li $t3, 8 # inimigos por linha
		li $t4, 4 # linhas
L:		lw $t2, 0($t1) # abre flag do enemy 1
		
		
	
		bne $t2, $0, MOVEDOWN
BARRY:		addi $t1, $t1, 40
		addi $t3, $t3, -1
		bne $t3, $0, L
		
		li $t3, 8
		addi $fp, $fp, 180
		addi $t4, $t4, -1
		addi $t1, $t1, 8640
		
		bne $t4, $0, L
		
		#atualiza address em INI
		lw $t1, 0($t0)
		addi $t1, $t1, 3200
		sw $t1, 0($t0)
		jr $ra
		
MOVEDOWN:	
	# primeiro pinta de preto onde o bichinho estava
	move $t5, $t1 #  salva address do bicho em $t5
	li $t6, 5 # words por linha
	li $t7, 10 # linhas
I:	sw $0, 0($t5)		# apaga
	addi $t5, $t5, 4
	addi $t6, $t6, -1
	bne $t6, $0, I
	
	li $t6, 5
	addi $t7, $t7, -1
	addi $t5, $t5, 300
	bne $t7, $0, I
	
	# agora vamos criar novamente o garoto
	move $t5, $t1 # salva adress de novo
	addi $t5, $t5, 3200
	li $s0, 0xFF000000
	addi $s0, $s0, 70080
	slt $s0, $t5, $s0
	bne $s0, $0, PLAYA
	li $t6, 5 # words por linha
	li $t7, 9 # linhas
J:	lw $t8, 0($fp)
	sw $t8, 0($t5)
	addi $fp, $fp, 4
	addi $t5, $t5, 4
	addi $t6, $t6, -1
	bne $t6, $0, J
	
	li $t6, 5
	addi $t7, $t7, -1
	addi $t5, $t5, 300
	bne $t7, $0, J
	
	# volta o $fp 
	addi $fp, $fp, -180
	move $t5, $t1
	# e setar a flag dele
	addi $t5, $t5, 3200
	li $t8, flagENEMY
	sw $t8, 0($t5)
	
	
	j BARRY
	
### gerando tiros dos inimigos
EFIRE:	la $t0, ESHOT
	li $t3, 5 # numero max de tiros
FIRE:	lw $t1, 0($t0)
	beq $t1, $0, NEWEFIRE # se um novo tiro puder ser alocado, faz isso
	addi $t0, $t0, 4 # checa se o prox tiro esta disponivel
	addi $t3, $t3, -1 # evita um loop infinito
	bne $t3, $0, FIRE
	j EFIREBACK # se chegar aqui, nao ha tiros disponiveis


NEWEFIRE: 
# primeiro decidimos quem vai atirar
	li $a0, 0 	# nao sei o q isso faz
	li $a1, 76	# maior possibilidade de retorno
	li $v0, 42 	# syscall para gerar numeros aleatorios
	syscall
	
	la $t8, INI
	lw $t1, 0($t8)
	addi $t1, $t1, 30080 # pula pra ultima linha de inimigos
	
	mul $t2, $a0, 4 # transforma numero aleatorio em um multiplo de 4
	add $t1, $t1, $t2 # o tiro vai sair daqui
	
	
# e depois criamos o tiro
	
	# $t1 tem a position do tiro; $t8 tem o address do vetor para salvar
	li $t7, 0xFFFFFFFF #branco
	li $t6, 4
	addi $t1, $t1, 320
EB:	lw $t9, 0($t1)
	la $v1, EF
	bne $t9, maskBLACK, ECOLORTEST
EF:	sw $t7, 0($t1)
	addi $t1, $t1, 320
	addi $t6, $t6, -1
	bne $t6, $0, EB
	sw $t1, 0($t0)
	j EFIREBACK
	
### movendo os tiros inimigos
### Movendo os tiros
MES:	la $t0, ESHOT
	li $t3, 5
FEC:	lw $t1, 0($t0)
	bne $t1, $0, EANDA
AER:	addi $t0, $t0, 4
	addi $t3, $t3, -1
	bne $t3, $0, FEC
	jr $ra #acabou retorna
	
EANDA:	move $t9, $t1 # salva position do tiro
	li $t8, 0x00000000 # preto
	sw $t8, 0($t9) # pinta lugar em que o tiro esta de preto. as 4 positions - 1
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 2
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 3
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 4
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 4
	# ve se o tira nao acerta nada e desenha novo tiro
	
	li $t7, 0xFFFFFFFF #branco
	li $t6, 4
	addi $t1, $t1, 320 # tiro desce
BE:	lw $t9, 0($t1)
	la, $v1, FE
	move $v0, $t1
	bne $t9, maskBLACK, ECOLORTEST
FE:	sw $t7, 0($t1)
	addi $t1, $t1, 320
	addi $t6, $t6, -1
	bne $t6, $0, BE
	
	sw $t1, 0($t0)
	j AER
	
### colortest versao inimigo
ECOLORTEST:	
# $t9 holds the color of whatever the shot hit # $v0 contem o address do que foi atingido 
	# $t0 tem o address do tiro no vetor ESHOT
	move $s0, $v0
	li $t2, 0xFF000000
	addi $t2, $t2, 70080
	slt $s0, $s0, $t2
	bne $s0, $0, CHAO
	
	move $s0, $t9
	andi $s0, maskBARRIER1
	beq $s0, maskBARRIER1, BARRIER
	
	move $s0, $t9
	andi $s0, maskBARRIER2
	beq $s0, maskBARRIER2, BARRIER
	
	move $s0, $t9
	andi $s0, maskPLAYA1
	beq $s0, maskPLAYA1, PLAYA
	
	move $s0, $t9
	andi $s0, maskPLAYA2
	beq $s0, maskPLAYA2, PLAYA
	
	move $s0, $t9
	andi $s0, maskPLAYA3
	beq $s0, maskPLAYA3, PLAYA
	
	move $s0, $t9
	andi $s0, maskPLAYA4
	beq $s0, maskPLAYA4, PLAYA
	
	move $s0, $t9
	andi $s0, maskPLAYA5
	beq $s0, maskPLAYA5, PLAYA

	
	jr $v1

BIPE:	move $t9, $t1 # salva position do tiro
	li $t8, 0x00000000 # preto
	sw $t8, 0($t9) # pinta lugar em que o tiro esta de preto. as 4 positions - 1
	sw $t8, 4($t9) # algo pra frente
	sw $t8, -4($t9) # algo pra tras
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 2
	sw $t8, 4($t9) # algo pra frente
	sw $t8, -4($t9) # algo pra tras
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 3
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 4
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 4
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 4
	sw $0, 0($t0) # termina o tiro. abre space pra outro
	
	jr $v1
	
CHAO:	move $t9, $t1 # salva position do tiro
	li $t8, 0x00000000 # preto
	sw $t8, 0($t9) # pinta lugar em que o tiro esta de preto. as 4 positions - 1
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 2
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 3
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 4
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 4
	addi $t9, $t9, -320
	sw $t8, 0($t9) # 4
	sw $0, 0($t0) # termina o tiro. abre space pra outro
	j AER
	
BARRIER: j BIPE
	
PLAYA: 	la $t0, LIVES
	lw $t1, 0($t0)
	addi $t1, $t1, -1
	beq $t1, $0, GAMEOVER
	sw $t1, 0($t0)
	j ABERTURA
	
### Finaliza o programa		
GAMEOVER:	la $a0, GAMEOVER
		jal ABRE
		move $a0, $s0
		
	
		la $a1,0xFF000000
		li $a2,76800
		li $v0,14
		syscall
		
		move $a0, $s0
		jal FECHA

		li $v0,10
		syscall
