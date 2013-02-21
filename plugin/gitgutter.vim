command! -nargs=0 GitGutter :call gitgutter#git_gutter()

if has("autocmd")
    augroup gitgutter
        autocmd BufRead  * :GitGutter
        autocmd BufWrite * :GitGutter
    augroup END
endif
