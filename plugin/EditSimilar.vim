" EditSimilar.vim: Commands to edit files with a similar filename. 
"
" DEPENDENCIES:
"   - Requires EditSimilar.vim autoload script. 
"
" Copyright: (C) 2009-2011 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.18.008	22-Jun-2011	ENH: Implement completion of file extensions for
"				EditSimilar-root commands like :EditRoot. 
"   1.13.007	26-Jun-2009	:EditNext / :EditPrevious without the optional
"				[count] now skip over gaps in numbering. Changed
"				the default [count] to 0 to be able to detect a
"				given count. 
"   1.11.006	11-May-2009	Added commands to open similar files in
"				read-only mode, a la :ViewSubstitute,
"				:SviewSubstitute. 
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

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_EditSimilar') || (v:version < 700)
    finish
endif
let g:loaded_EditSimilar = 1

let s:save_cpo = &cpo
set cpo&vim

" Substitute commands. 
command! -bar -bang -nargs=+ EditSubstitute	call EditSimilar#OpenSubstitute('edit',   <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ Esubst		call EditSimilar#OpenSubstitute('edit',   <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ ViewSubstitute	call EditSimilar#OpenSubstitute('view',   <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ Vsubst		call EditSimilar#OpenSubstitute('view',   <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ SplitSubstitute	call EditSimilar#OpenSubstitute('split',  <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ Spsubst	    	call EditSimilar#OpenSubstitute('split',  <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ VsplitSubstitute	call EditSimilar#OpenSubstitute('vsplit', <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ Vspsubst	    	call EditSimilar#OpenSubstitute('vsplit', <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ SviewSubstitute	call EditSimilar#OpenSubstitute('sview',  <bang>0, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ Svsubst	    	call EditSimilar#OpenSubstitute('sview',  <bang>0, expand('%:p'), <f-args>)

command! -bar	    -nargs=+ FileSubstitute	call EditSimilar#OpenSubstitute('file',         1, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ WriteSubstitute	call EditSimilar#OpenSubstitute('write<bang>',  1, expand('%:p'), <f-args>)
command! -bar -bang -nargs=+ SaveSubstitute	call EditSimilar#OpenSubstitute('saveas<bang>', 1, expand('%:p'), <f-args>)


" Next / Previous commands. 
command! -bar -bang -count=0 EditNext		call EditSimilar#OpenOffset('edit',   <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 Enext		call EditSimilar#OpenOffset('edit',   <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 EditPrevious	call EditSimilar#OpenOffset('edit',   <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 Eprev		call EditSimilar#OpenOffset('edit',   <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 ViewNext		call EditSimilar#OpenOffset('view',   <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 Vnext		call EditSimilar#OpenOffset('view',   <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 ViewPrevious	call EditSimilar#OpenOffset('view',   <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 Vprev		call EditSimilar#OpenOffset('view',   <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 SplitNext		call EditSimilar#OpenOffset('split',  <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 Spnext		call EditSimilar#OpenOffset('split',  <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 SplitPrevious	call EditSimilar#OpenOffset('split',  <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 Spprev		call EditSimilar#OpenOffset('split',  <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 VsplitNext		call EditSimilar#OpenOffset('vsplit', <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 Vspnext		call EditSimilar#OpenOffset('vsplit', <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 VsplitPrevious	call EditSimilar#OpenOffset('vsplit', <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 Vspprev	    	call EditSimilar#OpenOffset('vsplit', <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 SviewNext		call EditSimilar#OpenOffset('sview',  <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 Svnext		call EditSimilar#OpenOffset('sview',  <bang>0, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 SviewPrevious	call EditSimilar#OpenOffset('sview',  <bang>0, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 Svprev		call EditSimilar#OpenOffset('sview',  <bang>0, expand('%:p'), <count>, -1)

command! -bar	    -count=0 FileNext		call EditSimilar#OpenOffset('file',         1, expand('%:p'), <count>,  1)
command! -bar	    -count=0 FilePrevious	call EditSimilar#OpenOffset('file',         1, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 WriteNext		call EditSimilar#OpenOffset('write<bang>',  1, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 WritePrevious	call EditSimilar#OpenOffset('write<bang>',  1, expand('%:p'), <count>, -1)
command! -bar -bang -count=0 SaveNext		call EditSimilar#OpenOffset('saveas<bang>', 1, expand('%:p'), <count>,  1)
command! -bar -bang -count=0 SavePrevious	call EditSimilar#OpenOffset('saveas<bang>', 1, expand('%:p'), <count>, -1)


" Root (i.e. file extension) commands. 
function! s:RootComplete( ArgLead, CmdLine, CursorPos )
    return map(
    \	split(
    \	    glob(expand('%:r') . '.' . a:ArgLead . '*'),
    \	    "\n"
    \	),
    \	'fnamemodify(v:val, ":e")'
    \)
    " Note: No need for fnameescape(); the Root commands don't support Vim
    " special characters like % and # and therefore do the escaping themselves. 
endfunction
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete EditRoot     call EditSimilar#OpenRoot('edit',   <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete Eroot        call EditSimilar#OpenRoot('edit',   <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete ViewRoot     call EditSimilar#OpenRoot('view',   <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete Vroot        call EditSimilar#OpenRoot('view',   <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete SplitRoot    call EditSimilar#OpenRoot('split',  <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete Sproot       call EditSimilar#OpenRoot('split',  <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete VsplitRoot   call EditSimilar#OpenRoot('vsplit', <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete Vsproot      call EditSimilar#OpenRoot('vsplit', <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete SviewRoot    call EditSimilar#OpenRoot('sview',  <bang>0, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete Svroot       call EditSimilar#OpenRoot('sview',  <bang>0, expand('%'), <f-args>)

command! -bar       -nargs=1 -complete=customlist,<SID>RootComplete FileRoot     call EditSimilar#OpenRoot('file',         1, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete WriteRoot    call EditSimilar#OpenRoot('write<bang>',  1, expand('%'), <f-args>)
command! -bar -bang -nargs=1 -complete=customlist,<SID>RootComplete SaveRoot     call EditSimilar#OpenRoot('saveas<bang>', 1, expand('%'), <f-args>)


" Pattern commands. 
" Note: We cannot use -complete=file; it results in E77: too many files error
" when using a pattern. 
command! -bar -nargs=1 SplitPattern    call EditSimilar#SplitPattern('split', <f-args>)
command! -bar -nargs=1 Sppat	       call EditSimilar#SplitPattern('split', <f-args>)
command! -bar -nargs=1 VsplitPattern   call EditSimilar#SplitPattern('vsplit', <f-args>)
command! -bar -nargs=1 Vsppat	       call EditSimilar#SplitPattern('vsplit', <f-args>)
command! -bar -nargs=1 SviewPattern    call EditSimilar#SplitPattern('sview', <f-args>)
command! -bar -nargs=1 Svpat	       call EditSimilar#SplitPattern('sview', <f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
