" Folddigest plugin initialization
" The plugin is implemented in the autocommands functions.
"
" Mantainer:	Pablo Gimenez <pablogipi@gmail.com>
" Last Change:2010-09-16.
" Version: 0.1
" Notes: based on Folddigest plugin by Taro Muraoka:
"   http://www.vim.org/scripts/script.php?script_id=732
"
" Usage: {{{
"	:FoldDigest
"
"   Transform all folds in the current buffer into digest tree form, and
"   show it in another buffer.  The buffer is called ==FOLDDIGEST==.  It shows
"   not only all fold start positions, but also a tree depended on original
"   folds hierarchy.
"
"   In a FOLDDIGEST, you can move around the cursor, and when type <CR> jump
"   to fold at under it.  If you enter FOLDDIGEST window from other windows,
"   when depended buffer is availabeled, it will be synchronized
"   automatically.  If you want to force synchronize, type "r" in a
"   FOLDDIGEST buffer.
"   It is also possible to jump to the folsd under the cursor with a double
"   click.
"   The FOLDDIGEST window is updated when entering in a new buffer.
"
"   :FoldDigestToggle
"
"   Toggles FOLDDIGEST window
"
"   :FoldDigestClose
"
"   close FOLDDIGEST window
" }}}


" Folddigest window name:
let g:FoldDigest_Window_Title = '==FOLDDIGEST=='

" FoldDigest window position
if !exists("g:FoldDigest_Pos")
    let g:FoldDigest_Pos="right"
endif

" Setup all commands: {{{
" Open FoldDigest window
command! -nargs=0 -bar FoldDigest call tdvimFolddigest#FoldDigest()
" Close FoldDigest window
command! -nargs=0 -bar FoldDigestClose call tdvimFolddigest#FoldDigestClose()
" Toggle FoldDigest window
command! -nargs=0 -bar FoldDigestToggle call tdvimFolddigest#FoldDigestToggle()
"}}}

" Setup autocommands: {{{
augroup FoldDigest
    autocmd!
    "autocmd BufEnter ==FOLDDIGEST== call tdvimFolddigest#AutoRefresh()
    autocmd BufEnter g:FoldDigest_Window_Title call tdvimFolddigest#AutoRefresh()
    "autocmd BufEnter g:FoldDigest_Window_Title setlocal nomodifiable
    "autocmd BufLeave g:FoldDigest_Window_Title setlocal modifiable
    autocmd BufEnter * call tdvimFolddigest#ChangeBufferRefresh()
augroup END
" }}}

" Optional mapping: {{{
" Example mapping F8 to FoldDigestToggle()
"nnoremap  <unique> <silent>    <SID>TdvimFoldDigestToggle   :call tdvimFolddigest#FoldDigestToggle()<CR>
"vnoremap  <unique> <silent>    <SID>TdvimFoldDigestToggle   <Esc>:call tdvimFolddigest#FoldDigestToggle()<CR>
"inoremap  <unique> <silent>    <SID>TdvimFoldDigestToggle   <Esc>:call tdvimFolddigest#FoldDigestToggle()<CR>

"nmap <silent> <F8> <SID>TdvimFoldDigestToggle
"imap <silent> <F8> <SID>TdvimFoldDigestToggle
"vmap <silent> <F8> <SID>TdvimFoldDigestToggle
"}}}


" vim: ts=8 ft=vim nowrap fdm=marker
