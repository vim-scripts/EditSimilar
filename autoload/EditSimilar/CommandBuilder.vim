" EditSimilar/CommandBuilder.vim: Utility for creating EditSimilar commands.
"
" DEPENDENCIES:
"   - EditSimilar/Next.vim autoload script
"   - EditSimilar/Offset.vim autoload script
"   - EditSimilar/Root.vim autoload script
"   - EditSimilar/Substitute.vim autoload script
"
" Copyright: (C) 2011-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.10.006	26-Jul-2012	Change
"				a:omitOperationsWorkingOnlyOnExistingFiles
"				argument to optional a:options for
"				extensibility.
"   			    	ENH: Complete file extensions for any files
"				found in the file's directory for those commands
"				that most of the time are used to create new
"				files; the default search for the current
"				filename's extensions won't yield anything
"				there. Add a:options.completeAnyRoot for that.
"   2.00.005	11-Jun-2012	ENH: Allow passing custom fileargs / globs to
"				*Next / *Previous commands.
"   2.00.004	09-Jun-2012	Rename the *Next / *Previous commands to *Plus /
"				*Minus and redefine them to operate on directory
"				contents instead of numerical offsets.
"   			    	Move all similarity implementations to separate
"				modules.
"				Add argument
"				a:omitOperationsWorkingOnlyOnExistingFiles.
"   1.21.003	19-Jan-2012	Create the root commands also in the command
"				builder.
"   1.20.002	08-Nov-2011	Add documentation.
"	001	05-Nov-2011	file creation
let s:save_cpo = &cpo
set cpo&vim

function! EditSimilar#CommandBuilder#SimilarFileOperations( commandPrefix, fileCommand, hasBang, createNew, ... )
"******************************************************************************
"* PURPOSE:
"   Create *Plus, *Minus, *Next, *Previous, *Substitute and *Root commands with
"   * = a:commandPrefix for a:fileCommand.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   Creates commands.
"* INPUTS:
"   a:commandPrefix Name of the file operation command, used as a prefix to
"		    generate the entire command. When you want to pass
"		    :command options (like -range), just prepend them to name,
"		    e.g. "-range=% MyFileCommand"
"   a:fileCommand   Command to be invoked with the similar file name. Can
"		    contain :command escape sequences, e.g.
"		    "<line1>,<line2>MyCommand<bang>"
"   a:isBang	    Flag whether a:fileCommand supports a bang.
"   a:createNew	    Expression (e.g. '<bang>0') or flag whether a non-existing
"		    filespec will be opened, thereby creating a new file.
"   a:options       Optional Dictionary with configuration:
"   a:options.omitOperationsWorkingOnlyOnExistingFiles
"		    Flag that excludes the *Next and *Previous commands, which
"		    do not make sense for some a:fileCommand, because they
"		    cannot create new files.
"   a:options.completeAnyRoot
"		    Flag that makes the *Root commands complete file extensions
"		    from any file in that directory, not just the extensions of
"		    the current file name.
"* RETURN VALUES:
"   None.
"******************************************************************************
    let l:bangArg = (a:hasBang ? '-bang' : '')
    let l:options = (a:0 ? a:1 : {})
    let l:omitOperationsWorkingOnlyOnExistingFiles = get(l:options, 'omitOperationsWorkingOnlyOnExistingFiles', 0)
    let l:completeAnyRoot = get(l:options, 'completeAnyRoot', 0)

    execute printf('command! -bar %s -nargs=+ %sSubstitute call EditSimilar#Substitute#Open(%s, %s, expand("%%:p"), <f-args>)',
    \   l:bangArg, a:commandPrefix, string(a:fileCommand), a:createNew)
    execute printf('command! -bar %s -count=0 %sPlus       call EditSimilar#Offset#Open(%s, %s, expand("%%:p"), <count>,  1)',
    \   l:bangArg, a:commandPrefix, string(a:fileCommand), a:createNew)
    execute printf('command! -bar %s -count=0 %sMinus      call EditSimilar#Offset#Open(%s, %s, expand("%%:p"), <count>,  -1)',
    \   l:bangArg, a:commandPrefix, string(a:fileCommand), a:createNew)
    if ! l:omitOperationsWorkingOnlyOnExistingFiles
	execute printf('command! -bar %s -range=0 -nargs=* -complete=file %sNext       call EditSimilar#Next#Open(%s, %s, expand("%%:p"), <count>,  1, <q-args>)',
	\   l:bangArg, a:commandPrefix, string(a:fileCommand), a:createNew)
	execute printf('command! -bar %s -range=0 -nargs=* -complete=file %sPrevious   call EditSimilar#Next#Open(%s, %s, expand("%%:p"), <count>,  -1, <q-args>)',
	\   l:bangArg, a:commandPrefix, string(a:fileCommand), a:createNew)
    endif
    execute printf('command! -bar %s -nargs=1 -complete=customlist,%s ' .
    \                                        '%sRoot       call EditSimilar#Root#Open(%s, %s, expand("%%"), <f-args>)',
    \   l:bangArg,
    \   (l:completeAnyRoot ? 'EditSimilar#Root#CompleteAny' : 'EditSimilar#Root#Complete'),
    \   a:commandPrefix,
    \   string(a:fileCommand),
    \   a:createNew
    \)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
