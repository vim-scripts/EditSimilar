" EditSimilar/OverBuffer.vim: summary
"
" DEPENDENCIES:
"   - ingo/err.vim autoload script
"
" Copyright: (C) 2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.40.001	24-Mar-2014	file creation

function! EditSimilar#OverBuffer#Save( command, isBang, arguments )
    try
	execute a:command a:arguments
	return 1
    catch /^Vim\%((\a\+)\)\=:E139/ " E139: File is loaded in another buffer
	if a:isBang
	    try
		execute 'bdelete!' a:arguments
		execute a:command a:arguments
		return 1
	    catch /^Vim\%((\a\+)\)\=:/
		call ingo#err#SetVimException()
		return 0
	    endtry
	else
	    call ingo#err#SetVimException()
	    return 0
	endif
    catch /^Vim\%((\a\+)\)\=:/
	call ingo#err#SetVimException()
	return 0
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
