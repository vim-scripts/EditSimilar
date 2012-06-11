" EditSimilar/Substitute.vim: Custom completion for EditSimilar substitute commands.
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
"   2.00.001	09-Jun-2012	file creation from autoload/EditSimilar.vim.

" Substitute commands.
if exists('+shellslash') && ! &shellslash
    let s:pathSeparator = '\'
    let s:notPathSeparatorPattern = '\\[^/\\\\]'
else
    let s:pathSeparator = '/'
    let s:notPathSeparatorPattern = '\\[^/]'
endif
function! s:AdaptCollection()
    " Special processing for the submatch inside the [...] collection.

    " Earlier, simpler regexp that didn't handle \] inside [...]:
    "let l:text = substitute(l:text, '\[\(\%(\^\?\]\)\?.\{-}\)\]', '\\%(\\%(\\[\1]\\\&' . s:notPathSeparatorPattern . '\\)\\|[\1]\\)', 'g')

    " Handle \] inside by including \] in the inner pattern, then undoing the
    " backslash escaping done first in this function (i.e. recreate \] from the
    " initial \\]).
    " Vim doesn't seem to support other escaped characters like [\x6f\d122] in a
    " file pattern.
    let l:result = substitute(submatch(1), '\\\\]', '\\]', 'g')

    " Escape ? and *; the later wildcard expansions will trample over them.
    let l:result = substitute(l:result, '[?*]', '\\\\\0', 'g')

    return l:result
endfunction
function! s:CanonicalizeWildcard( text )
    let l:text = escape(a:text, '\')

    if exists('+shellslash') && ! &shellslash
	" On Windows, when the 'shellslash' option isn't set (i.e. backslashes
	" are used as path separators), still allow using forward slashes as
	" path separators, like Vim does.
	let l:text = substitute(l:text, '/', '\\\\', 'g')
    endif
    return l:text
endfunction
function! s:WildcardToRegexp( text )
    let l:text = s:CanonicalizeWildcard(a:text)

    " [...] wildcards
    let l:text = substitute(l:text, '\[\(\%(\^\?\]\)\?\(\\\\\]\|[^]]\)*\)\]', '\="\\%(\\%(\\[". s:AdaptCollection() . "]\\\&' . s:notPathSeparatorPattern . '\\)\\|[". s:AdaptCollection() . "]\\)"', 'g')

    " ? wildcards
    let l:text = substitute(l:text, '\\\@<!?', s:notPathSeparatorPattern, 'g')
    let l:text = substitute(l:text, '\\\\?', '?', 'g')

    " ** wildcards
    " The ** wildcard matches multiple path elements up to the last path
    " separator; i.e. it doesn't match the filename itself. To implement this
    " restriction, the replacement regexp for ** ends with a zero-width match
    " (so it isn't substituted away) for the path separator if no path separator
    " is already following in the wildcard, anyway.
    " (The l:originalPathspec that is processed in s:Substitute() always has a
    " trailing path separator.)
    "
    " Note: Instead of escaping the '.*' pattern in the replacement (or else
    " it'll be processed as a * wildcard), we use the equivalent '.\{0,}'
    " pattern.
    " Note: The regexp .\{0,}/\@= later substitutes twice if nothing precedes
    " it?! To fix this, we add the ^ anchor when the ** wildcard appears at the
    " beginning.
    if s:pathSeparator ==# '\'
	" If backslash is the path separator, one cannot escape the ** wildcard.
	" That isn't necessary, anyway, because Windows doesn't allow the '*'
	" character in filespecs.
	let l:text = substitute(l:text, '\\\\\zs\*\*$', '\\.\\{0,}\\%(\\\\\\)\\@=', 'g')
	let l:text = substitute(l:text, '^\*\*$', '\\^\\.\\{0,}\\%(\\\\\\)\\@=', 'g')
	let l:text = substitute(l:text, '\%(^\|\\\\\)\zs\*\*\ze\\\\', '\\.\\{0,}', 'g')
    else
	let l:text = substitute(l:text, '/\zs\*\*$', '\\.\\{0,}/\\@=', 'g')
	let l:text = substitute(l:text, '^\*\*$', '\\^\\.\\{0,}/\\@=', 'g')
	let l:text = substitute(l:text, '\%(^\|/\)\zs\*\*\ze/', '\\.\\{0,}', 'g')
	" Convert the escaped \** to \*\*, so that the following * wildcard
	" substitution converts that to **.
	let l:text = substitute(l:text, '\\\\\*\*', '\\\\*\\\\*', 'g')
    endif

    " * wildcards
    let l:text = substitute(l:text, '\\\@<!\*', s:notPathSeparatorPattern . '\\*', 'g')
    let l:text = substitute(l:text, '\\\\\*', '*', 'g')

    return '\V' . l:text
endfunction
function! s:IsWildcardPathPattern( text )
    let l:text = s:CanonicalizeWildcard(a:text)
    let l:pathSeparatorExpr = escape(s:pathSeparator, '\')

    " Check for ** wildcard.
    if l:text =~ '\%(^\|'. l:pathSeparatorExpr . '\)\zs\*\*\ze\%(' . l:pathSeparatorExpr . '\|$\)'
	return 1
    endif

    " Check for path separator outside of [...] wildcards.
    if substitute(l:text, '\[\(\%(\^\?\]\)\?\(\\\\\]\|[^]]\)*\)\]', '', 'g') =~ l:pathSeparatorExpr
	return 1
    endif

    return 0
endfunction
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
	let l:replacement = substitute( l:replacement, s:WildcardToRegexp(l:from), escape(l:to, '\&~'), 'g' )
	if l:replacement ==# l:beforeReplacement
	    call add(l:failedPatterns, l:pattern)
	endif
"***D echo '****' (l:beforeReplacement =~ s:WildcardToRegexp(l:from) ? '' : 'no ') . 'match for pattern' s:WildcardToRegexp(l:from)
"***D echo '**** replacing' l:beforeReplacement "\n          with" l:replacement
    endfor

    return [l:replacement, l:failedPatterns]
endfunction
function! EditSimilar#Substitute#Open( opencmd, isCreateNew, filespec, ... )
    let l:originalPathspec = fnamemodify(a:filespec, ':p:h') . s:pathSeparator
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
		let [l:replacementFilespec, l:failedPatterns] = s:Substitute(l:replacementFilespec, filter(l:failedPatterns, 's:IsWildcardPathPattern(v:val)'))
	    endif
	endif
	call EditSimilar#Open(a:opencmd, a:isCreateNew, 1, l:originalFilespec, l:replacementFilespec, l:replacementMsg)
    catch /^EditSimilar:/
	call EditSimilar#ErrorMsg(substitute(v:exception, '^EditSimilar:\s*', '', ''))
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
