" EditSimilar/Substitute.vim: Custom completion for EditSimilar substitute commands.
"
" DEPENDENCIES:
"   - EditSimilar.vim autoload script
"   - ingo/fs/path.vim autoload script
"   - ingo/err.vim autoload script
"   - ingo/regexp/fromwildcard.vim autoload script
"   - ingo/subst/pairs.vim autoload script
"
" Copyright: (C) 2012-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.40.008	23-Mar-2014	Return success status to abort on errors.
"   2.32.007	16-Jan-2014	Move s:Substitute() to
"				ingo#subst#pairs#Substitute() for reuse.
"   2.31.006	26-Oct-2013	Factor out
"				ingo#regexp#fromwildcard#Convert() and
"				ingo#regexp#fromwildcard#IsWildcardPathPattern()
"				into ingo-library.
"   2.31.005	14-Jun-2013	Replace EditSimilar#ErrorMsg() with
"				ingo#msg#ErrorMsg().
"   2.00.001	09-Jun-2012	file creation from autoload/EditSimilar.vim.

" Substitute commands.
function! EditSimilar#Substitute#Open( opencmd, isCreateNew, filespec, ... )
    let l:originalPathspec = ingo#fs#path#Combine(fnamemodify(a:filespec, ':p:h'), '')
    let l:originalFilename = fnamemodify(a:filespec, ':t')
    let l:originalFilespec = l:originalPathspec . l:originalFilename
    try
	" Try replacement in filename first.
	let [l:replacementFilename, l:failedPatterns] = ingo#subst#pairs#Substitute(l:originalFilename, a:000)
	let l:replacementFilespec = l:originalPathspec . l:replacementFilename
	let l:replacementMsg = l:replacementFilename
	if ! empty(l:failedPatterns)
	    " Then re-try all failed replacements in pathspec.
	    let [l:replacementPathspec, l:failedPatterns] = ingo#subst#pairs#Substitute(l:originalPathspec, l:failedPatterns)
	    let l:replacementFilespec = l:replacementPathspec . l:replacementFilename
	    let l:replacementMsg = fnamemodify(l:replacementFilespec, ':~:.')
	    if ! empty(l:failedPatterns)
		" Finally, apply still failed replacements to the entire
		" (already replaced) filespec, but only if the replacement
		" actually spans a path separator. (To avoid that pathological
		" replacements that should not match now suddenly match in the
		" already done replacements.)
		let [l:replacementFilespec, l:failedPatterns] = ingo#subst#pairs#Substitute(l:replacementFilespec, filter(l:failedPatterns, 'ingo#regexp#fromwildcard#IsWildcardPathPattern(v:val)'))
	    endif
	endif
	return EditSimilar#Open(a:opencmd, a:isCreateNew, 1, l:originalFilespec, l:replacementFilespec, l:replacementMsg)
    catch /^Substitute:/
	call ingo#err#SetCustomException('Substitute')
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
