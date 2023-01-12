if &compatible
  finish
endif

if !exists('g:softwrap_unwrap')
  let g:softwrap_unwrap = v:false
elseif type(g:softwrap_unwrap) != 6
  echomsg 'Wrong type for g:softwrap_unwrap'
  finish
endif

if !exists('g:softwrap_patterns')
  let g:softwrap_patterns = ''
elseif type(g:softwrap_patterns) == 3
  let g:softwrap_patterns = join(g:softwrap_patterns, ',')
elseif type(g:softwrap_patterns) != 1
  echomsg 'Wrong type for g:softwrap_patterns.'
  finish
endif

if !hlexists('SoftWrapHighlightGroup')
  highlight SoftWrapHighlightGroup ctermbg=NONE ctermfg=NONE cterm=bold
  autocmd ColorScheme * highlight SoftWrapHighlightGroup ctermbg=NONE ctermfg=NONE cterm=bold
endif

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
  exec 'autocmd CursorMoved ' . g:softwrap_patterns . ' call <sid>enableSoftwrapAutocmdOnCursorHold()'
augroup END

function! s:enableSoftwrapAutocmdOnCursorHold()
  augroup ShowSoftwrapOnCursorHold
    autocmd!
    exec 'autocmd CursorHold ' . g:softwrap_patterns . ' call <SID>showSoftwrap(g:softwrap_unwrap)'
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
    \    maxheight: float2nr(ceil(len(getline(line('.')))*1.0/(available_screen - (&showbreak == "" ? 0 : 1)))),
    \    maxwidth: available_screen,
    \    scrollbar: 0
    \ })

  exe "nnoremap <silent> <esc><esc> :call <SID>closePUM(" . pum . ")<cr>"

  augroup ShowSoftwrapOnCursorHold
    autocmd!
  augroup END
endfunction

function! s:closePUM(pum)
  call popup_close(a:pum)
  nunmap <esc><esc>
endfunction
