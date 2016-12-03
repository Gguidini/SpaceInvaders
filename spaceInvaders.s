###################################
# SPACE INVADERS - ASSEMBLY MIPS  #
###################################

.data 
FILE: .asciiz "space_open.bin"
LIT:	.asciiz "enter.bin"
.text

# Preenche a tela de preto	#aberto a modificações e melhorias. Ex: musica de entrada... frase de impacto
	li $t1,0xFF012C00	#last bitmap address
	li $s2,0xFF000000	#first bitmap address
	li $s1,0x00000000	# black, 4 bits
LOOP: 	beq $s2,$t1,FORA
	sw $s1,0($s2)
	addi $s2,$s2,4
	j LOOP
FORA:

# Abre o arquivo
ABRE:	la $a0,FILE
	li $a1,0
	li $a2,0
	li $v0,13
	syscall

	
# Le o arquivos para a memoria VGA
	move $a0,$v0
	la $a1,0xFF000000
	li $a2,76800
	li $v0,14
	syscall

#Fecha o arquivo
FECHA:	move $a0,$s1
	li $v0,16
	syscall
	
#fazendo o ENTER piscar
PISCA:	li $s1,0x00000000
	li $s2,0xFF000000
	addi $s2, $s2, 0xD4F0
	addi $t1, $s2, 0
	addi $t1, $t1, 52
	li $t7, 10
APAGA:	beq $s2,$t1, OK
	sw $s1,0($s2)
	addi $s2,$s2,4
	j APAGA
OK:	addi $t7, $t7, -1
	addi $s2, $s2, 268
	addi $t1, $t1, 320
	bne $t7, $zero, APAGA
	li $a0, 500			#isto terá que ser alterado para verificar se alguma tecla foi teclada
	jal SLEEP
	
	li $s2,0xFF000000
	addi $s2, $s2, 0xD4F0

	#reabrindo o enter
	la $a0,LIT
	li $a1,0
	li $a2,0
	li $v0,13
	syscall
	
	#lendo linha por linha
	move $t7, $v0
	addi $t1, $zero, 12
FILL:	beq $t1, $zero, DONE
	move $a0,$t7
	move $a1, $s2			#nao ta lendo direito. Resolver.
	li $a2,50
	li $v0,14
	syscall
	addi $t1, $t1, -1
	addi $s2, $s2, 320
	j FILL
	
DONE:	#fecha o arquivo
	move $a0,$s1
	li $v0,16
	syscall
	j FIM
#facilitando a chamada do sleep. $a0 deve conter o delay em milissegundos
SLEEP:	li $v0, 32
	syscall
	jr $ra
	
			
FIM:	li $v0,10
	syscall
