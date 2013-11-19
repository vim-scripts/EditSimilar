" EditSimilar/Root.vim: Custom completion for EditSimilar root (file extension)
" commands.
"
" DEPENDENCIES:
"   - EditSimilar.vim autoload script
"   - ingo/collections.vim autoload script
"   - ingo/fs/path.vim autoload script
"
" Copyright: (C) 2012-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.31.006	13-Jul-2013	FIX: Non-any completion can yield duplicate
"				roots, too (e.g. foobar.orig.txt + foobar.txt).
"				Use (sorted) unique function already in
"				s:Complete().
"   2.31.005	01-Jun-2013	Move ingofile.vim into ingo-library.
"   2.31.004	21-Feb-2013	Move ingocollections.vim to ingo-library.
"   2.10.003	26-Jul-2012	ENH: Complete file extensions for any files
"				found in the file's directory for those commands
"				that most of the time are used to create new
"				files; the default search for the current
"				filename's extensions won't yield anything
"				there. Add EditSimilar#Root#CompleteAny() for
"				that.
"   2.00.002	09-Jun-2012	Move EditSimilar#OpenRoot() here.
"	001	19-Jan-2012	file creation from plugin/EditSimilar.vim.
let s:save_cpo = &cpo
set cpo&vim

" Root (i.e. file extension) commands.
function! EditSimilar#Root#Open( opencmd, isCreateNew, filespec, newExtension )
    let [l:fullmatch, l:dots, l:newExtension; l:rest] = matchlist(a:newExtension, '\(^\.*\)\(.*$\)')

    " Each leading '.' removes one file extension from the original filename; a
    " single dot is optional.
    let l:rootRemovalNum = (strlen(l:dots) > 1 ? strlen(l:dots) : 1)

    let l:newFilespec = fnamemodify(a:filespec, repeat(':r', l:rootRemovalNum)) . (! empty(l:newExtension) ? '.' . l:newExtension : '')
    call EditSimilar#Open( a:opencmd, a:isCreateNew, 1, a:filespec, l:newFilespec, fnamemodify(l:newFilespec, ':t'))
endfunction

function! s:Complete( ArgLead, filenameGlob )
    return ingo#collections#UniqueSorted(sort(
    \	filter(
    \	    map(
    \		split(
    \		    glob(a:filenameGlob . '.' . a:ArgLead . '*'),
    \		    "\n"
    \		),
    \		'fnamemodify(v:val, ":e")'
    \	    ),
    \	    'v:val !=# ' . string(expand('%:e'))
    \	)
    \))
    " Note: No need for fnameescape(); the Root commands don't support Vim
    " special characters like % and # and therefore do the escaping themselves.
endfunction

function! EditSimilar#Root#Complete( ArgLead, CmdLine, CursorPos )
    return s:Complete(a:ArgLead, expand('%:r'))
endfunction

function! EditSimilar#Root#CompleteAny( ArgLead, CmdLine, CursorPos )
    return s:Complete(a:ArgLead, ingo#fs#path#Combine(expand('%:h'), '*'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
