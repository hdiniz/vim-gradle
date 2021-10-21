let s:script_path = tolower(resolve(expand('<sfile>:p:h')))
let s:gradle_folder_path = escape( expand( '<sfile>:p:h:h' ), '\' ) . '/gradle'

let s:default_vim_gradle_properties = {
    \ 'vim.gradle.enable.rtp': '1',
    \ 'vim.gradle.build.welcome': 'Built with vim-gradle plugin'
    \ }

let s:default_vim_gradle_extensions = [
    \ '"'.s:gradle_folder_path.'/java.gradle"',
    \ '"'.s:gradle_folder_path.'/kotlin.gradle"',
    \ '"'.s:gradle_folder_path.'/test.gradle"',
    \ ]

" {{{ Gradle API

function! gradle#load_project(root_project_folder) abort
    let l:project = gradle#project#get(a:root_project_folder)

    if type(l:project) == type({})
        call gradle#define_buffer_cmds()
        call gradle#utils#refresh_airline()
    endif
endfunction

function! gradle#cmd()
    if exists('g:vim_gradle_bin')
        return g:vim_gradle_bin
    endif

    if executable(s:gradle_home() . '/bin/gradle')
        return s:gradle_home() . '/bin/gradle'
    endif

    if executable('gradle')
        return 'gradle'
    endif

    return ''
endfunction

function! gradle#define_buffer_cmds()
    command! -buffer -nargs=+ Gradle w | call s:compile(<f-args>)
    command! -buffer GradleToggleOutputWin call gradle#project#current().toggle_output_win()
    command! -buffer GradleToggleTestsWin call gradle#project#current().toggle_tests_win()
endfunction

" }}}

" {{{ Private functions

function! s:compile(...) abort
    let l:project = gradle#project#current()

    let l:cmd = s:make_cmd()
    call l:project.compile(l:cmd, a:000)
endfunction

function! s:make_cmd()
    let l:project = gradle#project#current()
    return [
        \ l:project.cmd(),
        \ '--console',
        \ 'plain',
        \ '-I',
        \ s:gradle_folder_path . '/init.gradle',
        \ "-Pvim.gradle.apply=".s:extension_scripts(),
        \ '-b',
        \ l:project.build_file
        \ ] + s:vim_gradle_properties()
endfunction

function! s:gradle_home()
    if exists('g:vim_gradle_home')
        return g:vim_gradle_home
    endif

    if exists('$GRADLE_HOME')
        return $GRADLE_HOME
    endif
endfunction

function! s:vim_gradle_properties()

    let l:args = []
    for l:key in keys(s:default_vim_gradle_properties)
        let l:global_key = substitute(l:key, "\\.", "_", "g")
        let l:value = get(g:, l:global_key, get(s:default_vim_gradle_properties, l:key))
        let l:arg = '-P'.l:key.'='.l:value
        let l:args += [l:arg]
    endfor

    return l:args
endfunction

" https://github.com/vim-airline/vim-airline/blob/master/autoload/airline/extensions.vim
function! s:extension_scripts()
    let l:scripts =  copy(s:default_vim_gradle_extensions)
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
    return "[".join(l:scripts, ',')."]"
endfunction

" }}}

