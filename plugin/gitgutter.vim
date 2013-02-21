command! -nargs=? -complete=file GitGutter :call gitgutter#git_gutter(<f-args>)

if has("autocmd")
	augroup gitgutter
		autocmd BufRead  * :GitGutter
		autocmd BufWrite * :GitGutter
	augroup END
endif
