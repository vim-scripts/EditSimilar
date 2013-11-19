" EditSimilar/Next.vim: Custom completion for EditSimilar directory contents commands.
"
" DEPENDENCIES:
"   - EditSimilar.vim autoload script
"   - ingo/fs/path.vim autoload script
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2012-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.31.006	26-Jun-2013	Replace duplicated functions with
"				ingo/fs/path.vim.
"   2.31.005	14-Jun-2013	Replace EditSimilar#ErrorMsg() with
"				ingo#msg#ErrorMsg().
"   2.01.003	12-Jun-2012	FIX: To avoid issues with differing forward
"				slash / backslash path separator components,
"				canonicalize the glob pattern and filespec. This
"				avoids a "Cannot locate current file" error when
"				there is a mismatch.
"   2.00.002	11-Jun-2012	ENH: Allow passing custom fileargs / globs.
"   2.00.001	09-Jun-2012	file creation
let s:save_cpo = &cpo
set cpo&vim

" Next / Previous commands.
function! EditSimilar#Next#GetDirectoryEntries( dirSpec, fileGlobs )
    let l:files = []

    " Get list of files, apply 'wildignore'.
    for l:fileGlob in a:fileGlobs
	let l:files += split(glob(ingo#fs#path#Combine(a:dirSpec, l:fileGlob)), "\n")
	" Note: No need to normalize here; glob() always returns results with
	" the default path separator.
    endfor

    " Remove . and .. pseudo-directories.
    call filter(l:files, 'v:val !~# "[\\\\/]\\.\\.\\?$"')

    return l:files
endfunction
function! s:ErrorMsg( text, fileGlobsString, ... )
    call ingo#msg#ErrorMsg(a:text . (empty(a:fileGlobsString) ? '' : ' matching ' . a:fileGlobsString) . (a:0 ? ': ' . a:1 : ''))
endfunction
function! EditSimilar#Next#Open( opencmd, isCreateNew, filespec, difference, direction, fileGlobsString )
    " To be able to find the current filespec in the glob results with a simple
    " string compare, canonicalize all path separators to what Vim is internally
    " using, i.e. depending on the 'shellslash' option.
    let l:dirSpec = ingo#fs#path#Normalize(fnamemodify(a:filespec, ':h'))
    let l:dirSpec = (l:dirSpec ==# '.' ? '' : l:dirSpec)

    let l:fileGlobs = (empty(a:fileGlobsString) ? ['*'] : split(a:fileGlobsString, '\\\@<! '))
    let l:files = filter(EditSimilar#Next#GetDirectoryEntries(l:dirSpec, l:fileGlobs), '! isdirectory(v:val)')

    let l:currentIndex = index(l:files, ingo#fs#path#Normalize(a:filespec))
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
