" ex) source % | LifeGame

command! LifeGame call s:initialize() | call s:main()

let s:WIDTH  = 20
let s:HEIGHT = 20
let s:FPS = 60
let s:MAX_ITERATION = 10000

let s:CELL = 'c'
let s:EMPTY = '.'

function! s:initialize()
    tabnew
    setlocal filetype=lifegame buftype=nofile
    setlocal nolist nocursorline nonumber norelativenumber nowrap

    let s:WIDTH = winwidth(winnr())
    let s:HEIGHT = winheight(winnr())

    execute 'syntax match LifeGameDead "' . s:EMPTY . '"'
    execute 'syntax match LifeGameLive "' . s:CELL  . '"'
    highlight LifeGameLive ctermfg=Green ctermbg=Green guifg=#00ff00 guibg=#00ff00
    highlight LifeGameDead ctermfg=Black ctermbg=Black guifg=#000000 guibg=#000000
endfunction

function! s:fuzzy_random()
    return reltime()[1]
endfunction

function! s:generate_random_board(width, height)
    let board = {}
    for i in range(a:height * a:width)
        if (s:fuzzy_random() % 2) == 0
            let board[i] = s:CELL
        endif
    endfor
    return board
endfunction

function! s:get_position(x, y)
    return a:x + (a:y * (s:WIDTH))
endfunction

function! s:show(board)
    let buf = []
    for i in range(s:WIDTH * s:HEIGHT)
        call add(buf, s:EMPTY)
    endfor
    for pos in keys(a:board)
        if 0 <= pos && pos < len(buf)
            let buf[pos] = s:CELL
        endif
    endfor
    for y in range(s:HEIGHT)
        let begin = s:get_position(0, y)
        let end = s:get_position(s:WIDTH-1, y)
        call setline(y+1, join(buf[begin : end], ''))
    endfor
endfunction

function! s:get_exist_cells(board, cells)
    "存在するセルをリストで返却する"
    let exists = []
    for c in a:cells
        if has_key(a:board, c)
            call add(exists, c)
        endif
        " 4-8 はルール上同じ意味なので抜ける
        if 4 <= len(exists)
            return exists
        endif
    endfor
    return exists
endfunction

function! s:get_neighbors(cell)
    "周囲8セルのポジションをリストで返却する"
    let neighbors = []
    for y in range(-1, 1, 1)
        for x in range(-1, 1, 1)
            if 0 == x && 0 == y
                continue
            endif
            call add(neighbors, a:cell + s:get_position(x, y))
        endfor
    endfor
    return neighbors
endfunction

function! s:is_live(cell, board)
    let neighbors = s:get_neighbors(a:cell)
    let exists = len(s:get_exist_cells(a:board, neighbors))
    if 3 == exists
        return 1
    endif
    if len(s:get_exist_cells(a:board, [a:cell]))
        if 2 <= exists && exists <= 3
            return 1
        endif
    endif
endfunction

function! s:generation(board)
    let next_board = {}
    let memo = {}
    for origin in keys(a:board)
        for cell in s:get_neighbors(origin)
            if (s:WIDTH * s:HEIGHT) <= cell || cell < 0
                continue
            endif
            if has_key(memo, cell)
                continue
            endif
            let is_live = s:is_live(cell, a:board)
            let memo[cell] = is_live
            if is_live
                let next_board[cell] = s:CELL
            endif
        endfor
    endfor
    return next_board
endfunction

function! s:sleep(fps)
    execute 'sleep ' . (1000 / a:fps) . 'm'
endfunction

function! s:main()
    let board = s:generate_random_board(s:WIDTH, s:HEIGHT)
    for i in range(1, s:MAX_ITERATION, 1)
        let start = reltime()
        redraw
        let board = s:generation(board)
        call s:show(board)
        let elapse = reltimestr(reltime(start))
        let fps = 1.0 / str2float(elapse)
        "call s:sleep(s:FPS)
        echo "iteration: " . i . ", cells: " . len(board) . ", fps: " . string(fps)
    endfor
endfunction
