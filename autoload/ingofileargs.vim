" ingofileargs.vim: Custom utility functions for file arguments.
"
" DEPENDENCIES:
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	005	04-Sep-2012	Add optional a:isKeepNoMatch argument to
"				ingofileargs#ExpandGlobs() and
"				ingofileargs#ExpandGlob() to allow use in
"				commands that support creation of new files
"				(like my custom :Split wrapper).
"	004	27-Aug-2012	Correct argument specification for
"				ingofileargs#ExpandGlob(); it should work on
"				split arguments with spaces unescaped, as done
"				by ingofileargs#SplitAndUnescapeArguments().
"				Rename ingofileargs#unescape() to
"				ingofileargs#UnescapeArgument() and rework the
"				argument specifications of many functions based
"				on my new insights into the matter.
"				Add ingofileargs#SplitAndUnescapeArguments(), as
"				this is a common need seen in dropquery.vim and
"				ingocommands.vim.
"				Rename ingofileargs#ResolveExfilePatterns() to
"				ingofileargs#ResolveGlobs(), as it basically is
"				an extended version of
"				ingofileargs#ExpandGlobs().
"	003	26-Aug-2012	Add ingofileargs#ExpandGlobs() for use in
"				GrepTasks.vim.
"				Factor out single globbing to
"				ingofileargs#ExpandGlob() and use that to
"				improve ingofileargs#ResolveExfilePatterns().
"	002	24-Mar-2012	Add ingofileargs#unescape() for use in
"				dropquery.vim and :Split.
"	001	09-Feb-2012	file creation from dropquery.vim.

function! ingofileargs#FilterFileOptionsAndCommands( fileglobs )
"*******************************************************************************
"* PURPOSE:
"   Strip off the optional ++opt +cmd file options and commands.
"
"   (In Vim 7.2,) options and commands can only appear at the beginning of the
"   file list; there can be multiple options, but only one command. They are
"   only applied to the first (opened) file, not to any other passed file.
"
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:fileglobs Raw list of file patterns. To get this from a <q-args> string,
"		use ingofileargs#SplitAndUnescapeArguments().
"* RETURN VALUES:
"   [a:fileglobs, fileOptionsAndCommands]	First element is the passed
"   list, with any file options and commands removed. Second element is a string
"   containing all removed file options and commands.
"   Note: If the file arguments were obtained through
"   ingofileargs#SplitAndUnescapeArguments(), these must be re-escaped for use
"   in another Ex command:
"	escape(l:fileOptionsAndCommands, '\ ')
"*******************************************************************************
    let l:startIdx = 0
    while get(a:fileglobs, l:startIdx, '') =~# '^+\{1,2}'
	let l:startIdx += 1
    endwhile

    if l:startIdx == 0
	return [a:fileglobs, '']
    else
	return [a:fileglobs[l:startIdx : ], join(a:fileglobs[ : (l:startIdx - 1)], ' ')]
    endif
endfunction

function! ingofileargs#UnescapeArgument( fileArgument )
"******************************************************************************
"* PURPOSE:
"   Unescape spaces in a:fileArgument for use with glob().
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:fileArgument  Single raw filespec passed from :command -nargs=+
"		    -complete=file ... <q-args>
"* RETURN VALUES:
"   Fileglob with unescaped spaces.
"******************************************************************************
    return substitute(a:fileArgument, '\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!\\ ', ' ', 'g')
endfunction
function! ingofileargs#SplitAndUnescapeArguments( fileArguments )
"******************************************************************************
"* PURPOSE:
"   Split <q-args> filespec arguments into a list of elements, which can then be
"   used with glob().
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:fileArguments Raw filespecs passed from :command -nargs=+ -complete=file
"		    ... <q-args>
"* RETURN VALUES:
"   List of fileglobs with unescaped spaces.
"   Note: If the file arguments can start with optional ++opt +cmd file options
"   and commands, these must be re-escaped (after extracting them via
"   ingofileargs#FilterFileOptionsAndCommands()) for use in another Ex command:
"	escape(l:fileOptionsAndCommands, '\ ')
"******************************************************************************
    return map(split(a:fileArguments, '\\\@<! '), 'ingofileargs#UnescapeArgument(v:val)')
endfunction

function! ingofileargs#ExpandGlob( fileglob, ... )
"******************************************************************************
"* PURPOSE:
"   Expand any file wildcards in a:fileglob to a list of normal filespecs.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:fileglob  File glob (already processed by
"		ingofileargs#UnescapeArgument()).
"   a:isKeepNoMatch Optional flag that lets globs that have no matches be kept
"		    and returned as-is, instead of being removed. Set this when
"		    you want to support creating new files.
"* RETURN VALUES:
"   List of normal filespecs; globs have been expanded. To consume this in
"   another Vim command, use:
"	join(map(l:filespecs, 'fnameescape(v:val)))
"******************************************************************************
    " XXX: Special Vim variables are expanded by -complete=file, but (in Vim
    " 7.3), escaped special names are _not_ correctly re-escaped, and a
    " following glob() or expand() will mistakenly expand them. Because of the
    " auto-expansion, any unescaped special Vim variable that gets here is in
    " fact a literal special filename. We don't even need to re-escape and
    " glob() it, just return it verbatim.
    if a:fileglob =~# '^\%(%\|#\d\?\)\%(:\a\)*$\|^<\%(cfile\|cword\|cWORD\)>\%(:\a\)*$'
	return [a:fileglob]
    else
	" Filter out directories; we're usually only interested in files.
	return filter(split((a:0 && a:1 ? expand(a:fileglob) : glob(a:fileglob)), "\n"), '! isdirectory(v:val)')
    endif
endfunction
function! ingofileargs#ExpandGlobs( fileglobs, ... )
"******************************************************************************
"* PURPOSE:
"   Expand any file wildcards in a:fileglobs to a list of normal filespecs.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:fileglobs Either space-separated arguments string (from a :command
"		-complete=file ... <q-args> custom command), or a list of
"		fileglobs (already processed by
"		ingofileargs#UnescapeArgument()).
"   a:isKeepNoMatch Optional flag that lets globs that have no matches be kept
"		    and returned as-is, instead of being removed. Set this when
"		    you want to support creating new files.
"* RETURN VALUES:
"   List of filespecs; globs have been expanded. To consume this in another Vim
"   command, use:
"	join(map(l:filespecs, 'fnameescape(v:val)))
"******************************************************************************
    let l:fileglobs = (type(a:fileglobs) == type([]) ? a:fileglobs : ingofileargs#SplitAndUnescapeArguments(a:fileglobs))

    let l:filespecs = []
    for l:fileglob in l:fileglobs
	call extend(l:filespecs, call('ingofileargs#ExpandGlob', [l:fileglob] + a:000))
    endfor
    return l:filespecs
endfunction

function! s:ContainsNoWildcards( fileglob )
    " Note: This is only an empirical approximation; it is not perfect.
    if has('win32') || has('win64')
	return a:fileglob !~ '[*?]'
    else
	return a:fileglob !~ '\\\@<![*?{[]'
    endif
endfunction
function! ingofileargs#ResolveGlobs( fileglobs )
"*******************************************************************************
"* PURPOSE:
"   Expand any file wildcards in a:fileglobs, convert to normal filespecs
"   and assemble file statistics. Like ingofileargs#ExpandGlobs(), but
"   additionally returns statistics.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:fileglobs Raw list of file patterns.
"* RETURN VALUES:
"   [l:filespecs, l:statistics]	First element is a list of the resolved
"   filespecs (in normal, not ex syntax), second element is a dictionary
"   containing the file statistics.
"*******************************************************************************
    let l:statistics = { 'files': 0, 'removed': 0, 'nonexisting': 0 }
    let l:filespecs = []
    for l:fileglob in a:fileglobs
	let l:resolvedFilespecs = ingofileargs#ExpandGlob(l:fileglob)
	if empty(l:resolvedFilespecs)
	    " To treat the file pattern as a filespec, we must emulate one
	    " effect of glob(): It removes superfluous escaping of spaces in the
	    " filespec (but leaves other escaped characters like 'C:\\foo'
	    " as-is). Without this substitution, the filereadable() check won't
	    " work.
	    let l:normalizedPotentialFilespec = substitute(l:fileglob, '\\\@<!\\ ', ' ', 'g')

	    " The globbing yielded no files; however:
	    if filereadable(l:normalizedPotentialFilespec)
		" a) The file pattern itself represents an existing file. This
		"    happens if a file is passed that matches one of the
		"    'wildignore' patterns. In this case, as the file has been
		"    explicitly passed to us, we include it.
		let l:filespecs += [l:normalizedPotentialFilespec]
	    elseif s:ContainsNoWildcards(l:fileglob)
		" b) The file pattern contains no wildcards and represents a
		"    to-be-created file.
		let l:filespecs += [l:fileglob]
		let l:statistics.nonexisting += 1
	    else
		" Nothing matched this file pattern, or whatever matched is
		" covered by the 'wildignore' patterns and not a file itself.
		let l:statistics.removed += 1
	    endif
	else
	    " We include whatever the globbing returned; 'wildignore' patterns
	    " are filtered out.
	    let l:filespecs += l:resolvedFilespecs
	endif
    endfor

    let l:statistics.files = len(l:filespecs)
    return [l:filespecs, l:statistics]
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
