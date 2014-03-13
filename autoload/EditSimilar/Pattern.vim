" EditSimilar/Pattern.vim: Custom completion for EditSimilar pattern commands.
"
" DEPENDENCIES:
"   - ingo/cmdargs/file.vim autoload script
"   - ingo/cmdargs/glob.vim autoload script
"   - ingo/compat.vim autoload script
"   - ingo/escape/file.vim autoload script
"
" Copyright: (C) 2012-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.32.007	11-Feb-2014	New
"				ingo#cmdargs#file#FilterFileOptionsAndCommands()
"				API returns fileOptionsAndCommands as a List to
"				handle multiple ones.
"   2.31.006	08-Aug-2013	Move escapings.vim into ingo-library.
"   2.31.005	14-Jun-2013	Replace EditSimilar#ErrorMsg() with
"				ingo#msg#ErrorMsg().
"   2.31.004	01-Jun-2013	Move ingofileargs.vim into ingo-library.
"   2.20.003	27-Aug-2012	Do not use <f-args> because of its unescaping
"				behavior.
"				Handle optional ++opt +cmd file options and
"				commands.
"   2.20.002	26-Aug-2012	Allow passing of multiple file (pattern).
"				Correctly handle passed file globs (incl.
"				special cases) though
"				ingofileargs#ExpandGlobs().
"   2.00.001	09-Jun-2012	file creation from autoload/EditSimilar.vim.

" Pattern commands.
function! EditSimilar#Pattern#Split( splitcmd, filePatternsString )
    let l:filePatterns = ingo#cmdargs#file#SplitAndUnescape(a:filePatternsString)

    let l:openCnt = 0

    " Strip off the optional ++opt +cmd file options and commands.
    let [l:filePatterns, l:fileOptionsAndCommands] = ingo#cmdargs#file#FilterFileOptionsAndCommands(l:filePatterns)
    let l:filespecs = ingo#cmdargs#glob#Expand(l:filePatterns)

    " Expand all files to their absolute path, because the CWD may change when a
    " file is opened (e.g. due to autocmds or :set autochdir).
    let l:filespecs = map(ingo#cmdargs#glob#Expand(l:filePatterns), "fnamemodify(v:val, ':p')")
    let l:exFileOptionsAndCommands = join(map(l:fileOptionsAndCommands, "escape(v:val, '\\ ')"))

    for l:filespec in map(l:filespecs, 'fnamemodify(v:val, ":p")')
	if bufwinnr(ingo#escape#file#bufnameescape(l:filespec)) == -1
	    " The glob (usually) returns file names sorted alphabetially, and
	    " the splits should also be arranged like that (like vim -o file1
	    " file2 file3 does). So, we only observe 'splitbelow' and
	    " 'splitright' for the very first split, and then force splitting
	    " :belowright.
	    let l:splitWhere = (l:openCnt == 0 ? '' : 'belowright')

	    execute l:splitWhere a:splitcmd l:exFileOptionsAndCommands ingo#compat#fnameescape(fnamemodify(l:filespec, ':~:.'))
	    let l:openCnt += 1
	endif
    endfor

    " Make all windows the same size if more than one has been opened.
    if l:openCnt > 1
	wincmd =
    elseif len(l:filespecs) == 0
	call ingo#msg#ErrorMsg('No matches')
    elseif l:openCnt == 0
	echomsg 'No new matches that haven''t yet been opened'
    endif
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
