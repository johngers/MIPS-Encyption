#Who: John Gers
#What: project4.asm
#Why: Encyption program using input and output files and a passphrase from the console
#When: December 5th
#How: List the uses of 5 registers
#$s0 = BUFFER address
#$s1 = Newline character
#$s2 = PASSWORD_BUFFER address
#$s3 = Number of characters read
#$s4 = Input file descriptor
#$s5 = Output file descriptor

.data
	.align 2
	prompt1:		.asciiz "Please enter input file path: "
	prompt2:		.asciiz "Please enter passphrase: "
	prompt3:		.asciiz "Please enter output file path: "
	BUFFER:    		.space 1024
	PASSWORD_BUFFER: .space 500
.text
.globl main

main: # program entry
	li $s1, 10					# Load newline into register

	jal Input_Path				# Get path for input file

	jal Trim_Input				# Trim path

	jal OpenInput				# Open input file

	jal Output_Path				# Get path for output file

	jal Trim_Output				# Trim path

	jal OpenOutput				# Open output file

	jal	Input_Password			# Take password as input

	jal Trim_Password			# Trim the password

	jal Encode					# Perform the encode

	jal CloseFiles				# Close input and output files


Exit:
	li $v0,10 					# Terminate program
	syscall



Input_Path:

	# Display prompt
	la $a0, prompt1				# Load Prompt
	li $v0, 4					# Print prompt
	syscall

	# Take input path as string
	la $a0, BUFFER 				# Load the buffer
	li $a1, 1024					# Load size of the buffer
	li $v0, 8  					# Get string from console
	syscall

	move $s0, $a0 				# Save input path address

	j $ra						# Jump back to link

Input_Password:

	# Display prompt
	la $a0, prompt2				# Load Prompt
	li $v0, 4					# Print prompt
	syscall

	# Take input path as string
	la $a0, PASSWORD_BUFFER 	# Load the buffer
	li $a1, 500					# Load size of the buffer
	li $v0, 8  					# Get string from console
	syscall

	move $s2, $a0 				# Save password address

	j $ra						# Jump back to link

Output_Path:

	# Display prompt
	la $a0, prompt3				# Load Prompt
	li $v0, 4					# Print prompt
	syscall

	# Take input path as string
	la $a0, BUFFER 				# Load the buffer
	li $a1, 1024					# Load size of the buffer
	li $v0, 8  					# Get string from console
	syscall

	j $ra						# Return

Trim_Input:

	move $t0, $s0				# Move input path address to a temp register
	j TrimLoop					# Start trim

Trim_Password:

	move $t0, $s2				# Move password address to a temp register
	j TrimLoop					# Start trim

Trim_Output:

	move $t0, $s0				# Move output path address to a temp register
	j TrimLoop					# Start trim

TrimLoop:

	lb $t1, 0($t0)				# Load byte of $t0 into temp register
	beqz $t1, ExitTrim			# Branch if result is null
	bne $t1, $s1, SkipTrim 		# Skip the trim because it's not a newline character
		sb $0, 0($t0) 			# Make newline null (Trim part)
		j ExitTrim				# Exit trim
	SkipTrim:
	addiu $t0, $t0, 1			# Iterate through string
	j TrimLoop

ExitTrim:

	j $ra						# Return

Encode:

	move $t9, $ra 				# Save the return address

StartEncode:

	jal ReadFromFile

	beq $s3, $0, ExitEncode		# If nothing was read, exit

	# Load input and passphrase addresses to temps
	move $t0, $s0				# Load input adress
	move $t1, $s2				# Load password address

	move $t5, $0				# Start a counter

EncodeLoop:

	beq $t5, $s3, WriteEncode	# Exit when you've gone through all read characters
	lb $t2, 0($t0)				# Load byte from input
	lb $t3, 0($t1)				# Load byte from password
	beq $t3, $0, ResetPassword	# Reset password if at the end
	xor $t4, $t2, $t3			# Perform encyption

	sb $t4, 0($t0)				# Store encyption

	addi $t0, $t0, 1			# Iterate through buffer
	addi $t1, $t1, 1			# Iterate through passphrase

	addi $t5, $t5, 1			# Increment counter

	j EncodeLoop				# Loop back

ResetPassword:

	move $t1, $s2				# Move back into t1 the beginning of the password
	j EncodeLoop				# Go back to the loop

WriteEncode:

	jal WriteToFile				# Jump to write

ExitEncode:

	bne $s3, $0, StartEncode	# Make sure nothing was read or written, then exit

	j $t9 						# Jump back to main


OpenInput:

	# Open input file
	li   $v0, 13       			# System call for open file
	move   $a0, $s0      		# Input file name
	li   $a1, 0       			# Flag for reading
	syscall            			# Open file
	move $s4, $v0      			# Save the file descriptor

	j $ra						# Return

ReadFromFile:

	# Read from the input file
	li   $v0, 14       			# Read_file syscall code = 14
	move $a0, $s4     			# File descriptor
	la   $a1, BUFFER   			# Address of buffer from which to read
	la   $a2,  1024      			# Buffer length

	syscall           			# Read from file
	move $s3, $v0				# Number of characters read

	j $ra


OpenOutput:

	# Open output file
    li $v0,13           		# Open_file syscall code = 13
    move $a0, $s0     			# Get the file name
   	li $a1, 1
	li $a2, 0x1FF
    syscall
    move $s5,$v0        		# Save the file descriptor

	j $ra						# Return

WriteToFile:

    # Write to the output file
    li $v0,15					# Write file syscall code = 15
    move $a0,$s5				# Output file descriptor
    move $a1,$s0				# The string that will be written
    move $a2, $s3				# Load the number of character
    syscall

    j $ra						# Return

CloseFiles:

	# Close input file
    li $v0,16         			# Close file syscall code = 16
    move $a0,$s4     			# File descriptor to close
    syscall

	# Close output file
    li $v0,16         			# Close file syscall code = 16
    move $a0,$s5     			# File descriptor to close
    syscall

	j $ra						# Return