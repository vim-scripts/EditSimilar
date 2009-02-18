" EditSimilar.vim: Commands to edit files with a similar filename. 
"
" DEPENDENCIES:
"   - Requires escapings.vim autoload script. 
"
" Copyright: (C) 2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.00.005	18-Feb-2009	Reviewed for publication. 
"	004	04-Feb-2009	Now reducing the filespec to shortest possible
"				(:~:.) before executing opencmd. This avoids
"				ugly long buffer names when :set noautochdir. 
"	003	02-Feb-2009	ENH: Implemented EditSimilar#OpenRoot(). 
"	002	02-Feb-2009	BF: Test for existing buffer name in
"				EditSimilar#SplitPattern() now properly escapes
"				and anchors the filespec, so that only full
"				names match. 
"	001	02-Feb-2009	Moved functions from plugin to separate autoload
"				script. 
"				file creation

function! s:ErrorMsg( text )
    echohl ErrorMsg
    let v:errmsg = a:text
    echomsg v:errmsg
    echohl None
endfunction 

function! s:Open( opencmd, isCreateNew, originalFilespec, replacementFilespec, createNewNotAllowedMsg )
    if a:replacementFilespec ==# a:originalFilespec
	call s:ErrorMsg('Nothing substituted')
	return
    endif
    if ! a:isCreateNew && ! filereadable(a:replacementFilespec) && ! isdirectory(a:replacementFilespec)
	call s:ErrorMsg('Substituted file does not exist (add ! to create)' . (empty(a:createNewNotAllowedMsg) ? '' : ': ' . a:createNewNotAllowedMsg))
	return
    endif

"****D echomsg '****' . a:opencmd . ' ' . a:replacementFilespec | return
    try
	execute a:opencmd escapings#fnameescape(fnamemodify(a:replacementFilespec, ':~:.'))
    catch /^Vim\%((\a\+)\)\=:E37/	" E37: No write since last change (add ! to override)
	" The "(add ! to override)" is wrong here, we use the ! for another
	" purpose, so filter it away. 
	call s:ErrorMsg(substitute(substitute(v:exception, '^Vim\%((\a\+)\)\=:E37:\s*', '', ''), '\s*(.*)', '', 'g'))
    catch /^Vim\%((\a\+)\)\=:E/
	" v:exception contains what is normally in v:errmsg, but with extra
	" exception source info prepended, which we cut away. 
	call s:ErrorMsg(substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', ''))
    endtry
endfunction

" Substitute commands. 
let s:patternPattern = '\(^.\+\)=\(.*$\)'
function! s:Substitute( text, patterns )
    let l:replacement = a:text
    let l:failedPatterns = []

    for l:pattern in a:patterns
	if l:pattern !~# s:patternPattern
	    throw 'EditSimilar: Not a substitution: ' . l:pattern
	endif
	let [l:match, l:from, l:to; l:rest] = matchlist(l:pattern, s:patternPattern)
	if empty(l:match) || empty(l:from) | throw 'ASSERT: Pattern can be applied. ' | endif
	let l:beforeReplacement = l:replacement
	let l:replacement = substitute( l:replacement, '\V' . escape(l:from, '\'), escape(l:to, '\&~'), 'g' )
	if l:replacement ==# l:beforeReplacement
	    call add(l:failedPatterns, l:pattern)
	endif
    endfor

    return [l:replacement, l:failedPatterns]
endfunction
function! EditSimilar#OpenSubstitute( opencmd, isCreateNew, filespec, ... )
    let l:pathSeparator = (exists('+shellslash') && ! &shellslash ? '\' : '/')
    let l:originalPathspec = fnamemodify(a:filespec, ':p:h') . l:pathSeparator
    let l:originalFilename = fnamemodify(a:filespec, ':t')
    let l:originalFilespec = l:originalPathspec . l:originalFilename
    try
	let [l:replacementFilename, l:failedPatterns] = s:Substitute(l:originalFilename, a:000)
	let l:replacementFilespec = l:originalPathspec . l:replacementFilename
	let l:replacementMsg = l:replacementFilename
	if ! empty(l:failedPatterns)
	    let [l:replacementPathspec, l:failedPatterns] = s:Substitute(l:originalPathspec, l:failedPatterns)
	    let l:replacementFilespec = l:replacementPathspec . l:replacementFilename
	    let l:replacementMsg = fnamemodify(l:replacementFilespec, ':~:.')
	endif
	call s:Open(a:opencmd, a:isCreateNew, l:originalFilespec, l:replacementFilespec, l:replacementMsg)
    catch /^EditSimilar:/
	call s:ErrorMsg(substitute(v:exception, '^EditSimilar:\s*', '', ''))
    endtry
endfunction

" Next / Previous commands. 
let s:digitPattern = '\d\+\ze\D*$'
function! s:Offset( text, offset, minimum )
    let l:currentNumber = matchstr(a:text, s:digitPattern)
    let l:nextNumber = max([str2nr(l:currentNumber, 10) + a:offset, a:minimum])
    let l:nextNumberString = printf('%0' . strlen(l:currentNumber) . 'd', l:nextNumber)
    return [l:nextNumberString, substitute(a:text, s:digitPattern, l:nextNumberString, '')]
endfunction
function! EditSimilar#OpenOffset( opencmd, isCreateNew, filespec, difference, direction )
    let l:originalNumber = matchstr(a:filespec, s:digitPattern)
    if empty(l:originalNumber)
	call s:ErrorMsg('No number in filespec')
	return
    endif

    if a:isCreateNew
	let [l:replacementNumberString, l:replacement] = s:Offset(a:filespec, a:direction * a:difference, 0)
	if str2nr(l:replacementNumberString, 10) == 0 && a:direction == -1 && a:difference > 1 && ! filereadable(l:replacement)
	    let [l:replacementNumberString, l:replacement] = s:Offset(a:filespec, a:direction * a:difference, 1)
	endif
	let l:replacementMsg = '#' . l:replacementNumberString
    else
	let l:difference = a:difference
	let l:replacementMsg = ''
	while l:difference > 0
	    let [l:replacementNumberString, l:replacement] = s:Offset(a:filespec, a:direction * l:difference, 0)
	    if empty(l:replacementMsg) | let l:replacementMsg = '#' . l:replacementNumberString | endif
	    if filereadable(l:replacement)
		break
	    endif
	    let l:difference -= 1
	endwhile
    endif

    call s:Open(a:opencmd, a:isCreateNew, a:filespec, l:replacement, l:replacementMsg . ' (from #' . l:originalNumber . ')')
endfunction

" Root (i.e. file extension) commands. 
function! EditSimilar#OpenRoot( opencmd, isCreateNew, filespec, newExtension )
    let [l:fullmatch, l:dots, l:newExtension; l:rest] = matchlist(a:newExtension, '\(^\.*\)\(.*$\)')

    " Each leading '.' removes one file extension from the original filename; a
    " single dot is optional. 
    let l:rootRemovalNum = (strlen(l:dots) > 1 ? strlen(l:dots) : 1)

    let l:newFilespec = fnamemodify(a:filespec, repeat(':r', l:rootRemovalNum)) . (! empty(l:newExtension) ? '.' . l:newExtension : '')
    call s:Open( a:opencmd, a:isCreateNew, a:filespec, l:newFilespec, fnamemodify(l:newFilespec, ':t'))
endfunction

" Pattern commands. 
function! EditSimilar#SplitPattern( splitcmd, pattern )
    let l:openCnt = 0
    " Expand all files to their absolute path, because the CWD may change when a
    " file is opened (e.g. due to autocmds or :set autochdir). 

    let l:filespecs = map( split(glob(a:pattern), "\n"), "fnamemodify(v:val, ':p')" )
    for l:filespec in l:filespecs
	if bufwinnr(escapings#bufnameescape(l:filespec)) == -1
	    execute a:splitcmd escapings#fnameescape(fnamemodify(l:filespec, ':~:.'))
	    let l:openCnt += 1
	endif
    endfor

    " Make all windows the same size if more than one has been opened. 
    if l:openCnt > 1
	wincmd =
    elseif len(l:filespecs) == 0
	call s:ErrorMsg('No matches')
    elseif l:openCnt == 0
	echomsg 'No new matches that haven''t yet been opened'
    endif
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
