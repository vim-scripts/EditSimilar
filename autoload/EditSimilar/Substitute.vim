" EditSimilar/Substitute.vim: Custom completion for EditSimilar substitute commands.
"
" DEPENDENCIES:
"   - EditSimilar.vim autoload script
"   - ingo/fs/path.vim autoload script
"   - ingo/msg.vim autoload script
"   - ingo/regexp/fromwildcard.vim autoload script
"
" Copyright: (C) 2012-2013 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.31.006	26-Oct-2013	Factor out
"				ingo#regexp#fromwildcard#Convert() and
"				ingo#regexp#fromwildcard#IsWildcardPathPattern()
"				into ingo-library.
"   2.31.005	14-Jun-2013	Replace EditSimilar#ErrorMsg() with
"				ingo#msg#ErrorMsg().
"   2.00.001	09-Jun-2012	file creation from autoload/EditSimilar.vim.

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
	let l:replacement = substitute( l:replacement, ingo#regexp#fromwildcard#Convert(l:from), escape(l:to, '\&~'), 'g' )
	if l:replacement ==# l:beforeReplacement
	    call add(l:failedPatterns, l:pattern)
	endif
"***D echo '****' (l:beforeReplacement =~ ingo#regexp#fromwildcard#Convert(l:from) ? '' : 'no ') . 'match for pattern' ingo#regexp#fromwildcard#Convert(l:from)
"***D echo '**** replacing' l:beforeReplacement "\n          with" l:replacement
    endfor

    return [l:replacement, l:failedPatterns]
endfunction
function! EditSimilar#Substitute#Open( opencmd, isCreateNew, filespec, ... )
    let l:originalPathspec = ingo#fs#path#Combine(fnamemodify(a:filespec, ':p:h'), '')
    let l:originalFilename = fnamemodify(a:filespec, ':t')
    let l:originalFilespec = l:originalPathspec . l:originalFilename
    try
	" Try replacement in filename first.
	let [l:replacementFilename, l:failedPatterns] = s:Substitute(l:originalFilename, a:000)
	let l:replacementFilespec = l:originalPathspec . l:replacementFilename
	let l:replacementMsg = l:replacementFilename
	if ! empty(l:failedPatterns)
	    " Then re-try all failed replacements in pathspec.
	    let [l:replacementPathspec, l:failedPatterns] = s:Substitute(l:originalPathspec, l:failedPatterns)
	    let l:replacementFilespec = l:replacementPathspec . l:replacementFilename
	    let l:replacementMsg = fnamemodify(l:replacementFilespec, ':~:.')
	    if ! empty(l:failedPatterns)
		" Finally, apply still failed replacements to the entire
		" (already replaced) filespec, but only if the replacement
		" actually spans a path separator. (To avoid that pathological
		" replacements that should not match now suddenly match in the
		" already done replacements.)
		let [l:replacementFilespec, l:failedPatterns] = s:Substitute(l:replacementFilespec, filter(l:failedPatterns, 'ingo#regexp#fromwildcard#IsWildcardPathPattern(v:val)'))
	    endif
	endif
	call EditSimilar#Open(a:opencmd, a:isCreateNew, 1, l:originalFilespec, l:replacementFilespec, l:replacementMsg)
    catch /^EditSimilar:/
	call ingo#msg#ErrorMsg(substitute(v:exception, '^EditSimilar:\s*', '', ''))
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
