let current_compiler = 'gradle'

exec 'CompilerSet makeprg=' . gradle#makeprg()
exec 'CompilerSet errorformat=' . gradle#errorformat()
