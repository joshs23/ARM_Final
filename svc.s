		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
SYSTEMCALLTBL	EQU		0x20007B00 ; originally 0x20007500
SYS_EXIT		EQU		0x0		; address 20007B00
SYS_ALARM		EQU		0x1		; address 20007B04
SYS_SIGNAL		EQU		0x2		; address 20007B08
SYS_MALLOC		EQU		0x3		; address 20007B0C
SYS_FREE		EQU		0x4		; address 20007B10
;SYS_MEMCPY		EQU		0x5		; address 20007B14 extra credit-------------------------------------TODO if time allows

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Initialization
		EXPORT	_syscall_table_init
_syscall_table_init
	;; Implement by yourself
		PUSH	{lr}
		LDR		r0, =SYSTEMCALLTBL
		
		LDR		r1, =_sys_exit   ;;; address of _sys_exit is loaded to r1
		STR		r1, [r0]         ;;; Store address of _sys_exit to the start of table
		
		ADD		r0, r0, #0x4     ;;; increment table location by 4 to address 20007B04
		LDR		r1, =_sys_alarm  ;;; address of _sys_alarm is loaded to r1
		STR		r1, [r0]         ;;; Store address of _sys_alarm to the table
		
		ADD		r0, r0, #0x4     ;;; increment table location by 4 to address 20007B08
		LDR		r1, =_sys_signal ;;; address of _sys_signal is loaded to r1
		STR		r1, [r0]         ;;; Store address of _sys_signal to the table
								
		ADD		r0, r0, #0x4     ;;; increment table location by 4 to address 20007B0C
		LDR		r1, =_sys_malloc ;;; address of _sys_malloc is loaded to r1
		STR		r1, [r0]         ;;; Store address of _sys_malloc to the table
								
		ADD		r0, r0, #0x4     ;;; increment table location by 4 to address 20007B10
		LDR		r1, =_sys_free   ;;; address of _sys_free is loaded to r1
		STR		r1, [r0]         ;;; Store address of _sys_free to the table
								
		;;ADD		r0, r0, #0x4     ;;; increment table location by 4 to address 20007B14
		;;LDR		r1, =_sys_memcpy ;;; address of _sys_memcpy is loaded to r1
		;;STR		r1, [r0]         ;;; Store address of _sys_memcpy to the table
		
		POP		{lr}
		MOV		pc, lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table Jump Routine
        EXPORT	_syscall_table_jump
_syscall_table_jump
	;; Implement by yourself
		PUSH	{lr}
		LDR		r11, =SYSTEMCALLTBL
		MOV		r2, r7
		; extra credit memcpy TODO------------------------------------------------------
		
		CMP		r2, #SYS_FREE
		BEQ		_sys_free
		
		CMP		r2, #SYS_MALLOC
		BEQ		_sys_malloc
		
		CMP		r2, #SYS_SIGNAL
		BEQ		_sys_signal
		
		CMP		r2, #SYS_ALARM
		BEQ		_sys_alarm
		
		;;CMP		r2, #SYS_MEMCPY
		;;BEQ		_sys_memcpy
		
		BL		_sys_exit
		
		POP		{lr}
		MOV		pc, lr ; return to SVC_Handler (startup)			
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call

_sys_exit
		PUSH	{lr}
		BLX		r11
		POP		{lr}
		BX		lr
		
_sys_alarm
		IMPORT	_timer_start
		LDR		r11, =_timer_start
		PUSH	{lr}
		BLX		r11		; branch to _timer_start (timer.s)
		POP		{lr}
		BX		lr		; return to syscall_table_jump
		
_sys_signal
		IMPORT	_signal_handler
		LDR		r11, =_signal_handler
		PUSH	{lr}
		BLX		r11		; branch to _signal_handler (timer.s)
		POP		{lr}
		BX		lr		; return to syscall_table_jump
		
_sys_malloc
		IMPORT	_kalloc
		LDR		r11, =_kalloc
		PUSH	{lr}
		BLX		r11 	; branch to _kalloc (heap.s)
		POP		{lr}
		BX		lr 		; return to syscall_table_jump

_sys_free
		IMPORT	_kfree
		LDR		r11, =_kfree
		PUSH	{lr}
		BLX		r11  	; branch to _kfree (heap.s)
		POP		{lr}
		BX		lr  	; return to syscall_table_jump
		
_sys_memcpy
		;extra credit
		
		END