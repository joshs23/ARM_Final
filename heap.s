		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
		EXPORT	_heap_init
_heap_init
	;; Implement by yourself
		;Initialize the first entry (mcb[0]) to indicate the entire 16KB space is available
		LDR		r1, =MCB_TOP
		MOV		r0, #MAX_SIZE ;16KB
		STRH	r0, [r1]
		
		;Zero-initialize the rest of the entries
		LDR		r1, =MCB_TOP + 2 ; starting at the 2nd entry (mcb[1])
		MOV		r0, #0x0
		MOV		r2, #MCB_TOTAL - 1 ; Number of Entries to initialize
		
_heap_init_loop
		STRH	r0, [r1], #2 ; Zero-initialize the entry
		SUBS	r2, r2, #1
		BNE		_heap_init_loop
		
		; return
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recursive Allocation Function
;void* _r_alloc(int size, int startAddress, int endAddress, int index)
		EXPORT	_ralloc
_ralloc ; FUNCTION IS NOT FINISHED ++++++++++++++++++++++++++++++++++++++++++++++++++++
	;; Helper function for _kalloc
		; r0 = size
		; r1 = start address of the current range (left or right)
		; r2 = end address of the current range
		; r3 = current MCB index
		
		PUSH	{lr}
		; Calculate the size of the current range
		SUB		r4, r2, r1
		
		; Check if the current range is available and fits the requested size
		LDR		r5, [r3] ; Load the MCB entry
		CMP		r5, #0 ; Check if the range is available
		BNE		_ralloc_skip_allocation
		
		CMP		r4, r0 ; Check if the range size is greater than or equal to the requested size
		BLT		_ralloc_skip_allocation
		
		; Allocate the current range
		STR		r4, [r3] ; Record the size of the allocated range in the MCB

		; Calculate the address of the right half
		ADD		r6, r1, r4
		
		; Update the MCB entry for the right half
		STR		r4, [r6]
		
		MOV		r0, r1 ; Return the start address of the allocated range
		POP		{lr}
		MOV		pc, lr ; Return from _ralloc
		
_ralloc_skip_allocation
		; Check if the current range can be further divided
		CMP		r4, r0 ; Check if the current range size is ess than the requested size
		BLT		_ralloc_no_allocation
		
		;		Recursively call _ralloc for the left half
		BL		_ralloc
		MOV		pc, lr ; return from _ralloc
		
_ralloc_no_allocation
		MOV		r0, #0 ; return 0 to indicate failure
		MOV		pc, lr ; return from _ralloc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc ; FUNCTION IS NOT FINISHED
	;; Implement by yourself
		; r0 = size
		; Save return location
		PUSH	{LR}
		; Call the recursive allocation function
		LDR		r1, =MCB_TOP ; start address of the entire range
		LDR		r2, =MCB_BOT ; end address of the entire range
		LDR		r3, =MCB_ENT_SZ ; size of each MCB entry (2 bytes)
		BL		_ralloc ; branch to _ralloc (recursive allocation)
		
		POP		{LR}
		MOV		pc, lr ; return to _sys_malloc (svs.s)
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree
	;; Implement by yourself
		MOV		pc, lr					; return from rfree( )
		
		END
