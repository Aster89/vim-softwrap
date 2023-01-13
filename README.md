# vim↪softwrap

When [`nowrap`][1] is active and the current line is not entirely visible (_i.e._ there is text [preceding the character visible in the first column][2] and/or text [following the character visible in the last column][3]), wrap current line on [`CursorHold`][4] without altering the buffer nor the options. This implies that a soft-wrapped line will likely cover part of the line(s) below it; <kbd>Escape</kbd><kbd>Escape</kbd> can be used to dismiss the wrapped line, but you can change the combo by setting `g:softwrap_close_popup_mapping`.

The plugin is only active for the buffers matching the pattern defined by `g:softwrap_patterns`, which can be a string or a list of strings (in the latter case they are joined by interspersing commas in between the items).

The highlight group used by the pop-up is `SoftWrapHighlighGroup`, and can be customized.

See `:help softwrap` for details.


[![asciicast](https://asciinema.org/a/cl9Cctupv8MXIAvayz2rLkis3.svg)](https://asciinema.org/a/cl9Cctupv8MXIAvayz2rLkis3)

Setting `g:softwrap_unwrap_popup` to `v:true` "unwraps" the current line over the adjacent windows, and wraps it only if the screen size is not enough:

![wrapunwrap](https://user-images.githubusercontent.com/20521900/207529784-b0a542b5-e645-470e-b2a4-af94ffceb479.png)


[1]: https://vimhelp.org/options.txt.html#%27nowrap%27
[2]: https://vimhelp.org/options.txt.html#lcs-precedes
[3]: https://vimhelp.org/options.txt.html#lcs-extends
[4]: https://vimhelp.org/autocmd.txt.html#CursorHold
