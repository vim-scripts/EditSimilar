" EditSimilar/Root.vim: Custom completion for EditSimilar root (file extension)
" commands. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	19-Jan-2012	file creation from plugin/EditSimilar.vim. 
let s:save_cpo = &cpo
set cpo&vim

function! EditSimilar#Root#Complete( ArgLead, CmdLine, CursorPos )
    return 
    \	filter(
    \	    map(
    \		split(
    \		    glob(expand('%:r') . '.' . a:ArgLead . '*'),
    \		    "\n"
    \		),
    \		'fnamemodify(v:val, ":e")'
    \	    ),
    \	    'v:val !=# ' . string(expand('%:e'))
    \	)
    " Note: No need for fnameescape(); the Root commands don't support Vim
    " special characters like % and # and therefore do the escaping themselves. 
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
