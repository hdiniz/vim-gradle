let s:spc = g:airline_symbols.space
function! airline#extensions#gradle#init(ext)
    call airline#parts#define_text('gradle', 'G')
    call airline#parts#define_accent('gradle', 'bold')

    let l:b = airline#builder#new({'active': 1})
    call l:b.add_section_spaced('gradle_title', 'Gradle')
    call l:b.split()
    let s:gradle_build_airline = call b.build()

    call a:ext.add_statusline_func('airline#extensions#gradle#apply')
endfunction

function! airline#extensions#gradle#apply(...)
    if get(b:, 'gradle_project_root') != ''
        let w:airline_section_y = airline#section#create_right(['ffenc','gradle'])
    endif

    if &filetype == 'gradle-build'
        echom "buuil"
    endif

endfunction

function! airline#extensions#gradle#GetProject()
    return "Gradle"
endfunction

