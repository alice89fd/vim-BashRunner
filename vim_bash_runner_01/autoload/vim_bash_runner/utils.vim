if exists('g:loaded_vim_bash_runner_utils')
  finish
endif
let g:loaded_vim_bash_runner_utils = 1

" Get item index from a list of dictionaries by key-value pair
function! vim_bash_runner#utils#get_item_idx_by_kv(list, key, value) abort
  for i in range(len(a:list))
    if has_key(a:list[i], a:key) && a:list[i][a:key] ==# a:value
      return i
    endif
  endfor
  return -1
endfunction

" Get item from a list of dictionaries by key-value pair
function! vim_bash_runner#utils#get_item_by_kv(list, key, value) abort
  let idx = vim_bash_runner#utils#get_item_idx_by_kv(a:list, a:key, a:value)
  if idx != -1
    return a:list[idx]
  else
    return {} " Return an empty dictionary if not found
  endif
endfunction

" Get visual selection or current line
function! vim_bash_runner#utils#get_visual_selection_or_current_line() abort
  let lnum = line("'<")
  let endlnum = line("'>")
  return (visualmode() !=# '' && lnum > 0 && endlnum > 0) ? getline(lnum, endlnum) : [getline('.')]
endfunction
