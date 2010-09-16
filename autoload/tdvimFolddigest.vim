" TDVimFoldDigest
" Plugin that implements an outliner based on code folding.
"
" Mantainer:	Pablo Gimenez <pablogipi@gmail.com>
" Last Change:2010-09-16.
" Notes: based on Folddigest plugin by Taro Muraoka:
"   http://www.vim.org/scripts/script.php?script_id=732
"

" Options: {{{
"
"   g:FoldDigest_Pos:
"       Position for the FOLDDIGEST window: right, left, bottom, top
"}}}

" TDVim Changelog: {{{
" - 2010-09-01: disabled for non python files. Blank line folding disabled by
"               default.
"               Line numbers spacing set using &numberwidth
" - 2010-09-02: all functions transfered to autoload format with tdvimFolddigest# prefix
" - 2010-09-14: update with buffer change implemented
" - 2010-09-16: return to original window after FOLDDIGEST is created
"               Options for window placement
"               Keymaps
" }}}

function! tdvimFolddigest#HasFlag(flags, flag) "{{{
  return a:flags =~ '\%(^\|,\)'.a:flag.'\%(=\([^,]*\)\)\?\%(,\|$\)'
endfunction
" }}}

" CheckOptions {{{
" Check options passed to the plugin and saves values for the rest of the script
function! tdvimFolddigest#CheckOptions()
  let options = !exists('g:folddigest_options') ? '' : g:folddigest_options
  let s:use_flexnumwidth = tdvimFolddigest#HasFlag(options, 'flexnumwidth')
  let s:use_nofoldclose = tdvimFolddigest#HasFlag(options, 'nofoldclose')
  let s:use_vertical = tdvimFolddigest#HasFlag(options, 'vertical')
  if exists('g:folddigest_size') && (g:folddigest_size + 0) > 0
    let s:digest_size = g:folddigest_size + 0
  else
    let s:digest_size = 0
  endif
endfunction
" }}}

function! tdvimFolddigest#IndicateRawline(linenum) "{{{
  execute 'match Search /\m^\%'.a:linenum.'l\(\s*\d\+ \)\=\%(\%(| \)*+--\|\^\|\$\)/'
endfunction
" }}}

" MarkMasterWindow {{{
" Mark current buffer as the buffer controlled by folddigest
" The curren window number will be saved in the Folddigest window as 
" a window variable so folddigest could know from what window create 
" the folddigest
" The window variable is called folddigested
function! tdvimFolddigest#MarkMasterWindow()
    let winnr = winnr()

    " Set the window and buffer controlled by folddigest
    let fildDigestWinnr = bufwinnr(g:FoldDigest_Window_Title)
    if fildDigestWinnr  > 1
        call setwinvar(fildDigestWinnr , 'folddigested', winnr)
        "echomsg "Buffer marked as master: " . bufname('%') . ", " . winnr()
    endif
endfunction
" }}}

" GoMasterWindow {{{
" Go to the window scanned by folddigest to create its contents.
" It is the window with the code folded.
" This fubnction will take the value from the Folddigest window
" local variable folddigested and jump to the indicated window.
function! tdvimFolddigest#GoMasterWindow(...)
    let flags = a:0 > 0 ? a:1 : ""

    " Test folddigest in Folddigest window
    let fildDigestWinnr = bufwinnr(g:FoldDigest_Window_Title)
    if fildDigestWinnr  > 1
        " Get window controlled by folddigest
        let winnr = getwinvar(fildDigestWinnr , 'folddigested')
        execute winnr.'wincmd w'
        return winnr
    " If folddigest window doesn't exists
    elseif !tdvimFolddigest#HasFlag(flags, 'nosplit')
        let bufname = getbufvar(bufnr('%'), 'bufname')
        if s:use_vertical
            if 0 < s:digest_size && s:digest_size < winwidth(0)
                let size = winwidth(0) - s:digest_size
            else
                let size = ''
            endif
            silent execute "rightbelow ".size." vsplit ".bufname
        else
            if 0 < s:digest_size && s:digest_size < winheight(0)
                let size = winheight(0) - s:digest_size
            else
                let size = ''
            endif
            silent execute "rightbelow ".size." split ".bufname
        endif
        call tdvimFolddigest#MarkMasterWindow()
        return winnr()
    endif

    return 0
endfunction
" }}}

function! tdvimFolddigest#Jump() "{{{
  let mx = '\m^\%(\s*\(\d\+\) \)\=\%(\(\%(| \)*\)+--\(.*\)$\|\^$\|\$$\)'
  let linenr = line('.')
  let lastline = linenr == line('$') ? 1 : 0
  let line = getline(linenr)
  if line !~ mx
    echohl Error
    echo "Format error has been detected"
    echohl None
    return
  endif
  let linenum = substitute(line, mx, '\1', '') + 0
  let level = strlen(substitute(line, mx, '\2', '')) / 2 + 1
  let text = substitute(line, mx, '\3', '')
  call tdvimFolddigest#IndicateRawline(linenr)
  call tdvimFolddigest#GoMasterWindow()
  if lastline
    normal! G
  else
    execute linenum
  endif
  silent! normal! zO
  if !lastline
    normal! zt
  else
    normal! zb
  endif
endfunction
" }}}

function! tdvimFolddigest#Refresh() "{{{
  if tdvimFolddigest#GoMasterWindow('nosplit') > 0
    call tdvimFolddigest#FoldDigest()
  endif
endfunction
" }}}

let s:do_auto_refresh = 1

function! tdvimFolddigest#AutoRefresh() "{{{
  if s:do_auto_refresh
    let s:do_auto_refresh = 0
    call tdvimFolddigest#Refresh()
    let s:do_auto_refresh = 1
  endif
endfunction
" }}}

" MakeDigestBuffer {{{
" Create/find  folddigest's buffer
function! tdvimFolddigest#MakeDigestBuffer()
    let bufnum = bufnr('%')
    let bufname = expand('%:p')
    call tdvimFolddigest#MarkMasterWindow()
    " The old implementation for folddiget use one Folddigest buffer per file scanned
    " We will change this implementation to make it dynamic, so the fold window contents
    " will change when you change your buffer
    " This means we need to change the AutoRefresh function and  make autocommands to update the
    " folddigest buffer when entering in another buffer
    " So far here we use the global folddigest window name defined in the plugin initialization.
    "let name = "==FOLDDIGEST== ".expand('%:t')." [".bufnum."]"
    let name = g:FoldDigest_Window_Title

    " Look if the folddigest window already exists of if we need to create it.
    let winnr = bufwinnr(name)
    let s:do_auto_refresh = 0
    if winnr < 1
        " Create the folddigest window
        " Place FoldDigest window
        let size = s:digest_size > 0 ? s:digest_size : ""
        if g:FoldDigest_Pos == 'right'
            silent execute size." vertical rightbelow  split ++enc= ".escape(name, ' ')
        elseif g:FoldDigest_Pos == 'left'
            silent execute size." vertical leftabove  split ++enc= ".escape(name, ' ')
        elseif g:FoldDigest_Pos == 'bottom'
            silent execute size."  rightbelow  split ++enc= ".escape(name, ' ')
        elseif g:FoldDigest_Pos == 'top'
            silent execute size." leftabove  split ++enc= ".escape(name, ' ')
        else
            echoerr "Folddigest window position not supported: " . g:FoldDigest_Pos
            return
        endif
    else
        " Go to folddigest window
        execute winnr.'wincmd w'
    endif
    let s:do_auto_refresh = 1
    setlocal buftype=nofile bufhidden=hide noswapfile nowrap ft=
    setlocal foldcolumn=0 nonumber
    match none
    call setbufvar(bufnr('%'), 'bufnr', bufnum)
    call setbufvar(bufnr('%'), 'bufname', bufname)
    silent % delete _
    silent 1 put a
    silent 0 delete _
    " Set buffer local syntax and mapping
    syntax match folddigestLinenr display "^\s*\d\+"
    syntax match folddigestTreemark display "\%(| \)*+--"
    syntax match folddigestFirstline display "\^$"
    syntax match folddigestLastline display "\$$"
    hi def link folddigestLinenr Linenr
    hi def link folddigestTreemark Identifier
    hi def link folddigestFirstline Identifier
    hi def link folddigestLastline Identifier
    " Mappings
    nnoremap <silent><buffer> <CR> :call tdvimFolddigest#Jump()<CR>
    nnoremap <silent><buffer> r :call tdvimFolddigest#>Refresh()<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :call tdvimFolddigest#Jump()<CR>

endfunction
" }}}

function! tdvimFolddigest#Foldtext(linenum, text) "{{{
  let text = substitute(a:text, '\m^\s*\%(/\*\|//\)\s*', '', '')
  let text = substitute(text, s:mx_foldmarker, '', 'g')
  let text = substitute(text, s:mx_commentstring, '\1', '')
  let text = substitute(text, '\m\%(^\s\+\|\s\+$\)', '', 'g')
  return text
endfunction
" }}}

function! tdvimFolddigest#AddRegA(linenum, text) "{{{
  let linestr = '       '.a:linenum
  let linestr = strpart(linestr, strlen(linestr) - s:numwidth).' '
  call setreg('A', linestr.a:text."\<NL>")
endfunction
" }}}

function! tdvimFolddigest#AddFoldDigest(linenum) "{{{
  let text = tdvimFolddigest#Foldtext(a:linenum, getline(a:linenum))
  let head = strpart('| | | | | | | | | | | | | | | | | | | ', 0, (foldlevel(a:linenum) - 1) * 2).'+--'
  call tdvimFolddigest#AddRegA(a:linenum, head.text)
endfunction
"}}}

" GenerateFoldDigest {{{
" Create folddigest buffer contents.
" Extract folding info from source file
function! tdvimFolddigest#GenerateFoldDigest()
    " Configure script options
    let s:numwidth = strlen(line('$').'')
    if !s:use_flexnumwidth || s:numwidth < 0 || s:numwidth > 7
        let s:numwidth = 7
    endif
    " Open all folds and fetch lines at start of the fold.
    let foldnum = 0
    let cursorline = line('.')
    let cursorfoldnum = -1
    let firstfoldline = 0
    normal! zRgg
    if foldlevel(1) > 0
        call tdvimFolddigest#AddFoldDigest(1)
        let firstfoldline = 1
    else
        call tdvimFolddigest#AddRegA(1, '^')
    endif
    while 1
        let prevline = line('.')
        normal! zj
        let currline = line('.')
        if prevline == currline
            break
        endif
        if foldlevel(currline) > 0
            if firstfoldline == 0
                let firstfoldline = currline
            endif
            if prevline <= cursorline && cursorline < currline
                let cursorfoldnum = foldnum
            endif
            let foldnum = foldnum + 1
            call tdvimFolddigest#AddFoldDigest(currline)
        endif
    endwhile
    if cursorfoldnum < 0
        let cursorfoldnum = (cursorline == line('$') ? 1 : 0) + foldnum
    endif
    " Put buffer contents in a register
    call tdvimFolddigest#AddRegA(line('$'), '$')
    return cursorfoldnum + 1
endfunction
" }}}

" FoldDigest {{{
" Create/refresh folddigest window contents.
" this is the main function called to open FoldDigest
" At the end the focus will return to the window from which 
" folddigest is created
function! tdvimFolddigest#FoldDigest() 
    " Save current buffer name
    let bufname = bufname('%')

    "if bufname('%') =~# '\m^==FOLDDIGEST=='
    if bufname('%') == g:FoldDigest_Window_Title
        echohl Error
        echo "Can't make digest for FOLDDIGEST buffer"
        echohl None
        return
    endif

    call tdvimFolddigest#CheckOptions()
    " Save cursor position
    let save_line = line('.')
    let save_winline = winline()
    " Save undolevels
    let save_undolevels = &undolevels
    set undolevels=-1
    " Save regsiter "a"
    let save_regcont_a = getreg('a')
    let save_regtype_a = getregtype('a')
    call setreg('a', '')
    " Suppress bell when "normal! zj" in a last fold
    let save_visualbell = &visualbell
    let save_t_vb = &t_vb
    set vb t_vb=
    " Generate regexp pattern for Foldtext()
    let s:mx_foldmarker = "\\V\\%(".substitute(escape(getwinvar(winnr(), '&foldmarker'), '\'), ',', '\\|', 'g')."\\)\\d\\*"
    let s:mx_commentstring = '\V'.substitute(escape(getbufvar(bufnr('%'), '&commentstring'), '\'), '%s', '\\(\\.\\*\\)', 'g').''
    let currfold = tdvimFolddigest#GenerateFoldDigest()
    " Revert bell
    let &visualbell = save_visualbell
    let &t_vb = save_t_vb
    " Revert cursor line
    execute save_line
    if !s:use_nofoldclose
        silent! normal! zMzO
    endif
    " Keep same cursor position as possible
    if save_winline > winline()
        execute "normal! ".(save_winline - winline())."\<C-Y>"
    elseif save_winline < winline()
        execute "normal! ".(winline() - save_winline)."\<C-E>"
    endif
    call tdvimFolddigest#MakeDigestBuffer()

    "echo "currfold=".currfold
    if 0 < currfold && currfold <= line('$')
        execute currfold
        call tdvimFolddigest#IndicateRawline(currfold)
        if currfold == line('$')
            normal! zb
        endif
    endif
    " Revert register "a"
    call setreg('a', save_regcont_a, save_regtype_a)
    " Revert undolevels
    let &undolevels = save_undolevels

    " Return to original window
    exe bufwinnr(bufname) . 'wincmd w'

endfunction
" }}}

" FoldDigestClose {{{
" Function to close the folddigest window.
" Is based in the function Tlist_Window_Close from the TagList plugin
function! tdvimFolddigest#FoldDigestClose()
    " Make sure the folddigest window exists
    let winnum = bufwinnr(g:FoldDigest_Window_Title)
    if winnum == -1
        echoerr "FoldDigest window is not opened"
        return
    endif

    if winnr() == winnum
        " Already in the folddigest window. Close it and return
        if winbufnr(2) != -1
            " If a window other than the folddigest window is open,
            " then only close the folddigest window.
            close
        endif
    else
        " Goto the folddigest window, close it and then come back to the
        " original window
        let curbufnr = bufnr('%')
        exe winnum . 'wincmd w'
        close
        " Need to jump back to the original window only if we are not
        " already in that window
        let winnum = bufwinnr(curbufnr)
        if winnr() != winnum
            exe winnum . 'wincmd w'
        endif
    endif
endfunction
" }}}

" FoldDigestToggle() {{{
" Open or close a FoldDigest window
" Based   on the function Tlist_Window_Toggle from TagList plugin
function! tdvimFolddigest#FoldDigestToggle()
    " If folddigest window is open then close it.
    let winnum = bufwinnr(g:FoldDigest_Window_Title)
    if winnum != -1
        call tdvimFolddigest#FoldDigestClose()
        return
    endif

    " Otherwise open it
    call tdvimFolddigest#FoldDigest()
endfunction
" }}}

" ChangeBufferRefresh() {{{
" Refresh folddigest window when changing to another buffer.
" This function is supposed to be calles from an autocommand.
function! tdvimFolddigest#ChangeBufferRefresh()

    let l:winnr = winnr()
    "echomsg "Current buffer and window: " . bufname('%') . ", " . l:winnr
    " If Folddigest window is not open then go out from here:
    let winnum = bufwinnr(g:FoldDigest_Window_Title)
    if winnum == -1
        return
    endif
    " Check if buffer is a regular one, I mean is a file and is a standard vim buffer
    " Also check if the buffer has folds available
    "if !&modifiable || !&foldenable || findfile(bufname('%')) == ""
    if &buftype != '' || !&foldenable || findfile(bufname('%')) == ""
        " Just for debug
        "echoerr "Buffer can't be loaded in FoldDigest: " . bufname('%')
        " Go out from here
        return
    endif

    call tdvimFolddigest#MarkMasterWindow()
    " Call FoldDigest()
    if tdvimFolddigest#GoMasterWindow('nosplit') > 0
        call tdvimFolddigest#FoldDigest()
    endif
endfunction
" }}}

" vim: ts=8 ft=vim nowrap fdm=marker
