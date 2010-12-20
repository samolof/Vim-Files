"File: smartpair.vim
"Vim global plugin for automatically closing braces,
"quotemarks, and other char pairs 
"Version: 0.1
"Last Modified: 2010 Oct 15
"Maintainer: Samolof <samolof@gmail.com>
"License:   This file is placed in the public domain.
"
"To enable, create the .vim/plugin subdirectory in your 
"home directory if it doesn't 
"already exist and place this file in it.
"If enabled, vim will automatically insert the closing 
"half of a brace, quote mark or any other 
"character (or multi-character) defined in the
"cpCharPairs dictionary.
"Use the <TAB> key to navigate to just outside the immediate close pair.
"To avoid auto insertion tap the character twice. E.g tapping {{ 
"inserts { without the closing }
"
"Characters for which this works (also works for multi-character pairs) 
"can be set by defining the cpCharPairs dictionary in your vimrc file. 
"For example:
"
"	let cpCharPairs={ '[' : ']'  ,     '(' : ')'   , '\*' : '*\' }
"
"The plugin is enabled by default. To turn it off by default 
"add this line to your vimrc file:
"
"	let g:SmartPairsDefault=Off
"
"You may also define a mapping for toggling it on/off by 
"mapping a key or command to <Plug>SmartPairsToggle. 
"For e.g in my vimrc I have mapped the <F5> key:
"
"	nmap <F5>   <Plug>SmartPairsToggle
"
"The default toggle command is \p in normal mode.
"
"
"
" Commands:					*Smartp*
" :Smartp {cmd} [{args} ] 
"	{cmd} is either:
"	'remove'	Remove one or more pairs from the set. 
"			Each arg should be the 
"			opening character(s) of the pair
"			E.g :Smartp remove { [ ( 
"	'show'		Show the current set of mapped char pairs
"	'default'	Restore the default set 
"	'add'		Add new pairs e.g add { } \* *\
"	
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""					



if exists("loaded_smartpairs")
	finish
endif
let loaded_smartpairs=1


let s:save_cpopt = &cpo
set cpo&vim


if !hasmapto('<Plug>SmartPairsToggle')
	map <unique> <Leader>p <Plug>SmartPairsToggle
endif
noremap <unique> <script> <Plug>SmartPairsToggle <SID>Toggle
noremap <SID>Toggle :call <SID>Toggle()<CR>



"For testing
"nnoremap <F5> :call <SID>Toggle()<CR>


let s:setACP=0

"default character dictionary if not existing
if !exists("g:cpCharPairs")
	let g:cpCharPairs = {'[':']', '(':')','"':'"',"'":"'"}
endif

"Turn it on by default
if !exists("g:SmartPairsDefault")
	let g:SmartPairsDefault="On"
endif
autocmd Bufenter,Bufnewfile,Bufread   * :if g:SmartPairsDefault=="On"| :call <SID>AutoSmartPairsOn(1)| endif 





function! <SID>AddPair(a,b)
	try
		let g:cpCharPairs[a:a] = a:b

		"we need to reset mappings if currently switched on
		if s:setACP==1
			:call <SID>AutoSmartPairsOn(1)
		endif
	catch
		echohl ErrorMSg| echomsg "Try again. One of the pairs seems to be invalid."| echohl None
		sleep 1
	endtry
endfunction


function! <SID>RemovePair(ch)
	try
		"we need to unmap if currently switched on
		if s:setACP==1
			let l:clsymbol = g:cpCharPairs[a:ch]
			execute "iunmap <silent> ".a:ch 
			if strlen(a:ch) == 1
				execute "iunmap <silent> ".a:ch .l:clsymbol
				execute "iunmap <silent> ".a:ch .a:ch
			endif
		endif

		unlet g:cpCharPairs[a:ch]
	catch
		echohl ErrorMSg| echomsg a:ch." does not appear to have been mapped"| echohl None
		sleep 1
	endtry	 
endfunction



function! <SID>ShowPairs()
	let l:showstr = ""
	for key in keys(g:cpCharPairs)
		let l:showstr = l:showstr." ".key.g:cpCharPairs[key]
	endfor

	echohl Normal | echo l:showstr | echohl None
	unlet l:showstr
	sleep 1
endfunction



function! <SID>RestoreDefault()
	let g:cpCharPairs = {'[':']', '(':')','"':'"',"'":"'"}
	if s:setACP==1
		:call <SID>AutoSmartPairsOn(1)
	endif
endfunction


function! <SID>Dispatch(cmd, ...)
	if a:cmd == "add"
		if a:0 < 1
			echohl ErrorMsg|echoerr "Too few arguments"|echohl None
			1sleep
			return
		endif

		let l:index=1
		while l:index <= a:0
			try
				:call <SID>AddPair(a:{index},a:{index +1})
			catch
				echohl ErrorMsg| echomsg 'Bad symbols or not enough arguments' |echohl None
				sleep 1
				return
			endtry
			let l:index = l:index + 2
		endwhile
	elseif a:cmd == "remove"
		if a:0 < 1
			echohl ErrorMsg|echoerr "Too few arguments"|echohl None
			1sleep
			return
		endif
		let l:index=1
		while l:index <= a:0
			:call <SID>RemovePair(a:{index})
			let l:index = l:index + 1
		endwhile
	elseif a:cmd == "show"
		:call <SID>ShowPairs()
	elseif a:cmd == "default"
		:call <SID>RestoreDefault()
	else
		echohl Errormsg|echoerr "Use: Smartp <add/remove/show> [args]"|echohl None
		sleep 1
	endif
endfunction
	

function! <SID>Toggle()
	if s:setACP==0
		:call <SID>AutoSmartPairsOn(0)
	else
		:call <SID>AutoSmartPairsOff(0)
	endif
endfunction



function! <SID>AutoSmartPairsOn(nomsg)
	for symbol in keys(g:cpCharPairs)
		let l:clsymbol = g:cpCharPairs[symbol] 
		if symbol == "'"
			"properly handle single quote
			execute "inoremap <silent> " .symbol . " ".symbol."<C-R>=<SID>setVedit()<CR><C-R>=<SID>AutoSmartPairs(\"" .symbol . "\")<CR><C-R>=<SID>resetVedit()<CR>"
		else
			execute "inoremap <silent> " .symbol . " ".symbol."<C-R>=<SID>setVedit()<CR><C-R>=<SID>AutoSmartPairs('" .symbol . "')<CR><C-R>=<SID>resetVedit()<CR>"
		endif


		"Also let user avoid mapping by quickly typing character twice
		"or typing closing character
		if strlen(symbol)==1
			execute "inoremap <silent> " .symbol .l:clsymbol " ".symbol .l:clsymbol
			"This must come second to properly handle quote
			"symbols we don't want to repeat
			execute "inoremap <silent> " .symbol .symbol. " ".symbol
		endif
	
		"Map <Tab> for navigation
		inoremap <silent> <TAB> <C-R>=<SID>MTab()<CR>

	endfor
	let s:setACP=1
	if a:nomsg != 1
		echohl Normal|echomsg "smart braces enabled"|echohl None
		1sleep
	endif
endfunction





function! <SID>AutoSmartPairsOff(nomsg)
	for symbol in keys(g:cpCharPairs)
		let l:clsymbol = g:cpCharPairs[symbol]
		try
			execute "iunmap <silent> ".symbol


			if strlen(symbol) == 1
				execute "iunmap <silent> ".symbol .l:clsymbol
				execute "iunmap <silent> ".symbol .symbol
			endif
		catch
			"probably already unmapped
		endtry
	endfor
	iunmap <silent>	<Tab>

	let s:setACP = 0
	if a:nomsg != 1
		echohl Normal |echomsg "smart braces switched off"|echohl None
	endif
	1sleep 
endfunction
	


function! <SID>setVedit()
	let s:save_ve= &ve
	set ve=all
	return ""
endfunction

function! <SID>resetVedit()
	exe "set ve=" .s:save_ve
	return ""
endfunction




function! <SID>AutoSmartPairs(symbol)
	let l:z = g:cpCharPairs[a:symbol]


	for i in range(strlen(l:z))
		let l:z .= "\<Left>"
	endfor
	

	return "".l:z 
endfunction





function! <SID>MTab()


	let l:pat= escape(join(values(g:cpCharPairs),'\|'),'*')
	let l:oppat = escape(join(keys(g:cpCharPairs),'\|'),'*')


	if search(l:oppat,'bn',line("."))!=0 && search(l:pat,'ce',line("."))!=0
			return "\<Right>"
	endif

	unlet l:pat l:oppat
	return "\<TAB>"
endfunction




"add command for adding and removing character pairs
if !exists("Smartp")
	command -nargs=+ Smartp :call <SID>Dispatch(<f-args>)
endif


let &cpo=s:save_cpopt
