if exists("b:current_syntax")
    finish
endif

let b:current_syntax = "gradle-build"

syntax region GradleInfo
    \ keepend oneline
    \ contains=GradleIdentifier,
    \ GradleTaskResultFailure,
    \ GradleTaskResultSkipped,
    \ GradleTaskResultUpToDate,
    \ GradleTaskResultNoSource
    \ start=/^>/ start=/^:/
    \ end=/$/

syntax region GradleIdentifier
     \ contained oneline
     \ start=/:/
     \ end=/\s/ end=/$/

syntax match GradleTaskResultFailure contained /FAILED/
syntax match GradleTaskResultSkipped contained /SKIPPED/
syntax match GradleTaskResultUpToDate contained /UP-TO-DATE/
syntax match GradleTaskResultNoSource contained /NO-SOURCE/

syntax match GradleBuildResultSuccessful /^BUILD SUCCESSFUL.*$/
syntax match GradleBuildResultFailed /^BUILD FAILED.*$/


hi! def link GradleInfo Comment
hi! def link GradleIdentifier Identifier
hi! def link GradleTaskResultFailure Special
hi! def link GradleTaskResultSkipped Comment
hi! def link GradleTaskResultUpToDate Comment
hi! def link GradleTaskResultNoSource Comment
hi! def link GradleBuildResultSuccessful Operator
hi! def link GradleBuildResultFailed Special

