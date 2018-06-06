if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "gradle-test-result"

function! s:is_test_output(lnum)
    return getline(a:lnum) =~ '\v^\s.*\>.*$'
endfunction

function! GradleTestFoldText()
    let l:line = getline(v:foldstart)
    if s:is_test_output(v:foldstart)
        return getline(v:foldstart).repeat(' ', winwidth(0) - len(l:line))
    endif

    let l:test_indent = indent(v:foldstart)
    let l:current_line = v:foldstart
    let l:current_indent = indent(l:current_line)
    let l:tests = 0
    while l:current_line <= v:foldend
        let l:current_indent = indent(l:current_line)
        if l:current_indent == l:test_indent
           let l:tests += 1
        endif
        let l:current_line += 1
    endwhile
    let l:text = repeat(' ', l:test_indent).l:tests." tests"
    return l:text.repeat(' ', winwidth(0) - len(l:text))
endfunction

function! GradleTestFoldLevel(lnum)
    if a:lnum == 1
        return -1
    endif

    return indent(a:lnum) / 4
endfunction

setlocal foldtext=GradleTestFoldText()
setlocal foldexpr=GradleTestFoldLevel(v:lnum)
setlocal foldmethod=expr foldcolumn=5 nonumber

syntax match GradleTestResultSkipped  '\v\d+ SKIPPED'
syntax match GradleTestResultSuccess '\v\d+/\d+ SUCCESS'
syntax match GradleTestResultFailure '\v\d+/\d+ FAILURE'
syntax match GradleTestSuiteDesc '\v\w+\@\w+'
syntax match GradleTestResultDesc '\v\w+\@\w+:'
syntax region GradleTestResultOutput start='\v\>' end='$'

syntax keyword GradleTestFailure FAILURE
syntax keyword GradleTestSkipped SKIPPED
syntax keyword GradleTestSuccess SUCCESS

hi! def link GradleTestFailure Special
hi! def link GradleTestSuccess Statement
hi! def link GradleTestSkipped Comment
hi! def link GradleTestResultSuccess Statement
hi! def link GradleTestResultFailure Special
hi! def link GradleTestResultSkipped Comment
hi! def link GradleTestResultDesc Identifier
hi! def link GradleTestSuiteDesc Comment
hi! def link GradleTestResultOutput Comment

