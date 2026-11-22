section .data
    
    welcome_msg db "====== Welcome to the Coffee Shop ======", 10, 0
    menu_header db "Menu Options:", 10, 0
    ; Menu items with prices (in cents for integer calculations)
    item1 db "1. Espresso - $3.50", 10, 0
    item2 db "2. Cappuccino - $4.25", 10, 0
    item3 db "3. Latte - $4.75", 10, 0
    item4 db "4. Mocha - $5.00", 10, 0
    item5 db "5. Croissant - $2.50", 10, 0
    item6 db "6. Muffin - $3.00", 10, 0
    item7 db "7. Checkout", 10, 0
    item8 db "8. Cancel Order", 10, 0
    item9 db "9. Exit", 10, 0

    
    ; Item prices in cents
    prices dd 350, 425, 475, 500, 250, 300
    
    item_names db "Espresso   ", 0
              db "Cappuccino ", 0
              db "Latte      ", 0
              db "Mocha      ", 0
              db "Croissant  ", 0
              db "Muffin     ", 0
    
    quantities dd 0, 0, 0, 0, 0, 0
    
    ; Order messages
    order_prompt db "Enter item number (1-8): ", 0
    quantity_prompt db "Enter quantity: ", 0
    added_msg db "Added to order: ", 0
    invalid_msg db "Invalid selection! Please try again.", 10, 0
    subtotal_msg db "Subtotal: $", 0
    tax_msg db "Tax (8%): $", 0
    total_msg db "Total: $", 0
    
    receipt_header db "====== RECEIPT ======", 10, 0
    receipt_footer db "Thank you for your purchase!", 10, 0
    receipt_item db "x ", 0
    receipt_line db "-------------------------", 10, 0
    
    order_active db 1              ; 1 = active, 0 = inactive
    
    newline db 10, 0
    tax_rate dd 8                  ; 8% tax rate
    space db " ", 0
    
    ; Number formatting
    decimal_point db ".", 0
    hundred dd 100
    ten dd 10

section .bss
    input_buffer resb 32
    display_buffer resb 100
    
    subtotal resd 1
    tax_amount resd 1
    total_amount resd 1
    
    selected_item resd 1
    item_quantity resd 1
    

section .text
    global _start

_start:
    ; Display welcome message
    mov eax, 4
    mov ebx, 1
    mov ecx, welcome_msg
    call print_string
    
    call reset_order
    
    call process_orders
    
    ; Exit program
    mov eax, 1
    xor ebx, ebx
    int 0x80

print_string:
    push eax
    push ebx
    push edx
    
    mov edx, 0
    mov ebx, ecx
    
.count_loop:
    cmp byte [ebx], 0
    je .print_it
    inc ebx
    inc edx
    jmp .count_loop
    
.print_it:
    mov eax, 4
    mov ebx, 1
    int 0x80
    
    pop edx
    pop ebx
    pop eax
    ret

string_to_int:
    push ebx
    push edx
    
    xor eax, eax    ; Clear result
    
.convert_loop:
    movzx edx, byte [ecx]  ; Get current character
    
    ; Check for end of string or newline
    cmp edx, 0
    je .done
    cmp edx, 10    ; Newline
    je .done
    
    ; Check if digit
    cmp edx, '0'
    jl .skip
    cmp edx, '9'
    jg .skip
    
    ; Convert and add digit
    sub edx, '0'
    imul eax, 10
    add eax, edx
    
.skip:
    inc ecx
    jmp .convert_loop
    
.done:
    pop edx
    pop ebx
    ret

; Function to convert integer to string
int_to_string:
    push ecx
    push edx
    push esi
    push edi
    
    mov edi, ebx    ; Save buffer pointer
    mov esi, 10
    
    test eax, eax
    jnz .not_zero
    
    mov byte [ebx], '0'
    mov byte [ebx+1], 0
    jmp .done
    
.not_zero:
    ; Convert to string (backwards)
    mov ecx, ebx
    
.convert_loop:
    xor edx, edx
    div esi             ; Divide by 10
    add dl, '0'         ; Convert remainder to ASCII
    mov [ecx], dl       ; Store digit
    inc ecx
    test eax, eax
    jnz .convert_loop
    
    mov byte [ecx], 0
    
    ; Reverse the string
    mov esi, ebx
    dec ecx
    
.reverse_loop:
    cmp esi, ecx
    jge .done
    
    mov al, [esi]
    mov dl, [ecx]
    mov [esi], dl
    mov [ecx], al
    
    inc esi
    dec ecx
    jmp .reverse_loop
    
.done:
    pop edi
    pop esi
    pop edx
    pop ecx
    ret

; Function to format price (cents to dollars)
format_price:
    push ebx
    push ecx
    push edx
    
    ; Get dollars and cents
    xor edx, edx
    div dword [hundred]
    
    ; Format dollars
    mov ebx, display_buffer
    call int_to_string
    
    ; Add decimal point
    mov ebx, display_buffer
    xor ecx, ecx
    
.find_end:
    cmp byte [ebx+ecx], 0
    je .found_end
    inc ecx
    jmp .find_end
    
.found_end:
    mov byte [ebx+ecx], '.'
    inc ecx
    
    ; Format cents
    cmp edx, 10
    jge .no_leading_zero
    
    mov byte [ebx+ecx], '0'
    inc ecx
    
.no_leading_zero:
    ; Convert cents to string
    push eax
    mov eax, edx
    lea ebx, [display_buffer+ecx]
    call int_to_string
    pop eax
    
    pop edx
    pop ecx
    pop ebx
    ret

; Function to reset order variables
reset_order:
    mov dword [subtotal], 0
    mov dword [tax_amount], 0
    mov dword [total_amount], 0
    
    ; Reset quantities
    mov ecx, 6
    xor esi, esi
    
.reset_loop:
    mov dword [quantities + esi*4], 0
    inc esi
    loop .reset_loop
    
    ; Set order as active
    mov byte [order_active], 1
    
    ret

; Function to display menu and process orders
process_orders:
    ; Check if order is active
    cmp byte [order_active], 0
    je .exit_ordering
    
    ; Display menu header
    mov eax, 4
    mov ebx, 1
    mov ecx, menu_header
    call print_string
    
    ; Display menu items
    mov eax, 4
    mov ebx, 1
    mov ecx, item1
    call print_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, item2
    call print_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, item3
    call print_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, item4
    call print_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, item5
    call print_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, item6
    call print_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, item7
    call print_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, item8
    call print_string
    
    mov eax, 4
    mov ebx, 1
  mov ecx, item9
  call print_string
  
  ; Display current subtotal if items in order
    mov eax, [subtotal]
    cmp eax, 0
    je .prompt_order
    
    mov eax, 4
    mov ebx, 1
    mov ecx, subtotal_msg
    call print_string
    
    mov eax, [subtotal]
    call format_price
    
    mov eax, 4
    mov ebx, 1
    mov ecx, display_buffer
    call print_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    call print_string
    
.prompt_order:
    ; Prompt for order
    mov eax, 4
    mov ebx, 1
    mov ecx, order_prompt
    call print_string
    
    ; Get user input
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buffer
    mov edx, 32
    int 0x80
    
    ; Convert input to number
    mov ecx, input_buffer
    call string_to_int
    mov [selected_item], eax
    
    ; Check if valid selection
     cmp eax, 1
     jl .invalid_selection
     cmp eax, 9
     je .exit_program  ; Jump to exit if option 9 is selected
     cmp eax, 8
     jg .invalid_selection
    
    ; Process based on selection
    cmp eax, 7
    je .checkout
    cmp eax, 8
    je .cancel_order
    
    ; Regular item selection (1-6)
    ; Prompt for quantity
    mov eax, 4
    mov ebx, 1
    mov ecx, quantity_prompt
    call print_string
    
    ; Get quantity
    mov eax, 3
    mov ebx, 0
    mov ecx, input_buffer
    mov edx, 32
    int 0x80
    
    ; Convert quantity to number
    mov ecx, input_buffer
    call string_to_int
    mov [item_quantity], eax
    
    ; Check if valid quantity
    cmp eax, 1
    jl .invalid_selection
    
    ; Add items to order
    mov ecx, [selected_item]
    dec ecx                        ; Convert to 0-based index
    mov edx, [quantities + ecx*4]  ; Get current quantity
    add edx, [item_quantity]       ; Add new quantity
    mov [quantities + ecx*4], edx  ; Update quantity
    
    ; Update subtotal
    mov eax, [item_quantity]
    mul dword [prices + ecx*4]     ; Multiply by price
    add [subtotal], eax            ; Add to subtotal
    
    ; Display confirmation
    mov eax, 4
    mov ebx, 1
    mov ecx, added_msg
    call print_string
    
    ; Display quantity
    mov eax, [item_quantity]
    mov ebx, display_buffer
    call int_to_string
    
    mov eax, 4
    mov ebx, 1
    mov ecx, display_buffer
    call print_string
    
    ; Display "x "
    mov eax, 4
    mov ebx, 1
    mov ecx, receipt_item
    call print_string
    
    ; Display item name
    mov ecx, [selected_item]
    dec ecx                        ; Convert to 0-based index
    
    ; Calculate item name pointer
    mov esi, item_names
    imul ecx, 11                   ; Each name is 11 bytes
    add esi, ecx
    
    mov eax, 4
    mov ebx, 1
    mov ecx, esi
    mov edx, 10                    ; Length of item name
    int 0x80
    
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    call print_string
    
    ; Continue ordering
    jmp process_orders

.exit_program:
    ; Exit program
    mov eax, 1
    xor ebx, ebx
    int 0x80
    
.invalid_selection:
    mov eax, 4
    mov ebx, 1
    mov ecx, invalid_msg
    call print_string
    
    jmp process_orders

.exit_ordering:
    ; Handle exiting the ordering process
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    call print_string
    ret

.cancel_order:
    ; Handle canceling the order
    mov eax, 4
    mov ebx, 1
    mov ecx, invalid_msg
    call print_string
    call reset_order
    jmp process_orders

.checkout:
    ; Calculate tax
    mov eax, [subtotal]
    mov edx, 0
    mul dword [tax_rate]
    mov edx, 0
    div dword [hundred]        ; Divide by 100
    mov [tax_amount], eax

    ; Calculate total
    mov eax, [subtotal]
    add eax, [tax_amount]
    mov [total_amount], eax     ; Store total amount

    ; Print receipt header
    mov eax, 4
    mov ebx, 1
    mov ecx, receipt_header
    call print_string
    
    ; Print items ordered
    mov ecx, 6
    xor esi, esi
    
.print_items:
    mov eax, [quantities + esi*4]
    cmp eax, 0
    je .next_item
    
    ; Print quantity
    mov eax, [quantities + esi*4]
    mov ebx, display_buffer
    call int_to_string
    mov eax, 4
    mov ebx, 1
    mov ecx, display_buffer
    call print_string
    
    ; Print "x "
    mov eax, 4
    mov ebx, 1
    mov ecx, receipt_item
    call print_string
    
    ; Print item name
    mov edi, item_names
    imul esi, 11
    add edi, esi
    mov eax, 4
    mov ebx, 1
    mov ecx, edi
    mov edx, 10
    int 0x80
    
    ; Print newline
    mov eax, 4
    mov ebx, 1
    mov ecx, newline
    call print_string
    
.next_item:
    inc esi
    cmp esi, 6
    jl .print_items

    ; Print subtotal
    mov eax, 4
    mov ebx, 1
    mov ecx, subtotal_msg
    call print_string
    
    mov eax, [subtotal]
    call format_price
    mov eax, 4
    mov ebx, 1
    mov ecx, display_buffer
    call print_string

    ; Print tax
    mov eax, 4
    mov ebx, 1
    mov ecx, tax_msg
    call print_string
    
    mov eax, [tax_amount]
    call format_price
    mov eax, 4
    mov ebx, 1
    mov ecx, display_buffer
    call print_string

    ; Print total
    mov eax, 4
    mov ebx, 1
    mov ecx, total_msg
    call print_string
    
    mov eax, [total_amount]
    call format_price
    mov eax, 4
    mov ebx, 1
    mov ecx, display_buffer
    call print_string

    ; Print receipt footer
    mov eax, 4
    mov ebx, 1
    mov ecx, receipt_footer
    call print_string
    
    ; Exit ordering
    jmp .exit_ordering
