if &compatible
  finish
endif

if !exists('g:softwrap_unwrap')
  let g:softwrap_unwrap = v:false
endif

au ColorScheme * hi SoftWrapHighlighGroup ctermbg=NONE ctermfg=NONE

function! s:softwrap(softwrap_unwrap)
  if &wrap
    return
  endif
  let winfo = getwininfo(win_getid())[0]
  if v:versionlong >= 8023627
    " textoff is available only from cdf5fdb2948ecdd24c6a1e27ed33dfa847c2b3e4
    let textoff = winfo.textoff
  else
    " otherwise we compute it according to a version of
    " https://stackoverflow.com/a/26318602/5825294 improved based on the
    " comments therein
    let textoff = ((&number||&relativenumber) ? &numberwidth : 0) + &foldcolumn + (empty(sign_getplaced(bufname(), {'group': '*'})[0].signs) ? 0 : 2)
  endif
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
  call popup_setoptions(
    \ popup_create(
    \   bufnr(),
    \   #{
    \      line: 'cursor',
    \      col: popup_fst_col,
    \      moved: 'any',
    \      highlight: 'SoftWrapHighlighGroup'
    \   }
    \ ),
    \ #{
    \    wrap: 1,
    \    firstline: line('.'),
    \    maxheight: float2nr(ceil(len(getline(line('.')))*1.0/(available_screen - (&showbreak == "" ? 0 : 1)))),
    \    maxwidth: available_screen,
    \    scrollbar: 0
    \ })
endfunction

augroup SoftWrap
  autocmd!
  autocmd CursorHold * call <SID>softwrap(g:softwrap_unwrap)
augroup END
