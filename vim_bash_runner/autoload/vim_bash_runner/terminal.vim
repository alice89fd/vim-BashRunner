if exists('g:loaded_vim_bash_runner_terminal')
  finish
endif
let g:loaded_vim_bash_runner_terminal = 1

let s:is_windows = has('win32') || has('win64')

function! s:on_exit(job, exitval) dict abort
  echom "Terminal job " . self.job_id . " exited with " . a:exitval
  call s:close_terminal_buffer(self.bufnr, self.job_id)
endfunction

function! s:close_terminal_buffer(bufnr, job_id) abort
  if bufexists(a:bufnr)
    silent! execute 'bdelete! ' . a:bufnr
  endif
  let idx = vim_bash_runner#utils#get_item_idx_by_kv(g:term_lists, 'job_id', a:job_id)
  if idx != -1
    call remove(g:term_lists, idx)
  endif
  " If terminal list popup is open, refresh it
  if exists('s:terminal_list_popup_id') && s:terminal_list_popup_id > 0 " s:terminal_list_popup_id is in ui.vim
    if get(g:term_title, 'key_for_close_popup', '') ==# get(popup_getoptions(s:terminal_list_popup_id), 'title', '') ||
     \ get(g:term_title, 'key_for_show_popup', '') ==# get(popup_getoptions(s:terminal_list_popup_id), 'title', '')
      call vim_bash_runner#ui#CreateOrUpdateTerminalListItemPopup(popup_getoptions(s:terminal_list_popup_id).purpose)
    endif
  endif
endfunction

function! vim_bash_runner#terminal#GetTerminalName(index) abort
  return 'Terminal-' . (a:index + 1)
endfunction

function! vim_bash_runner#terminal#CreateNewTerminal() abort
  if !exists('g:term_lists') | let g:term_lists = [] | endif
  if len(g:term_lists) >= g:term_list_max_cnt
    echoerr "Maximum terminal count (" . g:term_list_max_cnt . ") reached."
    return
  endif

  let term_name = vim_bash_runner#terminal#GetTerminalName(len(g:term_lists))
  let term_options = {'curwin': 1, 'hidden': 0}
  if has('nvim')
    execute 'new'
    execute 'terminal'
    let bufnr = bufnr('%')
    let job_id = b:terminal_job_id
  else " Vim
    let cmd = s:is_windows ? 'cmd.exe' : get(g:, 'vim_bash_runner_shell', 'bash')
    let job_id = term_start(cmd, term_options)
    let bufnr = term_getjob(job_id).bufnr
    execute bufwinnr(bufnr) . "wincmd w" " Focus the new terminal window
  endif

  if job_id > 0 && bufexists(bufnr)
    call add(g:term_lists, {'name': term_name, 'bufnr': bufnr, 'job_id': job_id})
    setlocal buftype=nofile bufhidden=hide noswapfile
    echom term_name . " created (Job ID: " . job_id . ", Bufnr: " . bufnr . ")"
    
    " Setup exit callback
    let callback_info = {'job_id': job_id, 'bufnr': bufnr}
    if has('nvim')
      " Neovim handles exit differently, often via autocmds or jobwait
      " For simplicity, we'll rely on manual closure or plugin unload for now.
      " A more robust solution would use autocmd TermClose or similar.
    else " Vim
      call job_setoptions(job_id, {'exit_cb': {job_id -> function('s:on_exit', [job_id, callback_info])(job_id)}})
    endif
  else
    echoerr "Failed to create terminal."
  endif
endfunction

function! vim_bash_runner#terminal#ShowTerminal(term_info) abort
  if bufexists(a:term_info.bufnr)
    execute bufwinnr(a:term_info.bufnr) . "wincmd w"
  else
    echoerr "Terminal buffer " . a:term_info.bufnr . " for " . a:term_info.name . " not found."
  endif
endfunction

function! vim_bash_runner#terminal#CloseTerminalByNameOrIndex(identifier) abort
  let idx = -1
  if type(a:identifier) == type(0) " Index
    if a:identifier >= 0 && a:identifier < len(g:term_lists)
      let idx = a:identifier
    endif
  elseif type(a:identifier) == type('') " Name
    let idx = vim_bash_runner#utils#get_item_idx_by_kv(g:term_lists, 'name', a:identifier)
  endif

  if idx != -1 && idx < len(g:term_lists)
    let term_info = g:term_lists[idx]
    echom "Closing " . term_info.name . " (Job ID: " . term_info.job_id . ")"
    if has('nvim')
      silent! execute 'bdelete! ' . term_info.bufnr
    else " Vim
      call job_stop(term_info.job_id) " This should trigger s:on_exit
    endif
    " s:on_exit or direct removal will handle g:term_lists update
  else
    echoerr "Terminal not found: " . a:identifier
  endif
endfunction
