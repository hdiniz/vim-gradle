let s:script_path = tolower(resolve(expand('<sfile>:p:h')))
let s:gradle_folder_path = escape( expand( '<sfile>:p:h:h' ), '\' ) . '/gradle'

" {{{ Gradle API

function! gradle#load_project(root_project_folder) abort

    let l:project = gradle#project#get(a:root_project_folder)

    if l:project.cmd() != ''
        exec 'compiler gradle'
        command! -buffer -nargs=+ -bang Gradle call s:compile(<bang>0, <f-args>)
    else
        throw "Gradle command not found"
    endif

    if exists(':AirlineRefresh')
        exec 'AirlineRefresh'
    endif
endfunction


function! gradle#cmd()
    if exists('g:vim_gradle_bin')
        return g:vim_gradle_bin
    endif

    if finddir(s:gradle_home()) && executable(s:gradle_home() . '/bin/gradle')
        return s:gradle_home() . '/bin/gradle'
    endif

    if executable('gradle')
        return 'gradle'
    endif

    return ''

endfunction

" }}}

" {{{ VIM Compiler API

function! gradle#makeprg()
    return substitute(substitute(join(s:make_cmd(1), ' '), ' ', '\\ ', 'g'), '"', '\\"', 'g')
endfunction

function! gradle#errorformat()
    let l:efm = "%-G%[\\\s]%#,"
    let l:efm .= "lint:\\\ %tarning\\\ %f:%l:%c\\\ %m,"     "lint
    let l:efm .= "lint:\\\ %trror\\\ %f:%l:%c\\\ %m,"       "lint
    let l:efm .= "%+G%m\\\ FAILED,"                         "task failed
    let l:efm .= "%+GBUILD\\\ FAILED,"                      "build failed
    let l:efm .= "%-G:%.%#,"                                "ignore task list
    let l:efm .= "%-GNote:%.%#,"                            "ignore Notes
    let l:efm .= "%t:\\\ warning:\\\ %m,"                   "kotlin general warning
    let l:efm .= "%t:\\\ %f:\\\ (%l\\\\,\\\ %c):\\\ %m,"    "kotlin
    let l:efm .= "%t:\\\ %f:%l:\\\ %m,"                     "kotlin
    let l:efm .= "%t:\\\ %f\\\ %m,"                         "kotlin
    let l:efm .=  "%-G%.%#"                                 "ignore rest
    return l:efm
endfunction

function! s:make_cmd(make)
    let l:project = gradle#project#current()
    return [
        \ l:project.cmd(),
        \ '--console',
        \ 'plain',
        \ '-I',
        \ s:gradle_folder_path . '/init.gradle',
        \ "-Pvim.apply=".s:extension_scripts(a:make),
        \ '-b',
        \ l:project.build_file
        \ ] + s:vim_gradle_properties(a:make)
endfunction

" }}}

" {{{ Private functions

function! s:log(msg)
    echomsg a:msg
endfunction

function! s:open_compilation_window(project, args)
    if a:project.build_buffer == 0
        below 10new
        let b:gradle_project = a:project
        let s:bufnr = bufnr('%')
        setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nonumber nowrap filetype=gradle-build
    else
		exec bufwinnr(a:project.build_buffer) . 'wincmd w'
        exec 'b '.a:project.build_buffer
        exec 'normal! ggdG'
    endif
    execute 'file ' . substitute(a:project.root_folder . ': gradle ' . a:args , ' ', '\\ ', 'g')
    wincmd p
    return s:bufnr
endfunction

function! s:gradle_home()
    if exists('g:vim_gradle_home')
        return g:vim_gradle_home
    endif

    if exists('$GRADLE_HOME')
        return $GRADLE_HOME
    endif
endfunction

function! s:compile(async, ...) abort
    let l:project = gradle#project#current()

    let l:args = join(a:000, ' ')
    if a:async != ''
        call s:log('Compiling: ' . l:args)
        exec 'make ' . join(a:000, ' ')
    else
        let l:compile_options = {
            \ 'in_mode': 'raw',
            \ 'out_mode': 'nl',
            \ 'err_mode': 'nl',
            \ 'in_io': 'null',
            \ 'out_io': 'buffer',
            \ 'err_io': 'null',
            \ 'stoponexit': 'term',
            \ 'callback': l:project.compiler_callback,
            \ }

        if l:project.is_building()
            call s:log("Please wait until current build is finished")
            return
        endif

        let l:cmd = s:make_cmd(0) + a:000
        echom string(l:cmd)

        let l:escaped = substitute(join(l:cmd, ' '), '\\', '\', 'g')
        let l:escaped = substitute(l:escaped, '\"', '"', 'g')
        echom l:escaped

        let l:project.build_buffer = s:open_compilation_window(l:project, l:args)
        let l:compile_options['out_buf'] = l:project.build_buffer
        let l:project.build_job = job_start(l:cmd, l:compile_options)

    endif
endfunction

" }}}

" {{{ Extension functions

" https://github.com/vim-airline/vim-airline/blob/master/autoload/airline/extensions.vim

let s:default_vim_gradle_properties = {
    \ 'vim.gradle.enable.rtp': '1',
    \ 'vim.gradle.build.welcome': 'Built with vim-gradle plugin'
    \ }

function! s:vim_gradle_properties(make)

    let l:args = []
    for l:key in keys(s:default_vim_gradle_properties)
        let l:global_key = substitute(l:key, "\\.", "_", "g")
        let l:value = get(g:, l:global_key, get(s:default_vim_gradle_properties, l:key))
        if a:make
            let l:value = substitute(l:value, ' ', '\\\\ ', 'g')
        endif
        let l:arg = '-P'.l:key.'='.l:value
        let l:args += [l:arg]
    endfor

    return l:args
endfunction

function! s:extension_scripts(make)
    let l:scripts = []
    for l:file in split(globpath(&rtp, 'autoload/gradle/extensions/*.vim'), '\n')
        if stridx(tolower(resolve(fnamemodify(file, ':p'))), s:script_path) < 0
            \ && stridx(tolower(fnamemodify(file, ':p')), s:script_path) < 0
        let l:name = fnamemodify(l:file, ':t:r')
        try
            for l:script in gradle#extensions#{l:name}#build_scripts()
               let l:scripts += ['"'.l:script.'"']
            endfor
        catch
        endtry
      endif
    endfor
    if a:make
        return "'[".join(l:scripts, ',')."]'"
    else
        return "[".join(l:scripts, ',')."]"
    endif
endfunction

" }}}

