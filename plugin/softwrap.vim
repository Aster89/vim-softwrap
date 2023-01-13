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

let g:softwrap_pum_unwrap = get(g:, 'softwrap_unwrap', v:false)
let g:softwrap_buf_patterns = get(g:, 'softwrap_buf_patterns', '*')
let g:softwrap_close_pum_mapping = get(g:, 'softwrap_close_pum_mapping', '<esc><esc>')

if type(g:softwrap_pum_unwrap) != v:t_bool
  echomsg 'Wrong type for g:softwrap_pum_unwrap'
  finish
endif

if type(g:softwrap_buf_patterns) == v:t_list
  let g:softwrap_buf_patterns = join(g:softwrap_buf_patterns, ',')
elseif type(g:softwrap_buf_patterns) != v:t_string
  echomsg 'Wrong type for g:softwrap_buf_patterns.'
  finish
endif

if type(g:softwrap_close_pum_mapping) != v:t_string
  echomsg 'Wrong type for g:softwrap_close_pum_mapping.'
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

augroup OnCursorMovedEnableSofwrapOnCursorHold
  autocmd!
  exec 'autocmd CursorMoved ' . g:softwrap_buf_patterns . ' call <SID>enableSoftwrapAutocmdOnCursorHold()'
augroup END

function! s:enableSoftwrapAutocmdOnCursorHold()
  augroup ShowSoftwrapOnCursorHold
    autocmd!
    exec 'autocmd CursorHold ' . g:softwrap_buf_patterns . ' ++once call <SID>showSoftwrap(g:softwrap_pum_unwrap)'
  augroup END
endfunction

function! s:showSoftwrap(softwrap_unwrap)
  if &wrap
    return
  endif
  let winfo = getwininfo(win_getid())[0]
  let textoff = s:Textoff(winfo)
  let fst_vis_scr_col_in_win = winfo.wincol + textoff
  let fst_scr_col_in_win = screencol() - virtcol('.') + 1

  let textwidth = winfo.width - textoff
  if fst_vis_scr_col_in_win == fst_scr_col_in_win && virtcol('$') - 1 <= textwidth
    return
  endif
  let available_screen = textwidth
  let popup_fst_col = fst_vis_scr_col_in_win
  if a:softwrap_unwrap
    let available_screen = &columns - max([0, screencol() - virtcol('.')])
    let popup_fst_col = screencol() - virtcol('.') + 1
  endif
  let pum = popup_create(
    \   bufnr(),
    \   #{
    \      line: 'cursor',
    \      col: popup_fst_col,
    \      moved: 'any',
    \      highlight: 'SoftWrapHighlightGroup'
    \   }
    \ )
  call popup_setoptions(
    \ pum,
    \ #{
    \    wrap: 1,
    \    firstline: line('.'),
    \    maxheight: float2nr(ceil(len(getline('.'))*1.0/(available_screen - (&showbreak == '' ? 0 : 1)))),
    \    maxwidth: available_screen,
    \    scrollbar: 0
    \ })

  exe 'nnoremap <silent> ' . g:softwrap_close_pum_mapping . ' :call <SID>closePUM(' . pum . ')<cr>'

endfunction

function! s:closePUM(pum)
  call popup_close(a:pum)
  exe 'nunmap ' . g:softwrap_close_pum_mapping
endfunction
