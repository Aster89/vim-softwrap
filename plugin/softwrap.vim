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

let g:softwrap_spill = get(g:, 'softwrap_spill', v:false)
let g:softwrap_hollow = get(g:, 'softwrap_hollow', v:false)
let g:softwrap_close_popup_mapping = get(g:, 'softwrap_close_popup_mapping', '<esc><esc>')

if type(g:softwrap_spill) != v:t_bool
  echoerr 'SoftWrap: g:softwrap_spill must be a boolean.'
  finish
endif

if type(g:softwrap_close_popup_mapping) != v:t_string
  echoerr 'SoftWrap: g:softwrap_close_popup_mapping must be a string.'
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

function! s:softwrapShow(...)
  let nargs = [0, 0]
  let unwrap = g:softwrap_spill
  if index(a:000, 'wrap') != -1
    let nargs[0] += 1
    let unwrap = v:false
  endif
  if index(a:000, 'unwrap') != -1
    let nargs[0] += 1
    let unwrap = v:true
  endif
  let hollow_leftover = g:softwrap_hollow
  if index(a:000, 'hollow') != -1
    let nargs[1] += 1
    let hollow_leftover = v:true
  endif
  if index(a:000, 'nohollow') != -1
    let nargs[1] += 1
    let hollow_leftover = v:false
  endif
  if a:0 > 2 || len(filter(nargs, {_, i -> i <= 1})) != 2
    echom 'Wrong args'
    return
  endif

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
  if unwrap
    let available_screen = &columns - max([0, screencol() - virtcol('.')])
    let popup_fst_col = screencol() - virtcol('.') + 1
  endif
  let nlines = float2nr(ceil(len(isfold ? foldtext : getline('.'))*1.0/(available_screen - (&showbreak == '' ? 0 : 1))))
  if nlines < 2 && !unwrap
    return
  endif
  if isfold
    let foldfilling = substitute(&fillchars, '.*fold:\(.\).*', '\1', '')
    let foldtext = foldtext . repeat(foldfilling, nlines*(available_screen - (&showbreak == '' ? 0 : 1)) - len(foldtext) + 1)
  endif
  let leftover_mask = []
  if hollow_leftover && nlines >= 2
    let leftover = (available_screen * nlines) - (len(getline('.')) + (&showbreak == '' ? 0 : (nlines - 1)))
    let leftover_mask = [[-leftover, -1, -1, -1]]
  endif
  let popup = popup_create(
    \   isfold ? foldtext : bufnr(),
    \   #{
    \      col: popup_fst_col,
    \      firstline: line('.'),
    \      highlight: isfold ? 'Folded' : 'SoftWrapHighlightGroup',
    \      line: 'cursor',
    \      mask: isfold ? [] : leftover_mask,
    \      maxheight: nlines,
    \      maxwidth: available_screen,
    \      moved: 'any',
    \      scrollbar: 0,
    \      wrap: 1
    \   }
    \ )
  exe 'nnoremap <silent> ' . g:softwrap_close_popup_mapping . ' :call <SID>closePopup(' . popup . ')<CR>'
endfunction

function! s:closePopup(popup)
  exe 'call popup_close(' . a:popup . ') | nunmap ' . g:softwrap_close_popup_mapping
endfunction

command! -nargs=* SoftWrapShow call s:softwrapShow(<f-args>)
