" ingofile.vim: Custom file functions.
"
" DEPENDENCIES:
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	003	21-May-2012	Add ingofile#GetRootDir().
"	002	18-May-2012	Add ingofile#NormalizePathSeparators().
"	001	18-May-2012	file creation from ingobuffer.vim

function! ingofile#PathSeparator()
    return (exists('+shellslash') && ! &shellslash ? '\' : '/')
endfunction

function! ingofile#NormalizePathSeparators( filespec, ... )
"******************************************************************************
"* PURPOSE:
"   Change all path separators in a:filespec to the passed or the typical format
"   for the current platform.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:filespec  Filespec, potentially with mixed / and \ path separators.
"   a:pathSeparator Optional path separator to be used.
"* RETURN VALUES:
"   a:filespec with uniform path separators, according to the platform.
"******************************************************************************
    let l:pathSeparator = (a:0 ? a:1 : ingofile#PathSeparator())
    let l:badSeparator = (l:pathSeparator ==# '/' ? '\' : '/')
    return tr(a:filespec, l:badSeparator, l:pathSeparator)
endfunction

function! ingofile#CombineToFilespec( first, ... )
"******************************************************************************
"* PURPOSE:
"   Concatenate the passed filespec fragments into a filespec, ensuring that all
"   fragments are combined with proper path separators.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   Either pass a dirspec and one or many filenames:
"	a:dirspec, a:filename [, a:filename2, ...]
"   Or a single list containing all filespec fragments.
"	[a:dirspec, a:filename, ...]
"* RETURN VALUES:
"   Combined filespec.
"******************************************************************************
    if type(a:first) == type([])
	let l:dirspec = a:first[0]
	let l:filenames = a:first[1:]
    else
	let l:dirspec = a:first
	let l:filenames = a:000
    endif

    " Use path separator as exemplified by the passed dirspec.
    if l:dirspec =~# '\' && l:dirspec !~# '/'
	let l:pathSeparator = '\'
    elseif l:dirspec =~# '/'
	let l:pathSeparator = '/'
    else
	" The dirspec doesn't contain a path separator, fall back to the
	" system's default.
	let l:defaultPathSeparator = (exists('+shellslash') && ! &shellslash ? '\' : '/')
	let l:pathSeparator = l:defaultPathSeparator
    endif

    let l:filespec = l:dirspec
    for l:filename in l:filenames
	let l:filename = substitute(l:filename, '^[/\\]', '', '')
	let l:filespec .= (l:filespec =~# '^$\|[/\\]$' ? '' : l:pathSeparator) . l:filename
    endfor

    return l:filespec
endfunction

function! ingofile#GetRootDir( filespec )
    if ! (has('win32') || has('win64'))
	return '/'
    endif

    let l:dir = a:filespec
    let l:ps = escape(ingofile#PathSeparator(), '\')
    let l:uncPathPattern = printf('^%s%s[^%s]\+%s[^%s]\+$', l:ps, l:ps, l:ps, l:ps, l:ps)
    while fnamemodify(l:dir, ':h') !=# l:dir && l:dir !~# l:uncPathPattern
	let l:dir = fnamemodify(l:dir, ':h')
    endwhile

    if empty(l:dir)
	throw 'Could not determine root dir!'
    endif

    return l:dir
endfunction

function! ingofile#MakeTempfile( filename )
"******************************************************************************
"* PURPOSE:
"   Generate a filespec in a temporary location. Unlike the built-in
"   |tempname()| function, this allows specification of the file name (which can
"   be beneficial if you want to open the temp file in a Vim buffer for the user
"   to use). Otherwise, prefer tempname().
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   None.
"* INPUTS:
"   a:filename	filename of the temp file. If empty, the function will just
"		return the name of a writable temp directory, with trailing path
"		separator.
"* RETURN VALUES:
"   Temp filespec.
"******************************************************************************
    let l:tempdirs = [fnamemodify(tempname(), ':t')]	" The built-in function should know best about a good temp dir.
    let l:tempdirs += [$TEMP, $TMP] " Also check common environment variables.

    " And finally try operating system-specific places.
    if has('dos16') || has('dos32') || has('win95') || has('win32') || has('win64')
	let l:tempdirs += [$HOMEDRIVE . $HOMEPATH, $WINDIR . '\Temp', 'C:\temp']
    else
	let l:tempdirs += [$TMPDIR, $HOME . '/tmp', '/tmp']
    endif

    for l:tempdir in l:tempdirs
	if filewritable(l:tempdir) == 2
	    return ingofile#CombineToFilespec(l:tempdir, a:filename)
	endif
    endfor
    throw 'MakeTempfile: No writable temp directory found!'
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
