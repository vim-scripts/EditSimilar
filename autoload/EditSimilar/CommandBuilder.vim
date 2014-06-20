" EditSimilar/CommandBuilder.vim: Utility for creating EditSimilar commands.
"
" DEPENDENCIES:
"   - EditSimilar/Next.vim autoload script
"   - EditSimilar/Offset.vim autoload script
"   - EditSimilar/Root.vim autoload script
"   - EditSimilar/Substitute.vim autoload script
"   - ingo/err.vim autoload script
"
" Copyright: (C) 2011-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.41.011	20-Jun-2014	BUG: :{range}WritePlus 999 doesn't actually
"				work, because it executes as
"				999,999WriteOverBuffer.
"				Add a:options.isSupportRange and then pass
"				-range=% -nargs=? instead of -count=0, so that
"				the <line1>,<line2> are actually filled with the
"				passed range and not with <count>,<count>.
"   2.40.010	24-Mar-2014	Drop -count and -count command options passed in
"				a:commandPrefix for the *Plus, *Minus, *Next,
"				*Previous commands that use a <count>
"				themselves. This allows to define the other
"				commands (e.g. *Substitute) in a way that allows
"				a range, e.g. for :write.
"   2.40.009	23-Mar-2014	Abort on errors.
"   2.30.008	09-Dec-2012	Do not require a:hasBang; instead pass the -bang
"				only for the *Plus and *Minus commands.
"   2.30.007	08-Dec-2012	CHG: For *Plus and *Minus commands with
"				a:options.omitOperationsWorkingOnlyOnExistingFiles,
"				define a -bang argument and pass
"				isFindNextNonExisting flag.
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
"		    :command options (like -buffer), just prepend them to name,
"		    e.g. "-buffer MyFileCommand". For passing ranges, use
"		    a:options.isSupportRange instead.
"   a:fileCommand   Command to be invoked with the similar file name. Can
"		    contain :command escape sequences, e.g.
"		    "<line1>,<line2>MyCommand<bang>"
"   a:hasBang	    Flag whether a:fileCommand supports a bang.
"   a:createNew	    Expression (e.g. '<bang>0') or flag whether a non-existing
"		    filespec will be opened, thereby creating a new file.
"   a:options       Optional Dictionary with configuration:
"   a:options.omitOperationsWorkingOnlyOnExistingFiles
"		    Flag that excludes the *Next and *Previous commands, which
"		    do not make sense for some a:fileCommand, because they
"		    cannot create new files.
"		    When set, the *Plus and *Minus commands also find the next
"		    non-existing file when a [count] but no [!] is given.
"   a:options.completeAnyRoot
"		    Flag that makes the *Root commands complete file extensions
"		    from any file in that directory, not just the extensions of
"		    the current file name.
"   a:options.isSupportRange
"		    Flag that uses -range=% instead of -count, used for the
"		    :Write* commands. With it, the a:fileCommand can take a
"		    <line1>,<line2> range.
"* RETURN VALUES:
"   None.
"******************************************************************************
    let l:bangArg = (a:hasBang ? '-bang' : '')
    let l:options = (a:0 ? a:1 : {})
    let l:omitOperationsWorkingOnlyOnExistingFiles = get(l:options, 'omitOperationsWorkingOnlyOnExistingFiles', 0)
    let l:completeAnyRoot = get(l:options, 'completeAnyRoot', 0)
    let l:isSupportRange = get(l:options, 'isSupportRange', 0)
    let [l:rangeArg, l:countArg, l:countIdentifier] = (l:isSupportRange ? ['-range=%', '-range=% -nargs=?', '<q-args>'] : ['', '-count=0', '<count>'])

    let l:commandPrefixWithoutRange = substitute(a:commandPrefix, '\%(^\|\s\+\)-\%(count\|range\)\%(=\S\+\)\?', '', '')


    execute printf('command! -bar %s %s -nargs=+ %sSubstitute if ! EditSimilar#Substitute#Open(%s, %s, expand("%%:p"), <f-args>) | echoerr ingo#err#Get() | endif',
    \   l:bangArg,
    \   l:rangeArg,
    \   a:commandPrefix, string(a:fileCommand), a:createNew
    \)
    execute printf('command! -bar %s %s %sPlus       if ! EditSimilar#Offset#Open(%s, %s, %s, expand("%%:p"), %s,  1) | echoerr ingo#err#Get() | endif',
    \   (l:omitOperationsWorkingOnlyOnExistingFiles && ! a:hasBang ? '-bang' : l:bangArg),
    \   l:countArg,
    \   l:commandPrefixWithoutRange, string(a:fileCommand), a:createNew,
    \   (l:omitOperationsWorkingOnlyOnExistingFiles ? '<bang>1' : 0),
    \   l:countIdentifier
    \)
    execute printf('command! -bar %s %s %sMinus      if ! EditSimilar#Offset#Open(%s, %s, %s, expand("%%:p"), %s,  -1) | echoerr ingo#err#Get() | endif',
    \   (l:omitOperationsWorkingOnlyOnExistingFiles && ! a:hasBang ? '-bang' : l:bangArg),
    \   l:countArg,
    \   l:commandPrefixWithoutRange, string(a:fileCommand), a:createNew,
    \   (l:omitOperationsWorkingOnlyOnExistingFiles ? '<bang>1' : 0),
    \   l:countIdentifier
    \)
    if ! l:omitOperationsWorkingOnlyOnExistingFiles
	" For these commands to support a:options.isSupportRange, we would have
	" to split the <args> into optional count followed by optional
	" fileGlobsString. As :WriteNext / :WritePrevious aren't defined, leave
	" this open for now.
	execute printf('command! -bar %s -range=0 -nargs=* -complete=file %sNext       if ! EditSimilar#Next#Open(%s, %s, expand("%%:p"), <count>,  1, <q-args>) | echoerr ingo#err#Get() | endif',
	\   l:bangArg, l:commandPrefixWithoutRange, string(a:fileCommand), a:createNew)
	execute printf('command! -bar %s -range=0 -nargs=* -complete=file %sPrevious   if ! EditSimilar#Next#Open(%s, %s, expand("%%:p"), <count>,  -1, <q-args>) | echoerr ingo#err#Get() | endif',
	\   l:bangArg, l:commandPrefixWithoutRange, string(a:fileCommand), a:createNew)
    endif
    execute printf('command! -bar %s %s -nargs=1 -complete=customlist,%s ' .
    \                                        '%sRoot       if ! EditSimilar#Root#Open(%s, %s, expand("%%"), <f-args>) | echoerr ingo#err#Get() | endif',
    \   l:bangArg,
    \   l:rangeArg,
    \   (l:completeAnyRoot ? 'EditSimilar#Root#CompleteAny' : 'EditSimilar#Root#Complete'),
    \   a:commandPrefix,
    \   string(a:fileCommand),
    \   a:createNew
    \)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
