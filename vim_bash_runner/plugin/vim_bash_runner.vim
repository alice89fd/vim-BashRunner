if exists('g:loaded_vim_bash_runner') && g:loaded_vim_bash_runner
  finish
endif
let g:loaded_vim_bash_runner = 1

" Default trigger key, user can override in vimrc
let g:term_trigger_key = get(g:, 'term_trigger_key', '<Leader>r')

" Default language, user can override in vimrc
let g:vim_bash_runner_language = get(g:, 'vim_bash_runner_language', 'en')

" Ensure mouse support is enabled for popup interaction if desired by user
" Users might manage this globally, so we don't force it.
" if &mouse == ''
"   set mouse=a
" endif

augroup VimBashRunnerAu
  autocmd!
  " Initialize language settings once Vim is fully entered.
  " Using User event to allow deferral and explicit call if needed.
  autocmd User VimBashRunnerInit call s:VimBashRunnerInit()
  autocmd VimEnter * if !exists('s:vim_bash_runner_initialized') | doautocmd User VimBashRunnerInit | endif
augroup END

let s:vim_bash_runner_initialized = 0
function! s:VimBashRunnerInit() abort
  if s:vim_bash_runner_initialized | return | endif
  let s:vim_bash_runner_initialized = 1
  call vim_bash_runner#lang#SetupMenuLanguage()

  " Define mappings using <Plug> for user customization
  noremap <silent> <Plug>(VimBashRunnerShowMenu) :call vim_bash_runner#ui#CreateOptionsPopup([])<CR>
  noremap <silent> <Plug>(VimBashRunnerExecuteLine) :call vim_bash_runner#executor#ExecuteCurrentLine()<CR>
  noremap <silent> <Plug>(VimBashRunnerExecuteLineAsVimscript) :call vim_bash_runner#executor#ExecuteCurrentLineAsVimscript()<CR>
  noremap <silent> <Plug>(VimBashRunnerExecuteLineAsBash) :call vim_bash_runner#executor#ExecuteCurrentLineAsBash()<CR>
  noremap <silent> <Plug>(VimBashRunnerShowClickPosition) :call vim_bash_runner#ui#ShowClickPosition()<CR>

  " Map the trigger key to show the menu
  execute 'noremap <silent> ' . g:term_trigger_key . ' <Plug>(VimBashRunnerShowMenu)'
endfunction

command! VimBashRunnerShowMenu call vim_bash_runner#ui#CreateOptionsPopup([])
command! VimBashRunnerExecuteLine call vim_bash_runner#executor#ExecuteCurrentLine()
command! VimBashRunnerExecuteLineAsVimscript call vim_bash_runner#executor#ExecuteCurrentLineAsVimscript()
command! VimBashRunnerExecuteLineAsBash call vim_bash_runner#executor#ExecuteCurrentLineAsBash()
command! VimBashRunnerShowClickPosition call vim_bash_runner#ui#ShowClickPosition()
