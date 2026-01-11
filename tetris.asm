; ---------------------------------------------------------------------------
; TETRIS.EXE (MASM 16-bit, Intel 8086)
;

.8086
.model small
.stack 100h

PREVIEW_X  EQU 12
PREVIEW_Y  EQU 4      

.data

tick_counter       dw 0
score              dw 0
game_over          db 0
seed               dw 0

board              db 200 dup(0)

current_piece      db 0
current_rotation   db 0
current_x          db 0
current_y          db 0

next_piece         db 0

temp_color         db 0

pieces_data:
    ; I
    db 0,0,0,0, 1,1,1,1, 0,0,0,0, 0,0,0,0
    db 0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0
    db 0,0,0,0, 1,1,1,1, 0,0,0,0, 0,0,0,0
    db 0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0

    ; J
    db 1,0,0,0, 1,1,1,0, 0,0,0,0, 0,0,0,0
    db 0,1,1,0, 0,1,0,0, 0,1,0,0, 0,0,0,0
    db 0,0,0,0, 1,1,1,0, 0,0,1,0, 0,0,0,0
    db 0,1,0,0, 0,1,0,0, 1,1,0,0, 0,0,0,0

    ; L
    db 0,0,1,0, 1,1,1,0, 0,0,0,0, 0,0,0,0
    db 0,1,0,0, 0,1,0,0, 0,1,1,0, 0,0,0,0
    db 0,0,0,0, 1,1,1,0, 1,0,0,0, 0,0,0,0
    db 1,1,0,0, 0,1,0,0, 0,1,0,0, 0,0,0,0

    ; O
    db 0,1,1,0, 0,1,1,0, 0,0,0,0, 0,0,0,0
    db 0,1,1,0, 0,1,1,0, 0,0,0,0, 0,0,0,0
    db 0,1,1,0, 0,1,1,0, 0,0,0,0, 0,0,0,0
    db 0,1,1,0, 0,1,1,0, 0,0,0,0, 0,0,0,0

    ; S
    db 0,1,1,0, 1,1,0,0, 0,0,0,0, 0,0,0,0
    db 0,1,0,0, 0,1,1,0, 0,0,1,0, 0,0,0,0
    db 0,0,0,0, 0,1,1,0, 1,1,0,0, 0,0,0,0
    db 1,0,0,0, 1,1,0,0, 0,1,0,0, 0,0,0,0

    ; T
    db 0,1,0,0, 1,1,1,0, 0,0,0,0, 0,0,0,0
    db 0,1,0,0, 0,1,1,0, 0,1,0,0, 0,0,0,0
    db 0,0,0,0, 1,1,1,0, 0,1,0,0, 0,0,0,0
    db 0,1,0,0, 1,1,0,0, 0,1,0,0, 0,0,0,0

    ; Z
    db 1,1,0,0, 0,1,1,0, 0,0,0,0, 0,0,0,0
    db 0,0,1,0, 0,1,1,0, 0,1,0,0, 0,0,0,0
    db 0,0,0,0, 1,1,0,0, 0,1,1,0, 0,0,0,0
    db 0,1,0,0, 1,1,0,0, 1,0,0,0, 0,0,0,0
    db 0,1,0,0, 1,1,0,0, 1,0,0,0, 0,0,0,0

game_over_msg      db 'GAME OVER!', 13, 10, '$'
score_msg          db 'Score (Lines): $'
restart_msg        db 'Press SPACE to Restart, or ESC for Menu.$'

menu_title         db '=== TETRIS ===', 13, 10, 13, 10, '$'
menu_opt1          db 'Press SPACE to Start Game', 13, 10, '$'
menu_opt2          db 'Press ESC to Exit', 13, 10, '$'

ingame_score_msg   db 'Score: ', 0

.code

main PROC
    mov  ax, @data
    mov  ds, ax
    cld

main_menu:
    mov  ax, 0003h
    int  10h

    mov  ah, 09h
    mov  dx, OFFSET menu_title
    int  21h
    mov  dx, OFFSET menu_opt1
    int  21h
    mov  dx, OFFSET menu_opt2
    int  21h

menu_wait:
    mov  ah, 00h
    int  16h
    cmp  al, ' '
    je   start_game
    cmp  ah, 01h
    je   exit_program
    jmp  menu_wait

start_game:
    mov  ax, 0013h
    int  10h

    mov  ah, 00h
    int  1Ah
    mov  seed, dx

    call init_game

game_loop:
    call check_input
    call update_game
    call render_game

    mov  cx, 1
    call delay_ticks

    cmp  game_over, 1
    je   exit_game
    jmp  game_loop

exit_game:
    mov  ax, 0003h
    int  10h

    mov  ah, 09h
    mov  dx, OFFSET game_over_msg
    int  21h

    mov  ah, 09h
    mov  dx, OFFSET score_msg
    int  21h

    mov  ax, score
    call print_num

    mov  ah, 02h
    mov  dl, 13
    int  21h
    mov  dl, 10
    int  21h

    mov  ah, 09h
    mov  dx, OFFSET restart_msg
    int  21h

wait_restart:
    mov  ah, 00h
    int  16h
    cmp  al, ' '
    je   start_game
    cmp  ah, 01h
    je   main_menu
    jmp  wait_restart

exit_program:
    mov  ax, 4C00h
    int  21h
main ENDP

init_game PROC
    lea  di, board
    mov  cx, 200
    xor  al, al
ig_clear:
    mov  [di], al
    inc  di
    loop ig_clear

    mov  score, 0
    mov  game_over, 0
    mov  tick_counter, 0

    call generate_next_piece
    call spawn_piece
    ret
init_game ENDP

generate_next_piece PROC
    call rand
    mov  bx, 7
    xor  dx, dx
    div  bx
    mov  next_piece, dl
    ret
generate_next_piece ENDP

spawn_piece PROC
    mov  dl, next_piece
    mov  current_piece, dl

    mov  current_rotation, 0
    mov  current_x, 3
    mov  current_y, 0

    call generate_next_piece

    call check_collision
    test ax, ax
    jnz  set_game_over
    ret
spawn_piece ENDP

set_game_over PROC
    mov  game_over, 1
    ret
set_game_over ENDP

check_input PROC
    mov  ah, 01h
    int  16h
    jz   ci_done

    mov  ah, 00h
    int  16h

    cmp  ah, 01h
    je   set_game_over

    cmp  ah, 4Bh
    je   ci_left
    cmp  ah, 4Dh
    je   ci_right
    cmp  ah, 48h
    je   ci_rotate
    cmp  ah, 50h
    je   ci_down
    cmp  al, ' '
    je   ci_rotate
    jmp  ci_done

ci_left:
    dec  current_x
    call check_collision
    test ax, ax
    jz   ci_done
    inc  current_x
    jmp  ci_done

ci_right:
    inc  current_x
    call check_collision
    test ax, ax
    jz   ci_done
    dec  current_x
    jmp  ci_done

ci_rotate:
    mov  al, current_rotation
    mov  bl, al
    inc  al
    and  al, 3
    mov  current_rotation, al
    call check_collision
    test ax, ax
    jz   ci_done
    mov  current_rotation, bl
    jmp  ci_done

ci_down:
    inc  current_y
    call check_collision
    test ax, ax
    jz   ci_done
    dec  current_y

ci_done:
    ret
check_input ENDP

update_game PROC
    inc  tick_counter
    cmp  tick_counter, 5
    jl   ug_done

    mov  tick_counter, 0
    inc  current_y
    call check_collision
    test ax, ax
    jz   ug_done

    dec  current_y
    call lock_piece
    call check_lines
    call spawn_piece

ug_done:
    ret
update_game ENDP

check_collision PROC
    push bx
    push cx
    push dx
    push si
    push di

    mov  al, current_piece
    mov  bl, current_rotation
    call get_piece_offset

    xor  ch, ch
cc_row:
    xor  cl, cl
cc_col:
    mov  al, [si]
    test al, al
    jz   cc_next

    mov  al, current_x
    add  al, cl
    mov  dl, al

    mov  al, current_y
    add  al, ch
    mov  dh, al

    cmp  dl, 10
    jge  cc_hit
    cmp  dh, 20
    jge  cc_hit

    xor  ax, ax
    push dx
    mov  al, dh
    mov  bl, 10
    mul  bl
    xor  dh, dh
    add  ax, dx
    mov  di, ax
    pop  dx

    cmp  di, 200
    jge  cc_hit
    cmp  byte ptr [board + di], 0
    jne  cc_hit

cc_next:
    inc  si
    inc  cl
    cmp  cl, 4
    jl   cc_col
    inc  ch
    cmp  ch, 4
    jl   cc_row

    xor  ax, ax
    jmp  cc_out

cc_hit:
    mov  ax, 1

cc_out:
    pop  di
    pop  si
    pop  dx
    pop  cx
    pop  bx
    ret
check_collision ENDP

lock_piece PROC
    mov  al, current_piece
    mov  bl, current_rotation
    call get_piece_offset

    xor  ch, ch
lp_row:
    xor  cl, cl
lp_col:
    mov  al, [si]
    test al, al
    jz   lp_next

    mov  al, current_y
    add  al, ch
    mov  bl, 10
    mul  bl

    xor  bh, bh
    mov  bl, current_x
    add  bl, cl
    add  ax, bx

    mov  di, ax
    cmp  di, 200
    jge  lp_next

    mov  dl, current_piece
    inc  dl
    mov  [board + di], dl

lp_next:
    inc  si
    inc  cl
    cmp  cl, 4
    jl   lp_col
    inc  ch
    cmp  ch, 4
    jl   lp_row
    ret
lock_piece ENDP

check_lines PROC
    mov  bx, 19
cl_row:
    cmp  bx, 0
    jl   cl_done

    mov  cx, 10
    mov  ax, bx
    mov  dx, 10
    mul  dx
    mov  di, ax
    add  di, OFFSET board

cl_scan:
    cmp  byte ptr [di], 0
    je   cl_not_full
    inc  di
    loop cl_scan

    call remove_row
    inc  score
    jmp  cl_row

cl_not_full:
    dec  bx
    jmp  cl_row

cl_done:
    ret
check_lines ENDP

remove_row PROC
    push bx
    mov  cx, bx

rr_loop:
    test cx, cx
    jz   rr_clear0

    mov  ax, cx
    mov  dx, 10
    mul  dx
    mov  di, ax
    sub  ax, 10
    mov  si, ax

    add  si, OFFSET board
    add  di, OFFSET board

    push ds
    pop  es

    push cx
    mov  cx, 10
    rep  movsb
    pop  cx

    dec  cx
    jmp  rr_loop

rr_clear0:
    push ds
    pop  es
    mov  di, OFFSET board
    mov  cx, 10
    xor  al, al
    rep  stosb

    pop  bx
    ret
remove_row ENDP

; ---- RENDERING ----

render_next_piece PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov  al, next_piece
    mov  bl, 0
    call get_piece_offset

    xor  ch, ch
rnp_row:
    xor  cl, cl
rnp_col:
    mov  al, [si]
    test al, al
    jz   rnp_empty

    mov  al, next_piece
    inc  al

    push cx
    mov  dl, PREVIEW_X
    add  dl, cl
    mov  dh, PREVIEW_Y
    add  dh, ch
    mov  cl, dl
    mov  ch, dh
    call draw_block_at_grid
    pop  cx
    jmp  rnp_next

rnp_empty:
    xor  al, al
    push cx
    mov  dl, PREVIEW_X
    add  dl, cl
    mov  dh, PREVIEW_Y
    add  dh, ch
    mov  cl, dl
    mov  ch, dh
    call draw_block_at_grid
    pop  cx

rnp_next:
    inc  si
    inc  cl
    cmp  cl, 4
    jl   rnp_col

    inc  ch
    cmp  ch, 4
    jl   rnp_row

    pop  si
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret
render_next_piece ENDP

render_game PROC
    mov  ah, 02h
    mov  bh, 0
    xor  dx, dx
    int  10h

    lea  si, ingame_score_msg
    call print_str_bios
    mov  ax, score
    call print_num

    push es
    mov  ax, 0A000h
    mov  es, ax

    mov  di, 63680 + 110
    mov  cx, 100
    mov  al, 15
    rep  stosb

    mov  cx, 200
    mov  di, 109
    mov  si, 210
    mov  al, 15
rg_sides:
    mov  es:[di], al
    mov  es:[si], al
    add  di, 320
    add  si, 320
    loop rg_sides

    pop  es

    ; Draw board
    xor  bx, bx
    xor  ch, ch
rg_row:
    xor  cl, cl
rg_col:
    mov  al, [board + bx]
    test al, al
    jz   rg_empty

    call draw_block_at_grid
    jmp  rg_next

rg_empty:
    xor  al, al
    call draw_block_at_grid

rg_next:
    inc  bx
    inc  cl
    cmp  cl, 10
    jl   rg_col
    inc  ch
    cmp  ch, 20
    jl   rg_row

    ; Draw current piece
    mov  al, current_piece
    mov  bl, current_rotation
    call get_piece_offset

    xor  ch, ch
rp_row:
    xor  cl, cl
rp_col:
    mov  al, [si]
    test al, al
    jz   rp_next

    mov  dl, current_x
    add  dl, cl
    mov  dh, current_y
    add  dh, ch

    mov  al, current_piece
    inc  al

    push cx
    mov  cl, dl
    mov  ch, dh
    call draw_block_at_grid
    pop  cx

rp_next:
    inc  si
    inc  cl
    cmp  cl, 4
    jl   rp_col
    inc  ch
    cmp  ch, 4
    jl   rp_row

    call render_next_piece

    ret
render_game ENDP

draw_block_at_grid PROC
    mov  temp_color, al

    push ax
    push bx
    push cx
    push dx
    push di
    push es

    mov  ax, 0A000h
    mov  es, ax

    xor  bx, bx
    mov  bl, cl
    mov  dx, 10
    mov  ax, bx
    mul  dx
    add  ax, 110
    mov  di, ax

    xor  bx, bx
    mov  bl, ch
    mov  ax, bx
    mov  dx, 10 
    
    mul  dx           
    mov  dx, 320
    mul  dx             
    add  di, ax

    mov  al, temp_color
    and  al, 0Fh

    mov  dx, 9
    mov  bx, 320
dbg_line:
    mov  cx, 9
    rep  stosb
    add  di, bx
    sub  di, 9
    dec  dx
    jnz  dbg_line

    pop  es
    pop  di
    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret
draw_block_at_grid ENDP

print_num PROC
    push ax
    push bx
    push cx
    push dx

    xor  cx, cx
    mov  bx, 10
pn_div:
    xor  dx, dx
    div  bx
    push dx
    inc  cx
    test ax, ax
    jnz  pn_div

pn_out:
    pop  dx
    add  dl, '0'
    push cx
    mov  al, dl
    mov  ah, 0Eh
    mov  bl, 15
    int  10h
    pop  cx
    dec  cx
    jnz  pn_out

    pop  dx
    pop  cx
    pop  bx
    pop  ax
    ret
print_num ENDP

print_str_bios PROC
    push ax
    push bx
    push si
psb:
    mov  al, [si]
    test al, al
    jz   psb_done
    mov  ah, 0Eh
    mov  bl, 15
    int  10h
    inc  si
    jmp  psb
psb_done:
    pop  si
    pop  bx
    pop  ax
    ret
print_str_bios ENDP

delay_ticks PROC
    push es
    mov  ax, 0040h
    mov  es, ax
    mov  si, 006Ch
dt_loop:
    mov  ax, es:[si]
dt_wait:
    cmp  ax, es:[si]
    je   dt_wait
    loop dt_loop
    pop  es
    ret
delay_ticks ENDP

rand PROC
    mov  ax, seed
    mov  dx, 31821
    mul  dx
    add  ax, 13849
    mov  seed, ax
    ret
rand ENDP

get_piece_offset PROC
    xor  ah, ah
    mov  si, ax
    mov  cl, 6
    shl  si, cl         

    xor  bh, bh
    mov  ax, bx
    mov  cl, 4
    shl  ax, cl         
    add  si, ax

    add  si, OFFSET pieces_data
    ret
get_piece_offset ENDP

END main
