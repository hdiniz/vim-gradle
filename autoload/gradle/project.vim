let s:projects = {}

" {{{ Project object API

let s:project = {
    \ 'last_sync': localtime(),
    \ 'open_buffers': 0,
    \ 'build_job': 0,
    \ 'build_buffer': 0,
    \ 'last_compile_args': []
    \ }

function! s:project.is_building() dict
    return type(self.build_job) == 8 && job_status(self.build_job) == "run"
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
    if self.build_buffer == 0
        below 10new
        let l:bufnr = bufnr('%')
        setlocal buftype=nofile nobuflisted noswapfile nonumber nowrap filetype=gradle-build
        let self.build_buffer = l:bufnr
        let b:gradle_project_root = self.root_folder
        let b:gradle_output_win = 1
        call gradle#utils#refresh_airline()
    else
        let l:winnr = bufwinnr(self.build_buffer)
        if l:winnr == -1
            exec 'below 10sp | b' . self.build_buffer
        else
            exec l:winnr.'wincmd w'
        endif
        if a:clean
            exec ':%d'
        endif
    endif
    execute 'file ' . self.root_folder .':\ gradle\ '. join(self.last_compile_args, '\ ')
endfunction

function! s:project.cmd() dict
    return self.wrapper != '' ? self.wrapper : gradle#cmd()
endfunction

function! s:project.compiler_callback(ch, msg) dict
    if string(a:msg) =~ 'DETACH'
        let l:errorformat = &errorformat
        let &errorformat = gradle#errorformat()
        exec 'cad ' . self.build_buffer
        let &errorformat = l:errorformat
        job_stop(self.build_job)
        call gradle#utils#refresh_airline()

        return
    endif
endfunction

function! s:project.compile(cmd, args) dict
    if self.is_building()
        echom "Please wait until current build is finished"
        return
    endif

    let l:compile_options = {
        \ 'in_mode': 'raw',
        \ 'out_mode': 'nl',
        \ 'err_mode': 'nl',
        \ 'in_io': 'null',
        \ 'out_io': 'buffer',
        \ 'err_io': 'null',
        \ 'stoponexit': 'term',
        \ 'callback': self.compiler_callback,
        \ }

    let self.last_compile_args = a:args
    call self.open_output_win(1)
    let l:compile_options['out_buf'] = self.build_buffer
    let self.build_job = job_start(a:cmd + a:args, l:compile_options)
    wincmd p

    call gradle#utils#refresh_airline()
endfunction

" }}}

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

" {{{ Private Functions

function! s:create_project(root_folder) abort
    let l:project = copy(s:project)
    call extend(l:project, {
        \ 'root_folder': a:root_folder,
        \ 'wrapper': s:wrapper(a:root_folder),
        \ 'last_sync': localtime(),
        \ 'build_file': s:build_file(a:root_folder)
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

"}}}

