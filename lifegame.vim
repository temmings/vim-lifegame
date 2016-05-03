" ex) source % | LifeGame

command! LifeGame call s:initialize() | call s:main()

let s:WIDTH  = 20
let s:HEIGHT = 20
let s:FPS = 60
let s:MAX_ITERATION = 10000

let s:LIVE = '*'
let s:DEAD = ' '
let s:SENTINEL = '|'

function! s:initialize()
    new
    setlocal filetype=lifegame buftype=nofile
    setlocal nolist nocursorline nonumber norelativenumber nowrap

    let s:WIDTH = winwidth(winnr())
    let s:HEIGHT = winheight(winnr())

    execute 'syntax match LifeGameDead "' . s:DEAD . '"'
    execute 'syntax match LifeGameLive "' . s:LIVE  . '"'
    highlight LifeGameLive ctermfg=Green ctermbg=Green guifg=#00ff00 guibg=#00ff00
    highlight LifeGameDead ctermfg=Black ctermbg=Black guifg=#000000 guibg=#000000
endfunction

function! s:random()
    " http://stackoverflow.com/a/12739441
    return str2nr(matchstr(reltimestr(reltime()), '\v\.@<=\d+')[1:])
endfunction

function! s:generate_random_board(width, height)
    let cells = [s:LIVE, s:DEAD]
    let board = []
    for y in range(a:height)
        for x in range(a:width-1)
            let cell = cells[s:random() % len(cells)]
            call add(board, cell)
        endfor
        call add(board, s:SENTINEL)
    endfor
    return board
endfunction

function! s:show_board(board)
    for y in range(s:HEIGHT)
        let begin = s:get_position(0, y)
        let end = s:get_position(s:WIDTH - 1, y)
        call setline(y+1, join(a:board[begin : end], ''))
    endfor
endfunction

function! s:exist_cell(cell)
    return a:cell == s:LIVE
endfunction

function! s:get_position(x, y)
    "return a:y * (s:WIDTH + 1) + a:x " 横幅は番兵分+ 1
    return a:y * s:WIDTH + a:x
endfunction

function! s:count_neighbors(board, x, y)
    let target = [
        \ s:get_position(a:x - 1, a:y - 1), s:get_position(a:x, a:y - 1), s:get_position(a:x + 1, a:y - 1),
        \ s:get_position(a:x - 1, a:y)    ,                               s:get_position(a:x + 1, a:y),
        \ s:get_position(a:x - 1, a:y + 1), s:get_position(a:x, a:y + 1), s:get_position(a:x + 1, a:y + 1)]
    let n = 0
    for pos in target
        let n += s:exist_cell(get(a:board, pos, ''))
        " 隣接数 4～8 は同じ意味なので、打ち切る
        if 4 <= n
            return n
        endif
    endfor
    return n
endfunction

function! s:is_birth(cell, neighbors)
    return a:cell == s:DEAD && a:neighbors == 3
endfunction

function! s:is_dead(cell, neighbors)
    return a:cell == s:LIVE && (a:neighbors != 2 && a:neighbors != 3)
endfunction

function! s:generation(board, x, y)
    let pos = s:get_position(a:x, a:y)
    let cell = a:board[pos]
    if cell == s:SENTINEL
        return s:SENTINEL
    endif
    let neighbors = s:count_neighbors(a:board, a:x, a:y)
    "echo 'pos:' . pos . ' cell:' . cell . ' neighbors:' . neighbors . ' x:' . a:x . ' y:' . a:y
    if s:is_birth(cell, neighbors)
        return s:LIVE
    elseif s:is_dead(cell, neighbors)
        return s:DEAD
    endif
    return cell
endfunction

function! s:forward(board)
    let forwarded_board = []
    for y in range(s:HEIGHT)
        for x in range(s:WIDTH)
            call add(forwarded_board, s:generation(a:board, x, y))
        endfor
    endfor
    return forwarded_board
endfunction

function! s:sleep(fps)
    execute 'sleep ' . (1000 / a:fps) . 'm'
endfunction

function! s:main()
    let board = s:generate_random_board(s:WIDTH, s:HEIGHT)
    for i in range(1, s:MAX_ITERATION, 1)
        let start = reltime()
        let board = s:forward(board)
        call s:show_board(board)
        redraw
        let elapse = reltimestr(reltime(start))
        let fps = 1.0 / str2float(elapse)
        echo "iteration: " . i . ", cells: " . len(board) . ", fps: " . string(fps)
        "call s:sleep(s:FPS)
    endfor
endfunction
