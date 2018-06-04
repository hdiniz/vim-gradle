let s:save_cpo = &cpo
set cpo&vim

function! s:restore_cpo()
   let &cpo = s:save_cpo
   unlet s:save_cpo
endfunction

if exists("g:loaded_gradle")
    call s:restore_cpo()
    finish
endif

let g:loaded_gradle = 1

function! s:buffer_enter(auto)
    if a:auto == 1 && get(g:, "vim_gradle_autoload", 1) == 0
        return
    endif

    if get(b:, "gradle_project_root", '') != ''
        return
    endif

    let l:build_file_names = ['build.gradle', 'build.gradle.kts']
    let l:from = expand('%:p:h')
    if l:from == ''
        let l:from = getcwd()
    endif
    for l:build_file_name in l:build_file_names
        let b:gradle_project_root = s:find_project_root(l:from, l:build_file_name)
        if b:gradle_project_root != ''
            call gradle#load_project(b:gradle_project_root)
            return
        endif
    endfor
    if !a:auto
        echom "Gradle project not found"
    endif

endfunction

function! s:find_project_root(path, build_file_name)
    let l:build_file = findfile(a:build_file_name, a:path . ';$HOME')
    if l:build_file == ''
        return ''
    else
        let l:next_path = fnamemodify(l:build_file, ':p:h:h')
        let l:result = s:find_project_root(l:next_path, a:build_file_name)
        if l:result == ''
            return fnamemodify(l:build_file, ':p:h')
        else
            return l:result
    endif

endfunction

function! s:init_project(...)

    let l:cmd = gradle#cmd()
    if l:cmd == ''
        echom "Gradle binary not found"
        return
    endif

    exec '!'.l:cmd.' init '.join(a:000, ' ')
endfunction

function! s:init_project_wrapper(...)

    let l:cmd = gradle#cmd()
    if l:cmd == ''
        echom "Gradle binary not found"
        return
    endif

    exec '!'.l:cmd.' wrapper '.join(a:000, ' ')
endfunction


augroup gradle
    autocmd!
    autocmd BufEnter * call s:buffer_enter(1)
augroup END

command! GradleLoad call s:buffer_enter(0)
command! -nargs=* GradleInit call s:init_project(<f-args>)
command! -nargs=* GradleWrapper call s:init_project_wrapper(<f-args>)

call s:restore_cpo()

