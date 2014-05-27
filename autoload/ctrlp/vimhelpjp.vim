if exists('g:loaded_ctrlp_vimhelpjp') && g:loaded_ctrlp_vimhelpjp
  finish
endif
let g:loaded_ctrlp_vimhelpjp = 1

let s:vimhelpjp_var = {
\  'init':   'ctrlp#vimhelpjp#init()',
\  'exit':   'ctrlp#vimhelpjp#exit()',
\  'accept': 'ctrlp#vimhelpjp#accept',
\  'lname':  'vimhelpjp',
\  'sname':  'vimhelpjp',
\  'type':   'path',
\  'sort':   0,
\  'nolim':   1,
\}

if exists('g:ctrlp_ext_vars') && !empty(g:ctrlp_ext_vars)
  let g:ctrlp_ext_vars = add(g:ctrlp_ext_vars, s:vimhelpjp_var)
else
  let g:ctrlp_ext_vars = [s:vimhelpjp_var]
endif

function! s:gettags()
  if exists('s:list')
    return copy(s:list)
  endif
  let res = webapi#http#get("http://vim-help-jp.herokuapp.com/api/tags/json")
  let s:list = webapi#json#decode(res.content)
  return copy(s:list)
endfunction

let s:sortitem = ''
function! s:sortfunc(lhs, rhs)
  return stridx(a:lhs, s:sortitem) > stridx(a:rhs, s:sortitem)
endfunction

function! ctrlp#vimhelpjp#complete(arglead, cmdline, cursorpos)
  let items = filter(s:gettags(), 'stridx(v:val, a:arglead) >= 0')
  let s:sortitem = a:arglead
  return sort(items, function('s:sortfunc'))
endfunction

function! ctrlp#vimhelpjp#init(...)
  if len(a:000)
    call s:help(a:000[0])
  else
    call ctrlp#init(ctrlp#vimhelpjp#id())
  endif
  return s:gettags()
endfunc

function! s:help(word)
  try
    let res = webapi#http#get("http://vim-help-jp.herokuapp.com/api/search/json/", {"query": a:word})
    if res.status != 200
      echo "Not Found"
      exit
    endif
    let obj = webapi#json#decode(res.content)
    let winnum = bufwinnr(bufnr('__VimHelpJp__'))
    if winnum != -1
      if winnum != bufwinnr('%')
        exe winnum 'wincmd w'
      endif
    else
      silent noautocmd rightbelow split __VimHelpJp__
    endif
    setlocal buftype=nofile bufhidden=hide noswapfile modifiable
    call setline(1, split(obj.text, "\n"))
    setlocal nomodified nomodifiable
  finally
  endtry
endfunction

function! ctrlp#vimhelpjp#accept(mode, str)
  call ctrlp#exit()
  redraw!
  call s:help(a:str)
endfunction

function! ctrlp#vimhelpjp#exit()
  if exists('s:list')
    unlet! s:list
  endif
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#vimhelpjp#id()
  return s:id
endfunction

" vim:fen:fdl=0:ts=2:sw=2:sts=2
