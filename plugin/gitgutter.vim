command! -nargs=0 GitGutter :call gitgutter#git_gutter()

if has("autocmd")
    if !get(g:, 'no_auto_gitgutter', 0)
        augroup gitgutter
            autocmd BufRead  * :GitGutter
            autocmd BufWrite * :GitGutter
        augroup END
    endif
endif
