.MODEL SMALL
.STACK 100h

.DATA
; ---------- Data Section ----------
parkingSlots DB 10 DUP(0FFh)     ; 0FFh = Empty marker for all 10 slots
parkingHours DB 10 DUP(0)        ; Parking time in hours for each slot

lastAction DB 0                  ; 1 = park, 2 = leave, 0 = nothing
lastSlot   DW 0                  ; Last slot used
lastCar    DB 0                  ; Last car ID used
lastHour   DB 0                  ; Last hour value used

; ---------- Display Messages ----------
menuMsg      DB 13,10,"--- Parking System Menu ---",13,10
             DB "1. Park a Car",13,10
             DB "2. Leave a Car",13,10
             DB "3. Fee Calculator",13,10
             DB "4. Undo Last Action",13,10
             DB "5. Show Available Slots",13,10
             DB "6. Search Car",13,10
             DB "7. Exit",13,10
             DB "Choose: $"

parkMsg      DB 13,10,"Enter Car ID (0-9): $"
dupCarMsg    DB 13,10,"Car ID already parked!$"
hourMsg      DB 13,10,"Enter Hours (1-9): $"
slotMsg      DB 13,10,"Enter Slot Number (0-9): $"
feeMsg       DB 13,10,"Parking Fee(32TK/hour) = $"
foundMsg     DB 13,10,"Car found at Slot: $"
notFound     DB 13,10,"Car not found!$"
undoMsg      DB 13,10,"Last action undone.$"
nospace      DB 13,10,"No space available!$"
exitMsg      DB 13,10,"Exiting Program...$"

.CODE
MAIN PROC
    ; ---------- Set up Data Segment ----------
    MOV AX, @DATA
    MOV DS, AX

main_menu:
    ; ---------- Display Main Menu ----------
    CALL clear_input_buffer
    LEA DX, menuMsg
    MOV AH, 09h
    INT 21h

    ; ---------- Get User Menu Choice ----------
    CALL get_single_digit

    ; ---------- Go to selected operation ----------
    CMP AL, 1
    JE park_car
    CMP AL, 2
    JE leave_car
    CMP AL, 3
    JE fee_calc
    CMP AL, 4
    JE undo_action
    CMP AL, 5
    JE show_slots
    CMP AL, 6
    JE search_car
    CMP AL, 7
    JE exit_prog
    JMP main_menu

; ---------- 1. Park a Car ----------
park_car:
    LEA DX, parkMsg
    MOV AH, 09h
    INT 21h
    CALL get_single_digit        ; Input Car ID
    MOV BL, AL                   ; Save car ID in BL

    XOR SI, SI                   ; SI = index for scanning slots
check_duplicate:
    CMP SI, 10
    JE no_duplicate              ; No match found, safe to proceed
    MOV AL, parkingSlots[SI]
    CMP AL, BL
    JE duplicate_found
    INC SI
    JMP check_duplicate

duplicate_found:
    LEA DX, dupCarMsg
    MOV AH, 09h
    INT 21h
    JMP main_menu

no_duplicate:
    LEA DX, hourMsg
    MOV AH, 09h
    INT 21h
    CALL get_single_digit        ; Input parking hours
    MOV BH, AL

    XOR SI, SI
find_empty:
    CMP SI, 10
    JGE no_space
    MOV AL, parkingSlots[SI]
    CMP AL, 0FFh                 ; Check for empty slot
    JE store_car
    INC SI
    JMP find_empty

store_car:
    ; ---------- Save car & hour info ----------
    MOV parkingSlots[SI], BL
    MOV parkingHours[SI], BH
    MOV lastAction, 1
    MOV [lastSlot], SI
    MOV lastCar, BL
    MOV lastHour, BH
    JMP main_menu

no_space:
    LEA DX, nospace
    MOV AH, 09h
    INT 21h
    JMP main_menu

; ---------- Leave a Car ----------
leave_car:
    LEA DX, slotMsg
    MOV AH, 09h
    INT 21h
    CALL get_single_digit        ; Input slot number
    MOV AH, 0
    MOV SI, AX

    MOV AL, parkingSlots[SI]
    CMP AL, 0FFh
    JE main_menu                 ; Already empty

    ; ---------- Calculate Fee  ----------
    MOV AL, parkingHours[SI]
    MOV BL, 32
    MUL BL              ; AX = Fee

    PUSH AX
    LEA DX, feeMsg
    MOV AH, 09h
    INT 21h
    POP AX
    CALL print_num      ; Print fee

    ; ---------- Save undo state ----------
    MOV lastAction, 2
    MOV [lastSlot], SI
    MOV AL, parkingSlots[SI]
    MOV lastCar, AL
    MOV AL, parkingHours[SI]
    MOV lastHour, AL

    ; ---------- Clear the slot ----------
    MOV parkingSlots[SI], 0FFh
    MOV parkingHours[SI], 0
    JMP main_menu

; ----------  Fee Calculator ----------
fee_calc:
    LEA DX, slotMsg
    MOV AH, 09h
    INT 21h
    CALL get_single_digit
    MOV AH, 0
    MOV SI, AX

    MOV AL, parkingSlots[SI]
    CMP AL, 0FFh
    JE main_menu

    MOV AL, parkingHours[SI]
    MOV BL, 32
    MUL BL

    PUSH AX
    LEA DX, feeMsg
    MOV AH, 09h
    INT 21h
    POP AX
    CALL print_num
    JMP main_menu

; ---------- Undo Last Action ----------
undo_action:
    CMP lastAction, 0
    JE main_menu
    CMP lastAction, 1
    JE undo_park
    CMP lastAction, 2
    JE undo_leave
    JMP main_menu

undo_park:
    MOV SI, [lastSlot]
    MOV parkingSlots[SI], 0FFh
    MOV parkingHours[SI], 0
    JMP undo_done

undo_leave:
    MOV SI, [lastSlot]
    MOV AL, lastCar
    MOV parkingSlots[SI], AL
    MOV AL, lastHour
    MOV parkingHours[SI], AL
    JMP undo_done

undo_done:
    LEA DX, undoMsg
    MOV AH, 09h
    INT 21h
    MOV lastAction, 0
    JMP main_menu

; ---------- Show Available Slots ----------
show_slots:
    XOR SI, SI
next_slot:
    CMP SI, 10
    JGE main_menu
    MOV AL, parkingSlots[SI]
    CMP AL, 0FFh
    JNE skip_print

    MOV AX, SI
    CALL print_num

    ; Print newline
    MOV DL, 13
    MOV AH, 02h
    INT 21h
    MOV DL, 10
    INT 21h

skip_print:
    INC SI
    JMP next_slot

; ----------  Search Car by ID ----------
search_car:
    LEA DX, parkMsg
    MOV AH, 09h
    INT 21h
    CALL get_single_digit
    MOV BL, AL

    XOR SI, SI
search_loop:
    CMP SI, 10
    JGE not_found_lbl
    MOV AL, parkingSlots[SI]
    CMP AL, BL
    JE found_lbl
    INC SI
    JMP search_loop

found_lbl:
    LEA DX, foundMsg
    MOV AH, 09h
    INT 21h
    MOV AX, SI
    CALL print_num

    ; Print newline
    MOV DL, 13
    MOV AH, 02h
    INT 21h
    MOV DL, 10
    INT 21h
    JMP main_menu

not_found_lbl:
    LEA DX, notFound
    MOV AH, 09h
    INT 21h
    JMP main_menu

; ---------- Exit ----------
exit_prog:
    LEA DX, exitMsg
    MOV AH, 09h
    INT 21h
    MOV AH, 4Ch
    INT 21h
MAIN ENDP

; ---------- Print number in AX ----------
print_num PROC NEAR
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX, 0
    JNE not_zero
    MOV DL, '0'
    MOV AH, 02h
    INT 21h
    JMP restore

not_zero:
    XOR CX, CX
divide_loop:
    XOR DX, DX
    MOV BX, 10
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE divide_loop

print_loop:
    POP DX
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    LOOP print_loop

restore:
    POP DX
    POP CX
    POP BX
    RET
print_num ENDP

; ---------- Flush keyboard buffer ----------
clear_input_buffer PROC NEAR
check_input:
    MOV AH, 0Bh
    INT 21h
    CMP AL, 0
    JE done_clear
    MOV AH, 08h
    INT 21h
    JMP check_input
done_clear:
    RET
clear_input_buffer ENDP

; ---------- Get single digit ----------
get_single_digit PROC NEAR
    CALL clear_input_buffer
    MOV AH, 01h
    INT 21h
    SUB AL, '0'   ; ASCII to integer
    RET
get_single_digit ENDP

END MAIN
