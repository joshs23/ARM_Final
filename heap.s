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
_heap_init ;FINISHED
	;; Implement by yourself
		;Initialize the first entry (mcb[0]) to indicate the entire 16KB space is available
		LDR		r1, =MCB_TOP
		MOV		r0, #MAX_SIZE ;16KB
		STRH	r0, [r1]
		
		;Zero-initialize the rest of the entries
		LDR		r1, =MCB_TOP + 0x2 ; starting at the 2nd entry (mcb[1])
		MOV		r0, #0x0
		MOV		r2, #MCB_TOTAL - 0x1 ; Number of Entries to initialize
		
_heap_init_loop
		STRH	r0, [r1], #0x2 ; Zero-initialize the entry
		SUBS	r2, r2, #0x1
		BNE		_heap_init_loop
		
		; return
		MOV		pc, lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recursive Allocation Function
;void* _r_alloc(int size, int startAddress, int endAddress, int index)
		EXPORT	_ralloc
_ralloc ;FINISHED
	;; Helper function for _kalloc
		; r0 = size
		; r1 = start address of the current range (left or right)
		; r2 = end address of the current range
		; r3 = mcb_ent_sz

		PUSH	{lr}
		SUB		r4, r2, r1 
		ADD		r4, r4, r3 ; mcb_entire_size = right - left + mcb_ent_sz
		
		ASR		r5, r4, #0x1 ; mcb_half_size = mcb_entire_size / 2
		
		ADD		r6, r1, r5 ; midpoint = left + mcb_half_size
		MOV 	r12, #0x0	; heap_adr = NULL
		LSL		r8, r4, #0x4 ; act_entire_size = mcb_entire_size * 16
		LSL		r9, r5, #0x4; act_half_size = mcb_half_size * 16
		
		CMP		r0, r9 ; if(size <= act_half_size)
		BGT		_else
		
		PUSH 	{r0-r9}
		SUB		r2, r6, r3 ; right = midpoint - mcb_ent_sz
		BL		_ralloc
		POP		{r0-r9}
		
		CMP		r12, #0x0
		BEQ		_rightalloc
		
		; if ((array[m2a(midpoint)] & 0x01) == 0
		LDR		r10, [r6] ; value = value at the midpoint
		AND		r10, r10, #0x1
		CMP		r10, #0x0
		BEQ		_found
		
		B		done
		
_rightalloc
		; _ralloc(size, midpoint, right)
		PUSH	{r0-r9}
		MOV 	r1, r6 ; start address of current range = midpoint
		BL		_ralloc
		POP		{r0-r9}
		BL 		done
		
		
_else
		LDR		r10, [r1] ; value = value at start address of current range
		AND		r10, r10, #0x1 ; value = either 0 or 1
		CMP		r10, #0x0 ; if(value == 0)
		BNE		_return_invalid ; i.e. used
		
		LDR		r10, [r1] ; value = value at start address of current range
    CMP		r10, r8 ; if(value < act_entire_size)
		BLT		_return_invalid ; i.e. can't fit
		
		ORR		r10, r8, #0x1
		STR		r10, [r1]
		
		; return (void *)( heap_top + ( left - mcb_top ) * 16)
		LDR		r10, =MCB_TOP
		LDR		r11, =HEAP_TOP
		
		SUB		r1, r1, r10 ; (left - mcb_top)
		LSL		r1, r1, #0x4 ; (left - mcb_top) * 16
		ADD		r11, r11, r1
		MOV		r12, r11
		
		B 		done
		
		
_found
		STR		r9, [r6] 
		B		done
		
_return_invalid
		MOV		r12, #0 ; heap_addr = still not found (NULL)
		B		done
		
done
		POP		{lr}
		BX		lr
		
		
		
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc ;FINISHED
	;; Implement by yourself
		; r0 = size
		; Save return location
		PUSH	{lr}
		
		CMP R0, #0x20 ; if(size >= 32)
		BGE	_alloc ; allocate normally
		MOV R0, #0x20 ; else size = 32
		
_alloc
		; Call the recursive allocation function
		LDR		r1, =MCB_TOP ; start address of the entire range
		LDR		r2, =MCB_BOT ; end address of the entire range
		LDR		r3, =MCB_ENT_SZ ; size of each MCB entry (2 bytes)
		BL		_ralloc ; branch to _ralloc (recursive allocation)
		
		POP		{lr}
		MOV		R0, R12
		MOV		pc, lr ; return to _sys_malloc (svs.s)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; helper
;int _rfree( int mcb_addr ) {
		EXPORT _rfree
_rfree ;NOT FINISHED ACTIVE ERROR FOR MEM7
		PUSH	{lr}
		LDRH	r1, [r0] ; mcb_contents = *(short)&array[ m2a( mcb_addr) ]
		LDR		r2, =MCB_TOP
		SUB		r3, r0, r2 ; mcb_offset = mcb_addr - mcb_top
		ASR		r1, r1, #0x4 ; mcb_contents = mcb_contents / 16
		MOV		r4, r1 ; mcb_chunk = mcb_contents / 16
		
		; this clears the used bit
		LSL		r1, r1, #0x4 ; mcb_contents = mcb_contents * 16
		MOV		r5, r1 ; my_size = mcb_contents
		
		STRH	r1, [r0] ; *(short *)&array[ m2a( mcb_addr ) ] = mcb_contents
		
		SDIV	r12, r3, r4 ; if ( ( mcb_offset / mcb_chunk ) % 2 == 0 ) )
		AND		r12, r12, #0x1
		CMP		r12, #0x0
		MOV		r6, r12 ; r12 is indicator of left or right
		BEQ		_left_free

_right_free
		SUB		r6, r0, r4 ; mcb_addr - mcb_chunk
		CMP		r6, r2 ; if (mcb_addr - mcb_chunk < mcb_top)
		BLT		_return_zero
		B		_rejoin
		
_left_free
		; left
		ADD		r6, r0, r4 ; mcb_addr + mcb_chunk
		LDR		r8, =MCB_BOT
		CMP		r6, r8 ; if ( mcb_addr + mcb_chunk >= mcb_bot )
		BGE		_return_zero

_rejoin
		LDRH	r8, [r6] ; short mcb_buddy = *(short *)&array[ m2a( r6 ) ]
		; r6 is mcb_addr + mcb_chunk for left
		; r6 is mcb_addr - mcb_chunk for right
		
		AND		r9, r8, #0x1
		CMP		r9, #0x0 ; if ((mcb_buddy & 0x0001) == 0)
		BNE		_done
		
		ASR		r8, r8, #0x5 ;  mcb_buddy = (mcb_buddy / 32) * 32
		LSL		r8, r8, #0x5 
		CMP		r8, r5 ; if (mcb_buddy == my_size)
		BNE		_done
		
		CMP		r12, #0x0 ; recheck this condition
		BEQ		_left_free2
		
_right_free2
		STRH	r9, [r0] ; *(short *)&array[m2a(mcb_addr)] = 0
		LSL		r5, #0x1 ; my_size *= 2
		STRH 	r5, [r6] ; *(short *)&array[m2a(mcb_addr - mcb_chunk)] = my_size
		MOV		r0, r6 
		BL		_rfree ; return _rfree(mcb_addr - mcb_chunk)
		
_left_free2
		STRH	r9, [r6] ; *(short *)&array[m2a(mcb_addr + mcb_chunk)] = 0
		LSL		r5, #0x1 ; my_size *= 2
		STRH	r5, [r0] ; *(short *)&array[m2a(mcb_addr)] = my_size
		
		BL		_rfree ; return _rfree(mcb_addr)
		
_return_zero
		MOV		r0, #0x0
		
_done
		POP		{lr}
		MOV		pc, lr
	
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void free( void *ptr )
		EXPORT	_kfree
_kfree ;NOT FINISHED UNTIL _RFREE BUG IS RESOLVED
	;; Implement by yourself
		PUSH	{lr} ; saves pointer for later
		
		MOV		r1, r0 ; copy addr
		LDR		r2, =HEAP_TOP
		LDR		r3, =HEAP_BOT
		
		CMP		r1, r2 ; if(addr < heap_top)
		BLT		_return_null
		CMP		r1, r3 ; if(addr > heap_top)
		BGT		_return_null
		
		LDR		r4, =MCB_TOP
		SUB		r5, r1, r2 ; (addr - heap_top)
		ASR		r5, r5, #0x4 ; (addr - heap_top) / 16
		ADD		r5, r4, r5 ; mcb_addr = mcb_top + (addr - heap_top) / 16
		
		MOV		r0, r5 ; mcb_addr is param of _rfree
		PUSH	{r1-r12}
		BL		_rfree
		POP		{r1-r12}
		CMP		r0, #0x0 ; if( _rfree( mcb_addr ) == 0 )
		BEQ		_return_null
		B		_finish_kfree
		
_return_null
		MOV		r0, #0x0 ; return is null
		B		_finish_kfree
		
_finish_kfree
		POP		{lr}
		MOV		pc, lr					; return from rfree( )
		

		END
