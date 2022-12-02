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
  let fst_vis_scr_col_in_win = winfo.wincol + winfo.textoff
  let fst_scr_col_in_win = screencol() - virtcol('.') + 1
  let textwidth = winfo.width - winfo.textoff
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
    \    maxheight: float2nr(ceil(len(getline(line('.')))*1.0/available_screen)),
    \    maxwidth: available_screen,
    \    scrollbar: 0
    \ })
endfunction

augroup SoftWrap
  autocmd!
  autocmd CursorHold * call <SID>softwrap(g:softwrap_unwrap)
augroup END
