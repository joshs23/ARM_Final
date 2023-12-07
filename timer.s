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
SIGALRM		EQU		14			; sig alarm

; System Variables
SECOND_LEFT	EQU		0x20007B80		; Secounds left for alarm( )
USR_HANDLER     EQU		0x20007B84		; Address of a user-given signal handler function	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer initialization
; void timer_init( )
		EXPORT		_timer_init
_timer_init
	;; Implement by yourself
		;;;;;;
		LDR		r1, =STCTRL				;;load control/status register
		LDR		r0, =STCTRL_STOP		;;set interupt and clock enable off
		STR		r0, [r1]				;;store control/status register
	
		LDR		r0, =STRELOAD_MX		;;set to max val to count down from
		LDR		r1, =STRELOAD			;;store in register
		STR		r0, [r1]				; Load the maximum value to SYST_RVR(STRELOAD)
	
		MOV		r1, #0x0				;;have to clear these each time (counter, countflag, current value register, address)
		LDR		r0, =STCURR_CLR			
		STR		r1, [r0]
		;;;;;;;
		MOV		pc, lr		; return to Reset_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer start
; int timer_start( int seconds )
		EXPORT		_timer_start
_timer_start
	;; Implement by yourself
		;;;;;
		LDR		r1, =SECOND_LEFT		;;load/store register with how many seconds left
		STR		r0, [r1]
	
		LDR		r0, =STCTRL				;;load control/status register
		LDR		r1, =STCTRL_GO			;;set interupt and clock enable on
		STR 	r1, [r0]				;;store the new value
	
		;;;;;
		MOV		pc, lr		; return to SVC_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void timer_update( )
		EXPORT		_timer_update
_timer_update
	;; Implement by yourself
		;;PUSH	{r1-r12, lr}
		;;;;;
		LDR		r1, =SECOND_LEFT		;;grab seconds left on alarm
		LDR		r0, [r1]
	
		SUB 	r0, r0, #1				;;decrement by 1
		STR		r0, [r1]
		CMP		r0, #0					;;branches to _timer_update_done if value isnt 0
		BNE		_timer_update_done		;;otherwise it needs to stop timer and invoke user function
	
		LDR		r0, =STCTRL				;;load control/status register
		LDR		r1, =STCTRL_STOP		;;set interupt and clock enable off
		STR		r1, [r0]				;;store control/status register
	
		LDR		r0, =USR_HANDLER		;;branch to USR signal handler
		LDR		r0, [r0]
		;;STMDB 	sp!, {lr}
		PUSH	{r1-r12, lr}			;;save and resume lr
		BLX		r0
		;;LDMIA	sp!, {lr}
		POP		{r1-r12, lr}
		;;;;;
_timer_update_done
		MOV		pc, lr		; return to SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Timer update
; void* signal_handler( int signum, void* handler )
	    EXPORT	_signal_handler
_signal_handler
	;; Implement by yourself
	; r0 = signum
	; r1 = *func
		;;;;;
		CMP 	r0, #SIGALRM			;check if the signum is 14
		BNE		_done					; if not SIG_ALRM, do nothing
		LDR		r2, =USR_HANDLER		; load the USR_HANDLER address to r2
		LDR		r3, [r2]				; retain previous value to return
		STR		r1, [r2]				; save the *func to USR_HANDLER
		MOV		r0, r3					; Return the previous value of 0x2007B84 to
										; main( ) through R0.
_done	
		MOV		pc, lr					; return to Reset_Handler
		
		END		
