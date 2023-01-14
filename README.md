# vim↪softwrap

When [`nowrap`][1] is active and the current line is not entirely visible (_i.e._ there is text [preceding the character visible in the first column][2] and/or text [following the character visible in the last column][3]), wrap current line on [`CursorHold`][4] without altering the buffer nor the options. This implies that a soft-wrapped line will likely cover part of the line(s) below it.

<kbd>Escape</kbd><kbd>Escape</kbd> can be used to dismiss the wrapped line, and <kbd>Space</kbd><kbd>Space</kbd> can be used to show it again, but you can change the combos by setting `g:softwrap_close_popup_mapping` and `g:softwrap_open_popup_mapping` respectively.

Furthermore, you can use `g:softwrap_buf_patterns` to govern for which type of files the popup should be triggered, and whether it should do so on cursor movement or on cursor staying still.

See `:help softwrap` for details.


[![asciicast](https://asciinema.org/a/cl9Cctupv8MXIAvayz2rLkis3.svg)](https://asciinema.org/a/cl9Cctupv8MXIAvayz2rLkis3)

Setting `g:softwrap_unwrap_popup` to `v:true` "unwraps" the current line over the adjacent windows, and wraps it only if the screen size is not enough:

![wrapunwrap](https://user-images.githubusercontent.com/20521900/207529784-b0a542b5-e645-470e-b2a4-af94ffceb479.png)


[1]: https://vimhelp.org/options.txt.html#%27nowrap%27
[2]: https://vimhelp.org/options.txt.html#lcs-precedes
[3]: https://vimhelp.org/options.txt.html#lcs-extends
[4]: https://vimhelp.org/autocmd.txt.html#CursorHold
