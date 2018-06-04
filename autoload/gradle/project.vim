let s:projects = {}

" {{{ Project object API

let s:project = {
    \ 'last_sync': localtime(),
    \ 'open_buffers': 0,
    \ 'build_job': 0,
    \ 'build_buffer': 0
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

function! s:project.cmd() dict
    return self.wrapper != '' ? self.wrapper : gradle#cmd()
endfunction

function! s:project.compiler_callback(ch, msg) dict
    if string(a:msg) =~ 'DETACH'
        let l:errorformat = &errorformat
        let &errorformat = gradle#errorformat()
        exec 'cad ' . self.build_buffer
        let &errorformat = l:errorformat
        let self.build_job = 0
        "let self.build_buffer = 0
        return
    endif
endfunction

function! s:project.create_compilation_window(args)
    if self.build_buffer == 0
        below 10new
        let s:bufnr = bufnr('%')
        setlocal buftype=nofile nobuflisted noswapfile nonumber nowrap filetype=gradle-build
        exec 'au BufDelete,BufHidden <buffer> call gradle#project#close_compilation_window("'.self.root_folder.'")'
    else
        exec bufwinnr(self.build_buffer) . 'wincmd w'
        exec 'b '.self.build_buffer
        exec 'normal! ggdG'
    endif
    execute 'file ' . substitute(self.root_folder . ': gradle ' . a:args , ' ', '\\ ', 'g')
    wincmd p
    return s:bufnr
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

function! gradle#project#close_compilation_window(root_folder)
    let l:project = gradle#project#get(a:root_folder)
    if l:project.build_buffer != 0
        exec 'bd '.l:project.build_buffer
        let l:project.build_buffer = 0
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

