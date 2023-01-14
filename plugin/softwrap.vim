" SoftWrap - Plugin for soft-wrapping current line in nowrap buffers
" Copyright (c) 2022 Enrico Maria De Angelis
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in all
" copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
" SOFTWARE.

if &compatible
  finish
endif

let g:softwrap_buf_patterns = get(g:, 'softwrap_buf_patterns', #{ onHold: '*', onMove: '' })

if empty(g:softwrap_buf_patterns) && !hasmapto('<Plug>(SoftwrapShow)')
  finish
endif

function! s:isListOfStrings(list)
  return (type(a:list) == v:t_list) && (len(a:list) == len(filter(a:list, {_,v -> type(v) == v:t_string})))
endfunction

if type(g:softwrap_buf_patterns) != v:t_string
      \ && !<SID>isListOfStrings(g:softwrap_buf_patterns)
      \ && (type(g:softwrap_buf_patterns) != v:t_dict
      \ || len(g:softwrap_buf_patterns) != 2
      \ || !has_key(g:softwrap_buf_patterns, 'onHold')
      \ || !has_key(g:softwrap_buf_patterns, 'onMove')
      \ || (type(g:softwrap_buf_patterns.onHold) != v:t_string && !<SID>isListOfStrings(g:softwrap_buf_patterns.onHold))
      \ || (type(g:softwrap_buf_patterns.onMove) != v:t_string && !<SID>isListOfStrings(g:softwrap_buf_patterns.onMove)))
  echoerr 'SoftWrap: incorrect definition of g:softwrap_buf_patterns (see :help g:softwrap_buf_patterns for the format).'
  finish
endif

if type(g:softwrap_buf_patterns) != v:t_dict
  let g:softwrap_buf_patterns = #{ onHold: g:softwrap_buf_patterns, onMove: '' }
endif

if type(g:softwrap_buf_patterns.onMove) != v:t_string
  let g:softwrap_buf_patterns.onMove = join(g:softwrap_buf_patterns.onMove, ',')
endif
if type(g:softwrap_buf_patterns.onHold) != v:t_string
  let g:softwrap_buf_patterns.onHold = join(g:softwrap_buf_patterns.onHold, ',')
endif

let g:softwrap_unwrap_popup = get(g:, 'softwrap_unwrap_popup', v:false)

if type(g:softwrap_unwrap_popup) != v:t_bool
  echoerr 'SoftWrap: g:softwrap_unwrap_popup must be a boolean.'
  finish
endif

let g:softwrap_close_popup_mapping = get(g:, 'softwrap_close_popup_mapping', '<esc><esc>')
let g:softwrap_open_popup_mapping = get(g:, 'softwrap_open_popup_mapping', '<space><space>')
if empty(g:softwrap_open_popup_mapping) && hasmapto('<Plug>(SoftwrapShow)')
  echoerr 'SoftWrap: why have you defined g:softwrap_open_popup_mapping if you are mapping <Plug>(SoftwrapShow) yourself?'
endif

if (type(g:softwrap_close_popup_mapping) != v:t_string) || (type(g:softwrap_open_popup_mapping) != v:t_string)
  echoerr 'SoftWrap: both g:softwrap_close_popup_mapping and g:softwrap_open_popup_mapping must be a string.'
  finish
endif

highlight default SoftWrapHighlightGroup ctermbg=NONE ctermfg=NONE cterm=bold
autocmd ColorScheme * highlight default SoftWrapHighlightGroup ctermbg=NONE ctermfg=NONE cterm=bold

if v:versionlong >= 8023627
  " textoff is available only from cdf5fdb2948ecdd24c6a1e27ed33dfa847c2b3e4
  let s:Textoff = {winfo -> winfo.textoff}
else
  " otherwise we compute it according to a version of
  " https://stackoverflow.com/a/26318602/5825294 improved based on the
  " comments therein
  let s:Textoff = {winfo
        \ -> max([&numberwidth, (&number ? len(line('$')) + 1 : (&relativenumber ? winfo.height + 1 : 0))])
        \ + &foldcolumn
        \ + (empty(sign_getplaced(bufname(), {'group': '*'})[0].signs) ? 0 : 2)}
endif

augroup SoftWrap
  autocmd!
  if !empty(g:softwrap_buf_patterns.onHold)
    exec 'autocmd CursorMoved ' . g:softwrap_buf_patterns.onHold . ' call <SID>enableSoftwrapAutocmdOnCursorHold()'
  endif
  if !empty(g:softwrap_buf_patterns.onMove)
    exec 'autocmd CursorMoved ' . g:softwrap_buf_patterns.onMove . ' call <SID>showSoftwrap(g:softwrap_unwrap_popup)'
    exec 'autocmd CursorMoved ' . g:softwrap_buf_patterns.onMove . " call autocmd_delete([#{ group: 'ShowSoftwrapOnCursorHold', event: 'CursorHold' }])"
  endif
augroup END

augroup ShowSoftwrapOnCursorHold
augroup END

function! s:enableSoftwrapAutocmdOnCursorHold()
  augroup ShowSoftwrapOnCursorHold
    autocmd!
    exec 'autocmd CursorHold ' . g:softwrap_buf_patterns.onHold . ' ++once call <SID>showSoftwrap(g:softwrap_unwrap_popup)'
  augroup END
endfunction

function! s:showSoftwrap(softwrap_unwrap_popup)
  if &wrap
    return
  endif

  let winfo = getwininfo(win_getid())[0]
  let textoff = s:Textoff(winfo)
  let fst_vis_scr_col_in_win = winfo.wincol + textoff
  let fst_scr_col_in_win = screencol() - virtcol('.') + 1


  let foldtext = foldtextresult(line('.'))
  let isfold = foldtext != ''
  let textwidth = winfo.width - textoff
  if (isfold ? v:true : (fst_vis_scr_col_in_win == fst_scr_col_in_win))
        \ && (isfold ? len(foldtext) : (virtcol('$') - 1)) <= textwidth
    return
  endif
  let available_screen = textwidth
  let popup_fst_col = fst_vis_scr_col_in_win
  if a:softwrap_unwrap_popup
    let available_screen = &columns - max([0, screencol() - virtcol('.')])
    let popup_fst_col = screencol() - virtcol('.') + 1
  endif
  let nlines = float2nr(ceil(len(isfold ? foldtext : getline('.'))*1.0/(available_screen - (&showbreak == '' ? 0 : 1))))
  if nlines < 2
    return
  endif
  if isfold
    let foldfilling = substitute(&fillchars, '.*fold:\(.\).*', '\1', '')
    echo strlen(foldfilling)
      let foldtext = foldtext . repeat(foldfilling, nlines*(available_screen - (&showbreak == '' ? 0 : 1)) - len(foldtext) + 1)
  endif
  let popup = popup_create(
    \   isfold ? foldtext : bufnr(),
    \   #{
    \      line: 'cursor',
    \      col: popup_fst_col,
    \      moved: 'any',
    \      highlight: isfold ? 'Folded' : 'SoftWrapHighlightGroup'
    \   }
    \ )
  call popup_setoptions(
    \ popup,
    \ #{
    \    wrap: 1,
    \    firstline: line('.'),
    \    maxheight: nlines,
    \    maxwidth: available_screen,
    \    scrollbar: 0
    \ })

  exe 'nnoremap <silent> ' . g:softwrap_close_popup_mapping . ' :call <SID>closePopup(' . popup . ')<cr>'
endfunction

function! s:closePopup(popup)
  call popup_close(a:popup)
  exe 'nunmap ' . g:softwrap_close_popup_mapping
endfunction

nnoremap <silent> <Plug>(SoftwrapShow) :call <SID>showSoftwrap(g:softwrap_unwrap_popup)<cr>

if !hasmapto('<Plug>(SoftwrapShow)')
  exe 'nmap ' . g:softwrap_open_popup_mapping . ' <Plug>(SoftwrapShow)'
endif
