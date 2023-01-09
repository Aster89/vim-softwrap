# vim↪softwrap

When [`nowrap`](https://vimhelp.org/options.txt.html#%27nowrap%27) is active and the current line is not entirely visible (_i.e._ there is text [preceding the character visible in the first column](https://vimhelp.org/options.txt.html#lcs-precedes) and/or text [following the character visible in the last column](https://vimhelp.org/options.txt.html#lcs-extends)), wrap current line on [`CursorHold`](https://vimhelp.org/autocmd.txt.html#CursorHold) without altering the buffer nor the options. This implies that a soft-wrapped line will likely cover part of the line(s) below it; <kbd>Escape</kbd><kbd>Escape</kbd> can be used to dismiss the wrapped line.

[![asciicast](https://asciinema.org/a/cl9Cctupv8MXIAvayz2rLkis3.svg)](https://asciinema.org/a/cl9Cctupv8MXIAvayz2rLkis3)

Setting `g:softwrap_unwrap` to `v:true` "unwraps" the current line over the adjacent windows, and wraps it only if the screensize is not enough:

![wrapunwrap](https://user-images.githubusercontent.com/20521900/207529784-b0a542b5-e645-470e-b2a4-af94ffceb479.png)
