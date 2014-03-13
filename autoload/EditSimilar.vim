" EditSimilar.vim: Commands to edit files with a similar filename.
"
" DEPENDENCIES:
"   - ingo/compat.vim autoload script
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2009-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.32.023	17-Jan-2014	Add workaround for editing via :pedit, which
"				uses the CWD of existing preview window instead
"				of the CWD of the current window; leading to
"				wrong not-existing files being opened when :set
"				autochdir. Work around this by always passing a
"				full absolute filespec. Encountered this in my
"				MessageRecall.vim plugin, when doing <C-p> from
"				a modified VcsMessageRecall buffer.
"   2.31.021	08-Aug-2013	Move escapings.vim into ingo-library.
"   2.31.020	09-Jul-2013	Also handle :echoerr errors, which don't have an
"				E... number prepended.
"   2.31.019	14-Jun-2013	Minor: Make substitute() robust against
"				'ignorecase'.
"				Replace EditSimilar#ErrorMsg() with
"				ingo#msg#ErrorMsg().
"   2.00.018	11-Jun-2012	FIX: a:isFilePattern argument was ignored; only
"				perform the filespec glob expansion when it is
"				set.
"				BUG: Substituted filenames that only exist in an
"				unpersisted Vim buffer cause a "file does not
"				exist" error when a:isCreateNew isn't set. Also
"				check Vim buffers for a match.
"   2.00.017	09-Jun-2012	Move all similarity implementations to separate
"				modules and only keep core functionality here.
"   1.19.016	25-Jul-2011	Avoid that :SplitPattern usually opens splits in
"				reverse glob order (with default 'nosplitbelow'
"				/ 'nosplitright') by forcing :belowright
"				splitting for all splits after the first. I.e.
"				behave more like vim -o {pattern}.
"   1.17.015	25-Feb-2010	BUG: :999EditPrevious on 'file00' caused E121:
"				Undefined variable: l:replacement.
"   1.16.014	11-Nov-2009	BUG: Next / previous commands interpreted files
"				such as 'C406' as hexadecimal. Tweaked
"				s:hexadecimalPattern to have hexadecimals start
"				with a decimal, or have the "0x" prefix uniquely
"				identify (even pure decimal) numbers as
"				hexadecimal. Thanks to Andy Wokula for sending a
"				patch.
"   1.15.013	09-Sep-2009	Now also using EditSimilar#CanApplyOffset()
"				inside EditSimilar#OpenOffset(). The function
"				checks that the digit pattern does not
"				accidentally match inside a hexadecimal number
"				(which are unsupported).
"   1.14.012	21-Aug-2009	BF: :[N]Eprev with supplied [N] would skip over
"				existing smaller number file and would claim
"				that no substituted file existed. Must clear
"				a:isDescending flag passed to
"				s:CheckNextDigitBlock() for :Eprev.
"				BF: :[N]Eprev with supplied large [N] together
"				with a low original number hogs the CPU because
"				the loop iterates over the entire number range
"				where the resulting offset would be negative.
"				Now using the original number as the upper
"				bound, so that the efficient number range check
"				starts immediately.
"   1.13.011	27-Jun-2009	The skip to the next number implements a more
"				efficient search algorithm that checks whole
"				number ranges (via glob('...[0-9]')) and skips
"				over the range if no matches occur in that
"				block. This greatly speeds up :Enext / Eprev
"				over large gaps and after the last / before the
"				first existing number.
"   1.13.010	26-Jun-2009	:EditNext / :EditPrevious without the optional
"				[count] now skip over gaps in numbering.
"   1.12.009	13-May-2009	ENH: Supporting substitutions spanning both
"				pathspec and filename by finally applying failed
"				multi-path elements replacements to the entire
"				filespec.
"				BF: ** wildcard now matches multiple path
"				elements up to the last path separator; i.e. it
"				doesn't match the filename itself.
"   1.12.008	12-May-2009	ENH: Completed implementation of file patterns
"				with [...] and **; now also escaping ? and *
"				inside [...] collections to undo the later
"				indiscriminate wildcard expansion.
"				ENH: On Windows, forward slashes can also be
"				used as path separators in the wildcard text.
"   1.12.007	11-May-2009	ENH: Implemented use of file pattern (? and *,
"				plus escaped \? and \* literals) in
"				EditSimilar#OpenSubstitute().
"   1.10.006	23-Feb-2009	ENH: s:Open() now has additional a:isFilePattern
"				argument and is able to resolve file wildcards.
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

function! EditSimilar#Open( opencmd, isCreateNew, isFilePattern, originalFilespec, replacementFilespec, createNewNotAllowedMsg )
"*******************************************************************************
"* PURPOSE:
"   Open a substituted filespec via the a:opencmd Ex command.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:opencmd	Ex command to open the file (e.g. 'edit', 'split', etc.)
"   a:isCreateNew   Flag whether a non-existing filespec will be opened, thereby
"		    creating a new file.
"   a:isFilePattern Flag whether file wildcards will be resolved (if the
"		    filespec itself doesn't exist. If the resolution of
"		    wildcards yields a single (existing) file, it is opened.
"		    Multiple candidates will result in an error message.
"   a:originalFilespec	Original, unmodified filespec; is used for check that
"			something actually was substituted.
"   a:replacementFilespec   Filespec to be opened. May contain wildcards.
"   a:createNewNotAllowedMsg	(Optional) user message to be appended to the
"				"Substituted file does not exist" error message;
"				typically contains the (user-readable)
"				representation of a:replacementFilespec.
"* RETURN VALUES:
"   None.
"*******************************************************************************
    let l:filespecToOpen = a:replacementFilespec

    if l:filespecToOpen ==# a:originalFilespec
	call ingo#msg#ErrorMsg('Nothing substituted')
	return
    endif

    if a:isFilePattern && ! filereadable(l:filespecToOpen) && ! isdirectory(l:filespecToOpen)
	let l:files = split(glob(l:filespecToOpen), "\n")
	if len(l:files) > 1
	    call ingo#msg#ErrorMsg('Too many file names')
	    return
	elseif len(l:files) == 1
	    let l:filespecToOpen = l:files[0]
	    if l:filespecToOpen ==# a:originalFilespec
		call ingo#msg#ErrorMsg('Nothing substituted')
		return
	    endif
	endif
    endif
    if ! filereadable(l:filespecToOpen) && ! isdirectory(l:filespecToOpen)
	if bufexists(l:filespecToOpen)
	    " The file only exists in an unpersisted Vim buffer so far.
	else
	    if ! a:isCreateNew
		call ingo#msg#ErrorMsg('Substituted file does not exist (add ! to create)' . (empty(a:createNewNotAllowedMsg) ? '' : ': ' . a:createNewNotAllowedMsg))
		return
	    endif
	endif
    endif

"****D echomsg '****' . a:opencmd . ' ' . l:filespecToOpen | return
    if exists('+autochdir') && &autochdir && a:opencmd =~# '^pedit\>'
	" XXX: :pedit uses the CWD of existing preview window instead of the CWD
	" of the current window; leading to wrong not-existing files being
	" opened. Work around this by always passing a full absolute filespec.
	let l:filespec = fnamemodify(l:filespecToOpen, ':p')
    else
	let l:filespec = fnamemodify(l:filespecToOpen, ':~:.')
    endif
    try
	execute a:opencmd ingo#compat#fnameescape(l:filespec)
    catch /^Vim\%((\a\+)\)\=:E37/	" E37: No write since last change (add ! to override)
	" The "(add ! to override)" is wrong here, we use the ! for another
	" purpose, so filter it away.
	call ingo#msg#ErrorMsg(substitute(substitute(v:exception, '^\CVim\%((\a\+)\)\=:E37:\s*', '', ''), '\s*(.*)', '', 'g'))
    catch /^Vim\%((\a\+)\)\=:/
	call ingo#msg#VimExceptionMsg()
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
