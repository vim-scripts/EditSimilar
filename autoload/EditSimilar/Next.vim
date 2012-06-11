" EditSimilar/Next.vim: Custom completion for EditSimilar directory contents commands.
"
" DEPENDENCIES:
"   - EditSimilar.vim autoload script
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.002	11-Jun-2012	ENH: Allow passing custom fileargs / globs.
"   2.00.001	09-Jun-2012	file creation
let s:save_cpo = &cpo
set cpo&vim

" Next / Previous commands.
let s:pathSeparator = (exists('+shellslash') && ! &shellslash ? '\' : '/')
function! s:getDirectoryEntries( dirSpec, fileGlobs )
    let l:files = []

    " Get list of files, apply 'wildignore'.
    for l:fileGlob in a:fileGlobs
	let l:files += split(glob(a:dirSpec . s:pathSeparator . l:fileGlob), "\n")
    endfor

    " Remove . and .. pseudo-directories.
    call filter(l:files, 'v:val !~# "[\\\\/]\\.\\.\\?$"')

    return l:files
endfunction
function! s:ErrorMsg( text, fileGlobsString, ... )
    call EditSimilar#ErrorMsg(a:text . (empty(a:fileGlobsString) ? '' : ' matching ' . a:fileGlobsString) . (a:0 ? ': ' . a:1 : ''))
endfunction
function! EditSimilar#Next#Open( opencmd, isCreateNew, filespec, difference, direction, fileGlobsString )
    let l:dirSpec = fnamemodify(a:filespec, ':h')
    let l:dirSpec = (l:dirSpec ==# '.' ? '' : l:dirSpec)

    let l:fileGlobs = (empty(a:fileGlobsString) ? ['*'] : split(a:fileGlobsString, '\\\@<! '))
    let l:files = filter(s:getDirectoryEntries(l:dirSpec, l:fileGlobs), '! isdirectory(v:val)')

    let l:currentIndex = index(l:files, a:filespec)
    if l:currentIndex == -1
	if len(l:files) == 0
	    call s:ErrorMsg('No files in this directory', a:fileGlobsString)
	else
	    call s:ErrorMsg('Cannot locate current file', a:fileGlobsString, a:filespec)
	endif
	return
    elseif l:currentIndex == 0 && len(l:files) == 1
	call s:ErrorMsg('This is the sole file in the directory', a:fileGlobsString)
	return
    elseif l:currentIndex == 0 && a:direction == -1
	call s:ErrorMsg('No previous file', a:fileGlobsString)
	return
    elseif l:currentIndex == (len(l:files) - 1) && a:direction == 1
	call s:ErrorMsg('No next file', a:fileGlobsString)
	return
    endif

    " A passed difference of 0 means that no [count] was specified and thus
    " skipping over missing numbers is enabled.
    let l:difference = max([a:difference, 1])

    let l:offset = a:direction * l:difference
    let l:replacementIndex = l:currentIndex + l:offset
    let l:replacementIndex =
    \   max([
    \       min([l:replacementIndex, len(l:files) - 1]),
    \       0
    \   ])
    let l:replacementFilespec = l:files[l:replacementIndex]

    " Note: The a:isCreateNew flag has no meaning here, as all replacement
    " files do already exist.
    call EditSimilar#Open(a:opencmd, 0, 0, a:filespec, l:replacementFilespec, '')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
