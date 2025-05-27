if exists('g:loaded_vim_bash_runner_executor')
  finish
endif
let g:loaded_vim_bash_runner_executor = 1

let s:is_windows = has('win32') || has('win64')

function! vim_bash_runner#executor#ExecuteCurrentLine() abort
  let lines = vim_bash_runner#utils#get_visual_selection_or_current_line()
  let cmd = join(lines, '; ')

  if !exists('g:term_lists') | let g:term_lists = [] | endif

  if empty(g:term_lists)
    echom "No active terminal. Creating one."
    call vim_bash_runner#terminal#CreateNewTerminal()
  endif

  if !empty(g:term_lists)
    let latest_term_info = g:term_lists[-1]
    if bufexists(latest_term_info.bufnr) &&ชาว('term_getjob', latest_term_info.bufnr) != 0
      call term_sendkeys(latest_term_info.bufnr, cmd . "\<CR>")
      if !s:is_windows
        " Focus the terminal window briefly to ensure it's visible, then return focus
        let current_win = win_getid()
        execute bufwinnr(latest_term_info.bufnr) . "wincmd w"
        call win_gotoid(current_win)
      else
         " On Windows, term_sendkeys might be enough, or specific handling might be needed
         " For now, no explicit focus change to avoid issues.
      endif
    else
      echom "Latest terminal (bufnr " . latest_term_info.bufnr . ") is not valid or job not running. Creating a new one."
      call vim_bash_runner#terminal#CreateNewTerminal()
      " Retry sending command to the new terminal (assuming CreateNewTerminal updates g:term_lists)
      if !empty(g:term_lists)
        let new_latest_term_info = g:term_lists[-1]
        call term_sendkeys(new_latest_term_info.bufnr, cmd . "\<CR>")
      else
        echoerr "Failed to create a new terminal for execution."
      endif
    endif
  else
    echoerr "Failed to find or create a terminal for execution."
  endif
endfunction

function! vim_bash_runner#executor#ExecuteCurrentLineAsVimscript() abort
  let lines = vim_bash_runner#utils#get_visual_selection_or_current_line()
  try
    execute join(lines, "\n")
  catch
    echoerr "Error executing Vimscript: " . v:exception
  endtry
endfunction

function! vim_bash_runner#executor#ExecuteCurrentLineAsBash() abort
  let lines = vim_bash_runner#utils#get_visual_selection_or_current_line()
  let cmd = join(lines, "\n")
  echom system('bash -c ' . shellescape(cmd))
endfunction
