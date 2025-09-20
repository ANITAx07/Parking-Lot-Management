org 100h
jmp start

; ---------- DATA ----------
parkingSlots db 10 dup(0)
parkingHours db 10 dup(0)

lastAction db 0
lastSlot   dw 0
lastCar    db 0
lastHour   db 0

menu db 13,10,'--- Parking System Menu ---',13,10
     db '1. Park a Car',13,10
     db '2. Leave a Car',13,10
     db '3. Fee Calculator',13,10
     db '4. Undo Last Action',13,10
     db '5. Show Available Slots',13,10
     db '6. Search Car',13,10
     db '7. Exit',13,10
     db 'Choose: $'

parkMsg   db 13,10,'Enter Car ID (0-9): $'
dupCarMsg db 13,10,'Car ID already parked!$'
hourMsg   db 13,10,'Enter Hours (1-9): $'
slotMsg   db 13,10,'Enter Slot Number (0-9): $'
feeMsg    db 13,10,'Parking Fee = $'
foundMsg  db 13,10,'Car found at Slot: $'
notFound  db 13,10,'Car not found!$'
undoMsg   db 13,10,'Last action undone.$'
nospace   db 13,10,'No space available!$'
exitMsg   db 13,10,'Exiting Program...$'

; ---------- CODE ----------
start:
    push cs
    pop ds

main_menu:
    call clear_input_buffer
    lea dx, menu
    mov ah, 09h
    int 21h

    call get_single_digit

    cmp al, 1
    je park_car
    cmp al, 2
    je leave_car
    cmp al, 3
    je fee_calc
    cmp al, 4
    je undo_action
    cmp al, 5
    je show_slots
    cmp al, 6
    je search_car
    cmp al, 7
    je exit_prog
    jmp main_menu

; ---------- PARK ----------
park_car:
    lea dx, parkMsg
    mov ah, 09h
    int 21h
    call get_single_digit
    mov bl, al

    xor si, si    
    
check_duplicate:
    cmp si, 10
    je no_duplicate
    mov al, parkingSlots[si]
    cmp al, bl
    je duplicate_found
    inc si
    jmp check_duplicate

duplicate_found:
    lea dx, dupCarMsg
    mov ah, 09h
    int 21h
    jmp main_menu

no_duplicate:
    lea dx, hourMsg
    mov ah, 09h
    int 21h
    call get_single_digit
    mov bh, al

    xor si, si  
    
find_empty:
    cmp si, 10
    jge no_space
    mov al, parkingSlots[si]
    cmp al, 0
    je store_car
    inc si
    jmp find_empty

store_car:
    mov parkingSlots[si], bl
    mov parkingHours[si], bh
    mov lastAction, 1
    mov [lastSlot], si
    mov lastCar, bl
    mov lastHour, bh
    jmp main_menu

no_space:
    lea dx, nospace
    mov ah, 09h
    int 21h
    jmp main_menu  
    

; ---------- LEAVE ----------
leave_car:
    lea dx, slotMsg
    mov ah, 09h
    int 21h
    call get_single_digit
    mov ah, 0
    mov si, ax

    mov al, parkingSlots[si]
    cmp al, 0
    je main_menu

    mov al, parkingHours[si]
    mov bl, 10
    mul bl

    lea dx, feeMsg
    mov ah, 09h
    int 21h
    call print_num

    mov lastAction, 2
    mov [lastSlot], si
    mov al, parkingSlots[si]
    mov lastCar, al
    mov al, parkingHours[si]
    mov lastHour, al

    mov parkingSlots[si], 0
    mov parkingHours[si], 0
    jmp main_menu

; ---------- FEE CALCULATOR ----------
fee_calc:
    lea dx, slotMsg
    mov ah, 09h
    int 21h
    call get_single_digit
    mov ah, 0
    mov si, ax

    mov al, parkingSlots[si]
    cmp al, 0
    je main_menu

    mov al, parkingHours[si]
    mov bl, 10
    mul bl

    lea dx, feeMsg
    mov ah, 09h
    int 21h
    call print_num
    jmp main_menu

; ---------- UNDO ----------
undo_action:
    cmp lastAction, 0
    je main_menu
    cmp lastAction, 1
    je undo_park
    cmp lastAction, 2
    je undo_leave
    jmp main_menu

undo_park:
    mov si, [lastSlot]
    mov parkingSlots[si], 0
    mov parkingHours[si], 0
    jmp undo_done

undo_leave:
    mov si, [lastSlot]
    mov al, lastCar
    mov parkingSlots[si], al
    mov al, lastHour
    mov parkingHours[si], al
    jmp undo_done

undo_done:
    lea dx, undoMsg
    mov ah, 09h
    int 21h
    mov lastAction, 0
    jmp main_menu

; ---------- SHOW SLOTS ----------
show_slots:
    xor si, si 
    
next_slot:
    cmp si, 10
    jge main_menu
    mov al, parkingSlots[si]
    cmp al, 0
    jne skip_print

    mov ax, si
    call print_num

    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h

skip_print:
    inc si
    jmp next_slot

; ---------- SEARCH ----------
search_car:
    lea dx, parkMsg
    mov ah, 09h
    int 21h
    call get_single_digit
    mov bl, al

    xor si, si
search_loop:
    cmp si, 10
    jge not_found_lbl
    mov al, parkingSlots[si]
    cmp al, bl
    je found_lbl
    inc si
    jmp search_loop

found_lbl:
    lea dx, foundMsg
    mov ah, 09h
    int 21h
    mov ax, si
    call print_num

    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    jmp main_menu

not_found_lbl:
    lea dx, notFound
    mov ah, 09h
    int 21h
    jmp main_menu

; ---------- EXIT ----------
exit_prog:
    lea dx, exitMsg
    mov ah, 09h
    int 21h
    mov ah, 4Ch
    int 21h

; ---------- PRINT NUMBER ----------
print_num:
    xor ah, ah
    mov bl, 10
    div bl
    cmp al, 0
    je skip_tens
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h 
    
skip_tens:
    mov al, ah
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    ret

; ---------- FLUSH KEYBOARD BUFFER (correct method) ----------
clear_input_buffer:
    mov ah, 0Bh       ; Check for input
    int 21h
    cmp al, 0
    je .done
    mov ah, 08h       ; Read (no echo)
    int 21h
    jmp clear_input_buffer
.done:
    ret

; ---------- GET CLEAN SINGLE DIGIT INPUT ----------
get_single_digit:
    call clear_input_buffer
    mov ah, 01h
    int 21h           ; Read and echo
    sub al, '0'
    ret 
    
    
.wait_flush:
    mov ah, 0Bh
    int 21h
    cmp al, 0
    je .done_flush
    mov ah, 08h
    int 21h
    jmp .wait_flush

.done_flush:
    ret