let g:git_gutter_place = 2013
sign define change text=! texthl=SignColumn
sign define add    text=+ texthl=SignColumn
sign define delete text=_ texthl=SignColumn

" マーク行をリセットするために行数を保存する変数
if !exists('w:marked_line_num')
	let w:marked_line_num = 0
endif


" マークする
function! s:mark(name, begin, end)
	let i = str2nr(a:begin)
	let end = str2nr(a:end)
	while (i <= end)
		exe ":sign place " . g:git_gutter_place . " line=" . i . " name=" . a:name . " file=" . expand("%:p")
		let w:marked_line_num += 1
		let i += 1
	endwhile
endfunction


" マークをリセットする
function! s:reset_mark()
	if exists('w:marked_line_num')
		let i = 0
		while i <= w:marked_line_num
			exe ":sign unplace " . g:git_gutter_place
			let i += 1
		endwhile
	endif
	let w:marked_line_num = 0
endfunction


" 引数で渡されたファイルのコミット内容を取得する
function! s:get_commited_file(file)
	return system('git show HEAD:' . a:file)
endfunction


" 現在のファイル用の一時ファイルパス取得
function! s:get_current_file_path()
	return substitute(tempname(), '\', '/', 'g')
endfunction


" 現在のディレクトリがgitのリポジトリかどうか判定する
function! s:is_git_repos()
"	let ret = system('git rev-parse --is-inside-work-tree')[ : 3]
	let path = expand("%:r")
	let ret = system('git status ' . path . ' 2> /dev/null; echo $?')

	if ret
		return 0
	endif
	
	return 1
endfunction


" ファイルが編集済みかどうか判定
function! s:is_modified()
	redir => ret
		silent se modified?
	redir END

	let ret = ret[1: ] " 改行を削除
	if (ret == 'nomodified')
		return 0
	endif

	return 1
endfunction


" 現在のファイルとコミット済みファイルとのdiffを取得する
function! gitgutter#get_diff(current)
	let filename = expand("%")	" NOTE: %:p だとフルパス
	let commited = s:get_commited_file(filename)

	let diff = system('git show HEAD:' . filename . ' | diff - ' . a:current)
    return split(diff, '\n')
endfunction


" コミット済み情報とのdiffをマークする
function! gitgutter#git_gutter(...)
	" 編集中のファイルがgitリポジトリ下でなければ終了
	if (!s:is_git_repos())
"		throw "Error!! Here is not git repository."
		return
	endif

	" 編集中のファイルが未変更であれば終了
	if (!s:is_modified())
"		return
	endif

	" diffの取得
	if exists('a:1')
		" 引数があれば、それを比較対象にする
		let current = gitgutter#get_diff(a:1)
	else
		" 引数がなければ、現在のファイルを利用
		let current = s:get_current_file_path()
		silent execute 'write! ' . escape(current, ' ')
	endif
	let diff = gitgutter#get_diff(current)

	" マークをリセット
	call s:reset_mark()

	" diffを解析
	for line in diff
		" '12c24,25' といった行とマッチ
		let head_pattern = '^\([0-9]\+\),\?\([0-9]*\)\([acd]\)\([0-9]\+\),\?\([0-9]*\)$'
		if (match(line, head_pattern) >= 0)
			let [origin,before_begin,before_end,ope,after_begin,after_end;_] = matchlist(line, head_pattern)

			" endがない場合は1行のみマーク
			if (after_end == '')
				let after_end = after_begin
			endif

			" 追加の場合
			if (ope == 'a')
				call s:mark('add', after_begin, after_end)
			" 変更の場合
			elseif (ope == 'c')
				call s:mark('change', after_begin, after_end)
			" 削除の場合
			elseif (ope == 'd')
				" TODO 1行めを削除した場合、おかしくなる
				call s:mark('delete', after_begin, after_end)
			endif
		endif
	endfor
endfunction
