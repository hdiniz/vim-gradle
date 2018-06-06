function! gradle#utils#refresh_airline()
    if exists(':AirlineRefresh')
        exec 'AirlineRefresh'
        exec 'redrawstatus'
    endif
endfunction

"
" position
" size
" buffer_nr
" relative_to
" relative_position
" filename
" alternative_name
" filetype
" modifiers
function! gradle#utils#create_win_for(opt)
    let l:position = get(a:opt, 'position', 'below')
    let l:size = get(a:opt, 'size', '')
    let l:buffer_nr = get(a:opt, 'buffer_nr', 0)
    let l:relative_to = get(a:opt, 'relative_to', 0)
    let l:relative_position = get(a:opt, 'relative_position', 'vertical')
    let l:relative_size = get(a:opt, 'relative_size', '')
    let l:filename = get(a:opt, 'filename', '')
    let l:alternative_name = get(a:opt, 'alternative_name', '')
    let l:filetype = get(a:opt, 'filetype', '')
    let l:modifiers = get(a:opt, 'modifiers', '')

    let l:has_relative = l:relative_to != 0 && bufwinnr(l:relative_to) != -1
    let l:cur_win = winnr()

    let l:open_cmd = 'new'
    if l:filename != ''
        let l:open_cmd = 'sp '.l:filename
    endif

    let l:position_and_size = l:position.' '.l:size.' '
    if l:has_relative
        let l:position_and_size = l:relative_position.' '.l:position.' '.l:relative_size
    endif

    if l:has_relative
        exec bufwinnr(l:relative_to).'wincmd w'
    endif

    if l:buffer_nr == 0
        exec l:position_and_size.' '.l:open_cmd
        silent! setlocal buftype=nofile nobuflisted noswapfile nonumber nowrap
        exec 'silent! setlocal '.l:modifiers
        exec 'silent! setlocal filetype='.l:filetype
        if l:alternative_name != ''
            execute 'silent! file '.l:alternative_name
        endif
        let l:buffer_nr = bufnr('%')
    else
        let l:winnr = bufwinnr(l:buffer_nr)
        if l:winnr != -1
            exec l:winnr.'wincmd w'
        else
            exec l:position_and_size.'sp'
            exec 'b'. l:buffer_nr
        endif
    endif

    if l:has_relative
        exec l:cur_win.'wincmd w'
        exec bufwinnr(l:buffer_nr).'wincmd w'
    endif

    return l:buffer_nr

endfunction
