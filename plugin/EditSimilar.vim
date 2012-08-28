" EditSimilar.vim: Commands to edit files with a similar filename.
"
" DEPENDENCIES:
"   - EditSimilar.vim autoload script
"   - EditSimilar/CommandBuilder.vim autoload script
"   - EditSimilar/Pattern.vim autoload script
"
" Copyright: (C) 2009-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.20.015	27-Aug-2012	Do not use <f-args> because of its unescaping
"				behavior.
"   2.20.014	26-Aug-2012	Enable file (pattern) completion for :*Pattern
"				commands via -nargs=+ workaround and passing of
"				multiple file (pattern).
"   2.10.013	26-Jul-2012	Adapt to changed EditSimilar interface.
"				Now :File*, :Write*, and :Save* complete any
"				file extensions.
"   2.00.012	09-Jun-2012	Move all similarity implementations to separate
"				modules.
"   1.22.011	10-Feb-2012	ENH: Allow [v]split mode different than
"				determined by 'splitbelow' / 'splitright' via
"				configuration.
"   1.21.010	19-Jan-2012	Move file extension completion to
"				EditSimilar#Root#Complete() and create the root
"				commands also in the command builder.
"   1.20.009	05-Nov-2011	ENH: Omit current buffer's file extension from
"				the completion for EditSimilar-root commands.
"				Use
"				EditSimilar#CommandBuilder#SimilarFileOperations()
"				to create the :*Substitute, :*Next and
"				:*Previous commands.
"				Obsolete the short command forms :Esubst,
"				:Enext, :Eprev; the starting uppercase letter
"				makes them still awkward to type, there's more
"				likely a conflict with other custom commands
"				(e.g. :En -> :Encode, :Enext), and I now believe
"				aliasing via cmdalias.vim is the better way to
"				provide personal shortcuts, instead of polluting
"				the command namespace with all these duplicates.
"   1.18.008	22-Jun-2011	ENH: Implement completion of file extensions for
"				EditSimilar-root commands like :EditRoot.
"   1.13.007	26-Jun-2009	:EditNext / :EditPrevious without the optional
"				[count] now skip over gaps in numbering. Changed
"				the default [count] to 0 to be able to detect a
"				given count.
"   1.11.006	11-May-2009	Added commands to open similar files in
"				read-only mode, a la :ViewSubstitute,
"				:SViewSubstitute.
"   1.00.005	18-Feb-2009	Reviewed for publication.
"	004	04-Feb-2009	Full path '%:p' not needed for root commands.
"	003	02-Feb-2009	Moved functions from plugin to separate autoload
"				script.
"				Moved documentation to separate help file.
"	002	31-Jan-2009	Moved :Sproot and :Sppattern commands from
"				ingocommands.vim.
"				ENH: :Sppattern now notifies when no new windows
"				have been opened.
"				Added overloads for :file, :write and :saveas.
"				For the :edit, :split and :vsplit overloads,
"				there are now a long (:EditPrevious) and a short
"				(:Eprev) version.
"	001	29-Jan-2009	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_EditSimilar') || (v:version < 700)
    finish
endif
let g:loaded_EditSimilar = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:EditSimilar_splitmode')
    let g:EditSimilar_splitmode = ''
endif
if ! exists('g:EditSimilar_vsplitmode')
    let g:EditSimilar_vsplitmode = ''
endif



"- commands --------------------------------------------------------------------

" Substitute, Plus / Minus, and Next / Previous commands.
" Root (i.e. file extension) commands.
call EditSimilar#CommandBuilder#SimilarFileOperations('Edit',   'edit',                                     1, '<bang>0', {'omitOperationsWorkingOnlyOnExistingFiles': 0, 'completeAnyRoot': 0})
call EditSimilar#CommandBuilder#SimilarFileOperations('View',   'view',                                     1, '<bang>0', {'omitOperationsWorkingOnlyOnExistingFiles': 0, 'completeAnyRoot': 0})
call EditSimilar#CommandBuilder#SimilarFileOperations('Split',  join([g:EditSimilar_splitmode, 'split']),   1, '<bang>0', {'omitOperationsWorkingOnlyOnExistingFiles': 0, 'completeAnyRoot': 0})
call EditSimilar#CommandBuilder#SimilarFileOperations('VSplit', join([g:EditSimilar_vsplitmode, 'vsplit']), 1, '<bang>0', {'omitOperationsWorkingOnlyOnExistingFiles': 0, 'completeAnyRoot': 0})
call EditSimilar#CommandBuilder#SimilarFileOperations('SView',  join([g:EditSimilar_splitmode, 'sview']),   1, '<bang>0', {'omitOperationsWorkingOnlyOnExistingFiles': 0, 'completeAnyRoot': 0})
call EditSimilar#CommandBuilder#SimilarFileOperations('File',   'file',                                     0, 1,         {'omitOperationsWorkingOnlyOnExistingFiles': 1, 'completeAnyRoot': 1})
call EditSimilar#CommandBuilder#SimilarFileOperations('Write',  'write<bang>',                              1, 1,         {'omitOperationsWorkingOnlyOnExistingFiles': 1, 'completeAnyRoot': 1})
call EditSimilar#CommandBuilder#SimilarFileOperations('Save',   'saveas<bang>',                             1, 1,         {'omitOperationsWorkingOnlyOnExistingFiles': 1, 'completeAnyRoot': 1})


" Pattern commands.
" Note: Must use + instead of 1; otherwise (due to -complete=file), Vim
" complains about globs with "E77: Too many file names".
command! -bar -nargs=+ -complete=file SplitPattern  call EditSimilar#Pattern#Split(join([g:EditSimilar_splitmode, 'split']),   <q-args>)
command! -bar -nargs=+ -complete=file VSplitPattern call EditSimilar#Pattern#Split(join([g:EditSimilar_vsplitmode, 'vsplit']), <q-args>)
command! -bar -nargs=+ -complete=file SViewPattern  call EditSimilar#Pattern#Split(join([g:EditSimilar_splitmode, 'sview']),   <q-args>)

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
