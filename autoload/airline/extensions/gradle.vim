let s:spc = g:airline_symbols.space

function! airline#extensions#gradle#condition_build()
    let l:project_root = get(b:, 'gradle_project_root', '')
    if l:project_root != ''
        return gradle#project#current().is_building()
    else
        return 0
    endif
endfunction

function! airline#extensions#gradle#init(ext)
    call airline#parts#define_text('gradle_glyph', 'G')
    call airline#parts#define_accent('gradle_glyph', 'bold')
    call airline#parts#define_condition('gradle_glyph', "get(b:, 'gradle_project_root') != ''")

    call airline#parts#define_text('gradle_build_glyph', 'building..')
    call airline#parts#define_accent('gradle_build_glyph', 'bold')
    call airline#parts#define_condition('gradle_build_glyph', 'airline#extensions#gradle#condition_build()')

    call a:ext.add_statusline_func('airline#extensions#gradle#statusline_func')
    call a:ext.add_inactive_statusline_func('airline#extensions#gradle#inactive_statusline_func')
endfunction


function! s:statusline(...)
    let l:ctx = a:2
    let l:is_output_win = getbufvar(l:ctx.bufnr, 'gradle_output_win', 0)

    if l:is_output_win
        let l:b = a:1
        call l:b.add_raw('%f')
        call l:b.split()
        return 1
    elseif get(b:, 'gradle_project_root', '') != ''
        let w:airline_section_y = airline#section#create_right(['ffenc', 'gradle_glyph', 'gradle_build_glyph'])
    endif
endfunction

function! airline#extensions#gradle#inactive_statusline_func(...)
    return call(function('s:statusline'), a:000)
endfunction

function! airline#extensions#gradle#statusline_func(...)
    return call(function('s:statusline'), a:000)
endfunction

