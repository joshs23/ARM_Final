		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Timer Definition
STCTRL		EQU		0xE000E010		; SysTick Control and Status Register
STRELOAD	EQU		0xE000E014		; SysTick Reload Value Register
STCURRENT	EQU		0xE000E018		; SysTick Current Value Register
	
STCTRL_STOP	EQU		0x00000004		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 0, Bit 0 (ENABLE) = 0
STCTRL_GO	EQU		0x00000007		; Bit 2 (CLK_SRC) = 1, Bit 1 (INT_EN) = 1, Bit 0 (ENABLE) = 1
STRELOAD_MX	EQU		0x00FFFFFF		; MAX Value = 1/16MHz * 16M = 1 second
STCURR_CLR	EQU		0x00000000		; Clear STCURRENT and STCTRL.COUNT	
SIGALRM		EQU		14				; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
	;; Implement by yourself
		;;;;;;
		LDR		r1, =STCTRL				; load systick control
		LDR		r0, =STCTRL_STOP		; load systick stop value (4)
		STR		r0, [r1]				; update systick control to stop
	
		LDR		r0, =STRELOAD_MX		; load countdown to r0 to equal 1 second
		LDR		r1, =STRELOAD			; load address of systick reload into r1
		STR		r0, [r1]				; Load the maximum value to SYST_RVR(STRELOAD)
	
		LDR		r1, =STCURR_CLR			; load 0 to register
		LDR		r0, =STCURRENT			; load the systick current flags
		STR		r1, [r0]				; set all flags to 0 to reset timer
		;;;;;;;
		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start from _alarm
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
	;; Implement by yourself
	; r0 = seconds for new timer
		;;;;;
		LDR		r1, =SECOND_LEFT		; load address of previous seconds
		LDR		r2, [r1]				; save the previous time value to return
		STR		r0, [r1]				; update with new time value
		MOV		r0, r2					; move the previous time value to r0 to return
	
		LDR		r3, =STCTRL				; load systick control
		LDR		r4, =STCTRL_GO			; load systick go value (#7)
		STR 	r4, [r3]				; update systick control to start

		LDR		r5, =STCURR_CLR			; load 0 to register
		LDR		r6, =STCURRENT			; load the systick current flags
		STR		r5, [r6]				; set all flags to 0 to reset timer
	
		;;;;;
		MOV		pc, lr					; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
	;; Implement by yourself

		LDR		r1, =SECOND_LEFT		; load address of time value
		LDR		r2, [r1]				; get time value remaining
	
		SUB 	r2, r2, #1				; decrement by 1
		STR		r2, [r1]				; store the new time remaining value
		CMP		r2, #0					; check if timer has reached 0
		BNE		_timer_update_done		; if there is still time left, done
										; else, stop timer and invoke user function
										
		LDR		r3, =STCTRL				; load systick control
		LDR		r4, =STCTRL_STOP		; load systick stop value (4)
		STR		r4, [r3]				; update systick control to stop
	
		LDR		r5, =USR_HANDLER		; load USR handler address
		LDR		r5, [r5]				; load value at the USR handler address
		PUSH	{r1-r12, lr}			; save registers and lr
		BLX		r5						; branch to USR handler function
		POP		{r1-r12, lr}			; resume registers and lr
		;;;;;
_timer_update_done
		MOV		pc, lr					; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;; Implement by yourself
	; r0 = signum
	; r1 = *func
		;;;;;
		CMP 	r0, #SIGALRM			; check if the signum is 14
		BNE		_done					; if not SIG_ALRM, do nothing
		LDR		r2, =USR_HANDLER		; load the USR_HANDLER address to r2
		LDR		r3, [r2]				; retain previous value to return
		STR		r1, [r2]				; save the *func to USR_HANDLER
		MOV		r0, r3					; Return the previous value of 0x2007B84 to
										; main( ) through R0.
_done	
		MOV		pc, lr					; return to Reset_Handler
		
		END		
