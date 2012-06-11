" EditSimilar/Offset.vim: Custom completion for EditSimilar numerical offset commands.
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

" Plus / Minus commands.
function! s:NumberString( number, digitNum )
    return printf('%0' . a:digitNum . 'd', a:number)
endfunction
let s:digitPattern = '\d\+\ze\D*$'
" Hexadecimal numbers could appear in the same (last) position as the
" decimal digits, and must start as a new word. (This is to ensure that text
" such as "inside123" does not match "de123" as a hexadecimal number.)
" Either they are prefixed with '0x' (this uniquely identifies even
" decimal-only numbers such as "0x1234" as hexadecimals) , or they start
" with a decimal number. (To avoid common prefixes as in "E123" or "C406" to
" be interpreted as hexadecimals.)
let s:hexadecimalPattern = '\%(^\|[^0-9a-zA-Z]\)\%(0x\x\+\|\d\+[a-fA-F]\x*\)\D*$'
function! EditSimilar#Offset#CanApply( text )
    " To ensure that s:digitPattern does not match inside a hexadecimal number
    " (which are unsupported), we try to match with hexadecimal numbers, too.
    return a:text =~# s:digitPattern && a:text !~# s:hexadecimalPattern
endfunction
function! s:Offset( text, offset, minimum )
    let l:originalNumber = matchstr(a:text, s:digitPattern)
    let l:nextNumber = max([str2nr(l:originalNumber) + a:offset, a:minimum])
    let l:nextNumberString = s:NumberString(l:nextNumber, strlen(l:originalNumber))
    return [l:nextNumber, l:nextNumberString, substitute(a:text, s:digitPattern, l:nextNumberString, '')]
endfunction
function! s:CheckNextDigitBlock( filespec, numberString, isDescending, ... )
    let l:numberBlockRegexp = (a:isDescending ? '9' : '0') . (a:0 ? '\{' . a:1 . '}' : '\+') . '$'
    if a:numberString !~# l:numberBlockRegexp
	return 1
    endif

    " The (ascending) number is divisible by 10. Mass-check the next / last 10,
    " 100, 1000, ... number range for existing files via a file glob. If no
    " files exist in that range, the search can fast-forward across the range;
    " otherwise, the search must continue sequentially (until the next block).
    let l:numberBlock = matchstr(a:numberString, l:numberBlockRegexp)
    let l:numberBlockDigitNum = strlen(l:numberBlock)
    let l:numberFilePattern = substitute(a:numberString, l:numberBlockRegexp, repeat('[0-9]', l:numberBlockDigitNum), '')
    let l:filePattern = substitute(a:filespec, s:digitPattern, l:numberFilePattern, '')
"****D echomsg '****' l:filePattern
    let l:files = glob(l:filePattern)
    if empty(l:files)
	" The glob resulted in no files; the entire block can be skipped.
	let l:block = 1
	for l:i in range(l:numberBlockDigitNum)
	    let l:block = l:block * 10
	endfor
	return l:block
    else
	" The glob found at least one file; the block cannot be skipped.
	if l:numberBlockDigitNum > 1
	    " The block consisted of more than one decimal digit, so we can
	    " retry with a smaller block containing one digit less (i.e.
	    " one-tenth the number range).
	    return s:CheckNextDigitBlock(a:filespec, a:numberString, a:isDescending, l:numberBlockDigitNum - 1)
	else
	    " The block consisted of just one digit, and there is a match in
	    " there, so it must be searched sequentially.
	    return 1
	endif
    endif
endfunction
function! EditSimilar#Offset#Open( opencmd, isCreateNew, filespec, difference, direction )
    " A passed difference of 0 means that no [count] was specified and thus
    " skipping over missing numbers is enabled.
    let l:difference = max([a:difference, 1])
    let l:isSkipOverMissingNumbers = (a:difference == 0)

    if ! EditSimilar#Offset#CanApply(a:filespec)
	call EditSimilar#ErrorMsg('No number in filespec')
	return
    endif
    let l:originalNumberString = matchstr(a:filespec, s:digitPattern)
    if empty(l:originalNumberString) | throw 'ASSERT: Extracted number.' | endif

    let l:replacement = a:filespec
    if a:isCreateNew
	let [l:replacementNumber, l:replacementNumberString, l:replacement] = s:Offset(a:filespec, a:direction * l:difference, 0)
	if l:replacementNumber == 0 && a:direction == -1 && l:difference > 1 && ! filereadable(l:replacement)
	    let [l:replacementNumber, l:replacementNumberString, l:replacement] = s:Offset(a:filespec, a:direction * l:difference, 1)
	endif
	let l:replacementMsg = '#' . l:replacementNumberString
    elseif l:isSkipOverMissingNumbers
	let l:replacementMsg = ''

	" The maximum number that is searched for can have one more digit than
	" the next number.
	let l:numberLen = strlen(s:Offset(a:filespec, a:difference, 0)[1]) + 1
	let l:differenceMax = str2nr(repeat(9, l:numberLen))

	while l:difference < l:differenceMax
	    let [l:replacementNumber, l:replacementNumberString, l:replacement] = s:Offset(a:filespec, a:direction * l:difference, 0)
	    if empty(l:replacementMsg) | let l:replacementMsg = '#' . l:replacementNumberString | endif
	    if filereadable(l:replacement) || l:replacementNumber == 0
		break
	    endif
	    let l:difference += s:CheckNextDigitBlock(a:filespec, l:replacementNumberString, (a:direction == -1))
	endwhile
    else
	if a:direction == -1
	    " For :[N]Eprev, the replacement number cannot be smaller than zero.
	    " To avoid a CPU-intensive decrease of l:difference until
	    " l:replacementNumber becomes positive (which can take many
	    " iterations when a high [N] is supplied), the upper bound for the
	    " start value is the original number.
	    let l:originalNumber = s:Offset(a:filespec, 0, 0)[0]
	    let l:difference = min([l:difference, l:originalNumber])
	endif

	let l:replacementMsg = ''
	while l:difference > 0
	    let [l:replacementNumber, l:replacementNumberString, l:replacement] = s:Offset(a:filespec, a:direction * l:difference, 0)
	    if empty(l:replacementMsg) | let l:replacementMsg = '#' . l:replacementNumberString | endif
	    if filereadable(l:replacement)
		break
	    endif
	    let l:difference -= s:CheckNextDigitBlock(a:filespec, l:replacementNumberString, (a:direction != -1))
	endwhile
    endif

    call EditSimilar#Open(a:opencmd, a:isCreateNew, 0, a:filespec, l:replacement, l:replacementMsg . ' (from #' . l:originalNumberString . ')')
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :