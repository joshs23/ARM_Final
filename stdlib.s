		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero
		; r0 = s
		; r1 = n
		; r2 = 0
		STMFD	sp!, {r1-r12,lr}
		MOV		r3, r0				; r3 = dest
		MOV		r2, #0				; r2 = 0;	
_bzero_loop							; while( ) {
		SUBS	r1, r1, #1			; 	n--;
		BMI		_bzero_return		;   if ( n < 0 ) break;	
		STRB	r2, [r0], #0x1		;	[s++] = 0;
		B		_bzero_loop			; }
_bzero_return
		MOV		r0, r3				; return dest;
		LDMFD	sp!, {r1-r12,lr}
		MOV		pc, lr	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy
		; r0 = dest
		; r1 = src
		; r2 = size
		; r3 = a copy of original dest
		; r4 = src[i]
		STMFD	sp!, {r1-r12,lr}
		MOV		r3, r0				; r3 = dest
_strncpy_loop						; while( ) {
		SUBS	r2, r2, #1			; 	size--;
		BMI		_strncpy_return		; 	if ( size < 0 ) break; 		
		LDRB	r4, [r1], #0x1		; 	r4 = [src++];
		STRB	r4, [r0], #0x1		;	[dest++] = r4;
		CMP		r4, #0				;   
		BEQ		_strncpy_return		;	if ( r4 = '\0' ) break;
		B		_strncpy_loop		; }
_strncpy_return
		MOV		r0, r3				; return dest;
		LDMFD	sp!, {r1-r12,lr}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   	void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc
		; save registers
		PUSH 	{r1-r12, lr}
		; set the system call # to R7
		MOV 	r7, #0x3
	    SVC     #0x0
		; resume registers
		POP 	{r1-r12, lr}
		
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   	none
		EXPORT	_free
_free
		; save registers
		PUSH 	{r1-r12, lr}
		; set the system call # to R7
		MOV 	R7, #0x4
        SVC     #0x0
		; resume registers
		POP 	{r1-r12, lr}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; unsigned int _alarm( unsigned int seconds )
; Parameters
;   seconds - seconds when a SIGALRM signal should be delivered to the calling program	
; Return value
;   unsigned int - the number of seconds remaining until any previously scheduled alarm
;                  was due to be delivered, or zero if there was no previously schedul-
;                  ed alarm. 
		EXPORT	_alarm
_alarm
		; save registers
		PUSH 	{r1-r12, lr}
		; set the system call # to R7
		MOV 	r7, #0x1
        SVC     #0x0
		; resume registers
		POP 	{r1-r12, lr}
		MOV		pc, lr		
			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void* _signal( int signum, void *handler )
; Parameters
;   signum - a signal number (assumed to be 14 = SIGALRM)
;   handler - a pointer to a user-level signal handling function
; Return value
;   void*   - a pointer to the user-level signal handling function previously handled
;             (the same as the 2nd parameter in this project)
		EXPORT	_signal
_signal
		; save registers
		PUSH 	{r1-r12, lr}
		; set the system call # to R7
		MOV 	r7, #0x2
        SVC     #0x0
		; resume registers
		POP 	{r1-r12, lr}
		MOV		pc, lr	

;EXTRA CREDIT--------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; int abs(int)
; r0 = int
		EXPORT _abs
_abs
		STMFD	sp!, {r1-r12,lr}
		MOV		r1, #0x0
		CMP 	r0, r1
		BGE		_abs_done		; check if the int is already poisitive
		CMP		r0, #0x80000000 ; check if int is INT_MIN
		BEQ		_handle_min_int
		SUB		r0, r1, r0		; 0 + given value
_abs_done
		LDMFD	sp!, {r1-r12,lr}; resume registers
		MOV 	pc, lr			; branch back to main()
_handle_min_int
		MOV		r0, #0x7FFFFFFF	; assign INT_MAX (2,147,483,647 to return if value is 
								; -2,147,483,648. because this number does not exist in
								; int as a positive. this is how stdlib.h handles this
		B		_abs_done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The C library function int atoi(const char *str) converts the string argument str to 
; an integer (type int).
; int atoi(const char *str)
; r0 str beginning address
		EXPORT _atoi
_atoi
		STMFD	sp!, {r1-r12,lr}; save registers
		MOV		r1, r0			; r1 = source address
		MOV		r0, #0x0		; r2 = 0, start of the new int value
		MOV		r5, #10			; set multiplier value for later
		LDRB	r3, [r1], #0x1		; get the first char in the string
_aloop
		CMP		r3, #0x30		; compare to ASCII 0
		BLT		_error			; string contains non int
		CMP		r3, #0x39		; Compare to ASCII 9
		BGT		_error			; string contains non int
		
		
		MUL		r2, r0, r5		; move current digit to left 1 decimal place
		SUB		r3, r3, #0x30	; translate from ASCII
		ADD		r2, r2, r3		; add the next digit
		CMP		r2, r0			; check if new value has overflowed, stdlib in 		
		BLT		_error			; C does not handle this
		
		MOV		r0, r2			; value still valid
		LDRB	r3, [r1], #0x1	; move to next char in string
		CMP		r1, #0x0		; check if string is done
		BEQ		_atoi_done		; if so, done
		B		_aloop			; else, handle the next char
		
_error
		MOV		r0, #0x0		;return 0 because string contained a non int
_atoi_done	
		LDMFD	sp!, {r1-r12,lr}; resume registers
		MOV		pc, lr			; branch back to main()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		END			
