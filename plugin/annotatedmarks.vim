" Author: Wenzhi Liang <wenzhi.liang@gmail.com>
" Version: 0.1
"
" Vim script for enhancing the built-in marks functionality of vim. 
"
" It gives you a chance to associate some meaningful annotation with a particular mark,
" thus decreases the possibility of you getting lost amongst a large amount of codes.
" Also, it keeps track of which marks to use automatically: you don't have specify the
" name of mark. It uses global marks (A-Z) and tries to use an empty mark when possible.
" The first mark you add would be A, next would be B, etc. If all marks are used, it'll
" search for an least used one (provided that you use THIS script for jumping to it) and
" overwrite it.
" The information about marks are persistent so restarting Vim won't affect them.
"
" Usage:
" Pretty straight forward stuff.
" After installation (drop it in $RUNTIME/plugin), <Leader>M will add a new mark. You'll
" be prompted for a comment on this mark.
" :Amarks would list all marks known to this script and let you choose one to jump to.
"
" Configuration:
" g:am_persistent_file. String. Defines the file that this script writes to between vim sessions.
" g:am_use_popup_menu. 1 or 0. If it's 1, popup menu would be used, otherwise, echo would be used. 
"
" TODO:
" Add hilighting to output
"
"

"if exists('loaded_annotatedmarks')
  "finish
"endif
"
"let loaded_annotatedmarks = 1

" Configurables
if !has('g:am_persistent_file')
	if has('unix')
		let g:am_persistent_file = $HOME . '/.vim/Marks.txt'
	else
		let g:am_persistent_file = $HOME . '\_vim_marks.txt'
	endif
endif
if !has('g:am_use_popup_menu')
	let g:am_use_popup_menu = 0
endif

" gloabals
let s:first_mark = "A"
let s:last_mark = "Z"
let s:current_mark = s:last_mark
let s:dict = {}
let s:freq = {}
let s:full = 0

" functions
function! <SID>GoToMark( m )
	let str = "'" . a:m
	let s:freq[a:m] = s:freq[a:m] + 1
	exec "normal " . str
endfunction

function! <SID>NextMark( )
	let _count = 99999
	let slot = "$"
	if s:full 
		for k in keys(s:freq)
			if s:freq[k] < _count
				let slot = k
				let _count = s:freq[k]
			endif
		endfor
		let s:current_mark = slot
		return
	endif

	if s:current_mark == s:last_mark
		"In theory this should only happen for the first mark
		let s:current_mark = s:first_mark
	else
		let s:current_mark = nr2char(1 + char2nr(s:current_mark))
		if s:current_mark == s:last_mark
			let s:full = 1
		endif
	endif

endfunction

function! <SID>AddMark( )
	call <SID>NextMark()
	echohl Question
	let ans = input( "Annotation: " )
	echohl None
	let s:dict[s:current_mark] = printf("%s\t\t\t %s", ans, "{" . expand('%h') . " " . line('.') . "}")
	let s:freq[s:current_mark] = 0
	exec "normal m" . s:current_mark
endfunction

function! <SID>MarksPopup()
    " TODO: if the menu is empty, don't do anything
	aunmenu ]AM
	for k in keys( s:dict )
		exec "amenu ]AM.&" . tolower(k) . ":   " . escape(s:dict[k], " .") . " '" . k
	endfor
	popup ]AM
endfunction

function! <SID>MarksGui( )
    if (len(s:dict)==0)
        return
    endif

	if g:am_use_popup_menu == 1 && has('gui')
		call <SID>MarksPopup()
		return
	endif

	for k in keys( s:dict )
		echo tolower(k) . ": " . s:dict[k]
	endfor

	echohl Question
	let ans = input("Jump to: ")
	echohl None
	if ans == "" 
		return
	endif

	try
		call <SID>GoToMark( toupper(ans) )
	catch /E716/
		echo "\nInvalid mark."
	endtry
endfunction

function! <SID>Persistent()
	let lst = []
	for k in sort(keys(s:dict))
		call add( lst, s:dict[k] )
	endfor

	call writefile( lst,  g:am_persistent_file )
endfunction

function! <SID>ReadPersistent()
	try
		let lst = readfile( g:am_persistent_file)
		let key = s:first_mark
		" the written file is guaranteed to be sorted, without the key
		for l in lst
			let s:dict[key] = l
			let s:freq[key] = 0
			let key = nr2char( 1 + char2nr(key) )
			let s:current_mark = key
			if key == s:last_mark
				let s:full = 1
			endif
		endfor
	catch /E484/
		let foo=1
	endtry
endfunction


function! MarksManifest()
	echo "s:freq:"
	for k in keys(s:freq)
		echo "    " . k . ": " . s:freq[k]
	endfor
	echo "s:dict:"
	for k in keys(s:dict)
		echo "    " . k . ": " . s:dict[k]
	endfor
	echo "current mark: " . s:current_mark
	echo "full " . s:full
	call <SID>Persistent()
endfunction


"""""""""""""""""""""""""""""""""
" MAIN
"""""""""""""""""""""""""""""""""
call <SID>ReadPersistent()
nnoremap <silent> <Leader>M :call <SID>AddMark()<CR>
command! NewMark call <SID>AddMark()
command! Amarks call <SID>MarksGui()
au VimLeave * call <SID>Persistent()

"EoF
