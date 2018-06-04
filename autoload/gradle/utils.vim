function! gradle#utils#refresh_airline()
    if exists(':AirlineRefresh')
        exec 'AirlineRefresh'
    endif
endfunction
