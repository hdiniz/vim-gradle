let s:projects = {}

let s:project = {
    \ 'last_sync': localtime(),
    \ 'open_buffers': 0,
    \ 'build_job': 0,
    \ 'build_buffer': 0,
    \ 'tests_buffer': 0,
    \ 'quickfix_file': '',
    \ 'gradle_log_file': '',
    \ 'tests_file': '',
    \ 'last_compile_args': []
    \ }

" {{{ Project API

function! gradle#project#get(root_folder) abort
    if has_key(s:projects, a:root_folder)
        return get(s:projects, a:root_folder)
    else
        return s:create_project(a:root_folder)
    endif
endfunction

function! gradle#project#current()
    if exists('b:gradle_project_root')
        return gradle#project#get(b:gradle_project_root)
    else
        return v:null
    endif
endfunction

" }}}

" {{{ Project Object API

function! s:project.is_building() dict
    if has('nvim')
        return self.build_job != 0
    else
        return type(self.build_job) == 8
    endif
endfunction

function! s:project.open_file(path) dict
    let self.open_buffers += 1
endfunction

function! s:project.close_file(path) dict
    let self.open_buffers -= 1
endfunction

function! s:project.toggle_output_win() dict
    if bufwinnr(self.build_buffer) != -1
        call self.close_output_win()
    else
        call self.open_output_win(0)
    endif
endfunction

function! s:project.close_output_win() dict
    let l:winnr = bufwinnr(self.build_buffer)
    if l:winnr != -1
        exec l:winnr.'wincmd c'
    endif
endfunction

function! s:project.open_output_win(clean) dict

    let l:opts = {
        \ 'buffer_nr': self.build_buffer,
        \ 'filetype': 'gradle-build',
        \ 'position': 'belowright',
        \ 'size': '10',
        \ 'relative_to': self.tests_buffer,
        \ 'alternative_name': self.root_folder .':\ gradle\ '. join(self.last_compile_args, '\ '),
        \ }

    let self.build_buffer = gradle#utils#create_win_for(l:opts)
    let b:gradle_project_root = self.root_folder
    let b:gradle_output_win = 1
    call gradle#define_buffer_cmds()
    call gradle#utils#refresh_airline()

    if a:clean
        exec ':%d'
    endif

endfunction

function! s:project.toggle_tests_win() dict
    if bufwinnr(self.tests_buffer) != -1
        call self.close_tests_win()
    else
        call self.open_tests_win(0)
    endif
endfunction

function! s:project.close_tests_win() dict
    let l:winnr = bufwinnr(self.tests_buffer)
    if l:winnr != -1
        exec l:winnr.'wincmd c'
    endif
endfunction

function! s:project.open_tests_win(clean) dict
    if a:clean && self.tests_buffer != 0
        exec 'bd! '.self.tests_buffer
        let self.tests_buffer = 0
    endif
    let l:opts = {
        \ 'buffer_nr': self.tests_buffer,
        \ 'filetype': 'gradle-test-result',
        \ 'position': 'belowright',
        \ 'size': '10',
        \ 'relative_to': self.build_buffer,
        \ 'modifiers': 'nomodifiable',
        \ 'filename': self.tests_file,
        \ 'alternative_name': self.root_folder .':\ test\ results\',
        \ }

    if filereadable(self.tests_file)
        let self.tests_buffer = gradle#utils#create_win_for(l:opts)
        let b:gradle_project_root = self.root_folder
        let b:gradle_tests_win = 1
        call gradle#define_buffer_cmds()
        call gradle#utils#refresh_airline()
    endif
endfunction

function! s:project.cmd() dict
    return self.wrapper != '' ? self.wrapper : gradle#cmd()
endfunction

function! s:project.compiler_callback(ch, msg) dict
endfunction

function! s:project.compiler_exited(job, status) dict
    call self.compilation_done()
endfunction

function! s:project.compilation_done() dict
    let l:errorformat = &errorformat
    let &errorformat = "%t:\ %f:%l:%c\ %m,%t:\ %f:%l\ %m,%t:\ %f\ %m"
    exec 'cgetfile ' . self.quickfix_file
    let &errorformat = l:errorformat
    let self.build_job = 0
    call self.open_tests_win(1)
    call gradle#utils#refresh_airline()
endfunction


function! s:project.compiler_out(ch, msg) dict
endfunction

function! s:project.compile(cmd, args) dict
    if self.is_building()
        echom "Please wait until current build is finished"
        return
    endif

    if has('nvim')
        let l:compile_options = {
            \ 'on_stdout': function('s:nvim_job_out'),
            \ 'on_stderr': function('s:nvim_job_out'),
            \ 'on_exit': function('s:nvim_job_exit'),
            \ 'root_folder': self.root_folder,
            \ }
    else
        let l:compile_options = {
            \ 'in_mode': 'raw',
            \ 'out_mode': 'nl',
            \ 'err_mode': 'nl',
            \ 'in_io': 'null',
            \ 'out_io': 'buffer',
            \ 'err_io': 'out',
            \ 'stoponexit': 'term',
            \ 'out_cb': self.compiler_out,
            \ 'exit_cb': self.compiler_exited,
            \ 'callback': self.compiler_callback,
            \ }
    endif

    let self.last_compile_args = a:args
    let self.quickfix_file = tempname()
    let self.gradle_log_file = tempname()
    let self.tests_file = tempname()
    let l:additional_args = [
        \ '-Pvim.gradle.tests.file='.self.tests_file,
        \ '-Pvim.gradle.quickfix.file='.self.quickfix_file,
        \ '-Pvim.gradle.log.file='.self.gradle_log_file
        \ ]
    cclose
    call self.open_output_win(1)
    let l:compile_options['out_buf'] = self.build_buffer
    if has('nvim')
        let self.build_job = jobstart(a:cmd + a:args + l:additional_args, l:compile_options)
    else
        let self.build_job = job_start(a:cmd + a:args + l:additional_args, l:compile_options)
    endif
    wincmd p

    call gradle#utils#refresh_airline()
endfunction

" }}}

" {{{ Private Functions

function! s:create_project(root_folder) abort
    let l:project = copy(s:project)
    call extend(l:project, {
        \ 'root_folder': a:root_folder,
        \ 'wrapper': s:wrapper(a:root_folder),
        \ 'last_sync': localtime(),
        \ 'build_file': s:build_file(a:root_folder),
        \ 'build_folder': s:build_folder(a:root_folder)
        \ })

    let s:projects[a:root_folder] = l:project
    return l:project
endfunction

function! s:wrapper(root_folder)
    let l:ext = ''
    if has('win32') || has('win64')
        let l:ext = '.bat'
    endif
    let l:wrapper = a:root_folder . '/gradlew' . l:ext
    if filereadable(l:wrapper)
        return l:wrapper
    endif
    return ''
endfunction

function! s:build_file(root_folder) abort
    for l:file in ['/build.gradle', '/build.gradle.kts']
        if filereadable(a:.root_folder . l:file)
            return a:root_folder . l:file
        endif
    endfor
    throw 'Build file for project ' . a:root_folder  . ' not found'
endfunction

function! s:build_folder(root_folder) abort
    for l:file in ['/build.gradle', '/build.gradle.kts']
        if filereadable(a:.root_folder . l:file)
            return a:root_folder
        endif
    endfor
    throw 'Build folder for project ' . a:root_folder  . ' not found'
endfunction
"}}}

"{{{ NeoVim

" NeoVim uses jobstart {opts} as `self` dict in callback
function! s:nvim_job_out(ch, msg, event) dict
    call nvim_buf_set_lines(self.out_buf, -1, -1, v:true, a:msg)
endfunction

function! s:nvim_job_exit(job, data, event) dict
    let l:project = gradle#project#get(self.root_folder)
    call l:project.compilation_done()
endfunction

"}}}
