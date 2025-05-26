if exists('g:loaded_vim_bash_runner_ui')
  finish
endif
let g:loaded_vim_bash_runner_ui = 1

let s:popup_ids = [] " Stack of open popup window IDs
let s:current_menu_path = [] " Path of keys to the current menu
let s:terminal_list_popup_id = 0 " ID of the terminal list popup

function! s:close_all_popups() abort
  while !empty(s:popup_ids)
    let pid = remove(s:popup_ids, -1)
    if popup_exists(pid)
      call popup_close(pid)
    endif
  endwhile
  let s:current_menu_path = []
  if s:terminal_list_popup_id > 0 && popup_exists(s:terminal_list_popup_id)
    call popup_close(s:terminal_list_popup_id)
    let s:terminal_list_popup_id = 0
  endif
endfunction

function! s:get_menu_items_by_path(path_list) abort
  let current_level_items = g:term_root_menu
  for key_in_path in a:path_list
    let found_item = vim_bash_runner#utils#get_item_by_kv(current_level_items, 'key', key_in_path)
    if !empty(found_item) && has_key(found_item, 'sub_menu_ref')
      let current_level_items = vim_bash_runner#config#get_menu_template(found_item.sub_menu_ref)
      " Apply translation to this dynamically loaded submenu
      let current_level_items = s:translate_submenu(current_level_items, g:vim_bash_runner_language)
    elseif !empty(found_item) && has_key(found_item, 'sub_menu') " Legacy or direct sub_menu
      let current_level_items = found_item.sub_menu
    else
      return [] " Path not valid or no submenu
    endif
  endfor
  return current_level_items
endfunction

" Helper to translate dynamically loaded submenus (used by s:get_menu_items_by_path)
function! s:translate_submenu(items, lang)
    let translated_items = []
    for item_template in a:items
        let new_item = deepcopy(item_template)
        " Assuming lang.vim's s:translate is not directly accessible,
        " we might need a vim_bash_runner#lang#translate_text function or re-fetch from global translated menus.
        " For simplicity, let's assume g:term_terminal and g:term_options are already translated.
        " This part needs careful handling if sub_menu_ref points to a template that needs fresh translation.
        " The current lang.vim populates g:term_terminal and g:term_options directly.
        if item_template.sub_menu_ref == 'g:vim_bash_runner_menu_templates.terminal'
            return g:term_terminal " Return already translated version
        elseif item_template.sub_menu_ref == 'g:vim_bash_runner_menu_templates.options'
            return g:term_options " Return already translated version
        endif
        " Fallback for items not covered above (should not happen with current structure)
        let new_item.name = vim_bash_runner#lang#translate_text_if_needed(new_item.name, lang) " Requires such a function
        call add(translated_items, new_item)
    endfor
    return translated_items
endfunction


function! vim_bash_runner#ui#CreateOptionsPopup(path_list) abort
  call s:close_all_popups() " Close any existing popups before creating a new chain
  let s:current_menu_path = deepcopy(a:path_list) " Set current path

  let menu_items_to_display = empty(s:current_menu_path) ? g:term_root_menu : s:get_menu_items_by_path(s:current_menu_path)

  if empty(menu_items_to_display)
    echom "No menu items for path: " . string(s:current_menu_path)
    return
  endif

  let display_texts = map(deepcopy(menu_items_to_display), 'v:val.name')

  let popup_options = {
        \ 'title': get(g:term_title, 'main', 'Options'),
        \ 'line': 'cursor',
        \ 'col': 'cursor',
        \ 'highlight': 'PopupNotification',
        \ 'border': [],
        \ 'callback': function('vim_bash_runner#ui#ProcessSubMenuClick')
        \}
  let pid = popup_create(display_texts, popup_options)
  call add(s:popup_ids, pid)
endfunction

function! vim_bash_runner#ui#ProcessSubMenuClick(popup_id, result) abort
  call popup_close(a:popup_id)
  let idx = index(s:popup_ids, a:popup_id, 0, 1) " ignore_case = 1
  if idx != -1
    call remove(s:popup_ids, idx)
  endif

  if a:result < 1 | return | endif " No item selected or popup closed

  let current_menu_items = empty(s:current_menu_path) ? g:term_root_menu : s:get_menu_items_by_path(s:current_menu_path)
  if empty(current_menu_items) || a:result > len(current_menu_items)
    echom "Error: Could not determine selected item."
    let s:current_menu_path = [] " Reset path on error
    return
  endif

  let selected_item = current_menu_items[a:result - 1]

  call s:close_all_popups() " Close current popups before action or new submenu

  " Dispatch based on selected_item.key
  let key = get(selected_item, 'key', '')
  if key ==# 'terminal' || key ==# 'options' || has_key(selected_item, 'sub_menu_ref') || has_key(selected_item, 'sub_menu')
    let s:current_menu_path += [selected_item.key]
    call vim_bash_runner#ui#CreateOptionsPopup(s:current_menu_path) " Open submenu
  elseif key ==# 'new_terminal'
    call vim_bash_runner#terminal#CreateNewTerminal()
  elseif key ==# 'close_terminal'
    call vim_bash_runner#ui#CreateOrUpdateTerminalListItemPopup(1) " 1 for close
  elseif key ==# 'show_terminals'
    call vim_bash_runner#ui#CreateOrUpdateTerminalListItemPopup(0) " 0 for show
  elseif key ==# 'execute_line'
    call vim_bash_runner#executor#ExecuteCurrentLine()
  elseif key ==# 'execute_vimscript'
    call vim_bash_runner#executor#ExecuteCurrentLineAsVimscript()
  elseif key ==# 'execute_bash'
    call vim_bash_runner#executor#ExecuteCurrentLineAsBash()
  elseif key ==# 'show_click_position'
    call vim_bash_runner#ui#ShowClickPosition()
  elseif stridx(key, 'language_') == 0 && has_key(selected_item, 'lang_set')
    call vim_bash_runner#lang#SetLanguage(selected_item.lang_set)
    " Menu will be refreshed by SetLanguage if it was open, or next time it's opened.
  else
    echom "Action not implemented for key: " . key
    let s:current_menu_path = [] " Reset path
  endif
endfunction

function! vim_bash_runner#ui#CreateOrUpdateTerminalListItemPopup(purpose) abort
  " purpose: 0 for show, 1 for close
  call s:close_all_popups() " Close main menu popups

  if empty(g:term_lists)
    echom "No active terminals."
    return
  endif

  let term_display_names = map(deepcopy(g:term_lists), 'v:val.name')
  if empty(term_display_names)
    echom "No terminals to list."
    return
  endif

  let title_key = a:purpose == 1 ? 'close_terminal_list' : 'show_terminal_list'
  let popup_title = get(g:term_title, title_key, 'Terminal List')

  let popup_options = {
        \ 'title': popup_title,
        \ 'line': 'cursor', 'col': 'cursor',
        \ 'highlight': 'PopupNotification', 'border': [],
        \ 'callback': { id, result -> s:handle_terminal_selection(id, result, a:purpose) }
        \}
  let s:terminal_list_popup_id = popup_create(term_display_names, popup_options)
endfunction

function! s:handle_terminal_selection(popup_id, result, purpose) abort
  call popup_close(a:popup_id)
  let s:terminal_list_popup_id = 0
  if a:result < 1 || a:result > len(g:term_lists) | return | endif

  let selected_term_info = g:term_lists[a:result - 1]

  if a:purpose == 1 " Close
    call vim_bash_runner#terminal#CloseTerminalByNameOrIndex(selected_term_info.name)
  else " Show (purpose == 0)
    call vim_bash_runner#terminal#ShowTerminal(selected_term_info)
  endif
endfunction

function! vim_bash_runner#ui#ShowClickPosition() abort
  let pos = getmousepos()
  echom "Mouse Click Position: Line=" . pos.line . ", Col=" . pos.col .
        \ ", Window=" . pos.winid . ", Buffer=" . pos.bufnum
endfunction

function! vim_bash_runner#ui#RefreshCurrentMenu() abort
  " This function is called by lang.vim after language change if a menu is open.
  if !empty(s:popup_ids) || s:terminal_list_popup_id > 0
    let current_path_copy = deepcopy(s:current_menu_path) " Save current path
    call s:close_all_popups()
    " Reopen the menu at the same path, which will now use new language strings
    if !empty(current_path_copy)
        call vim_bash_runner#ui#CreateOptionsPopup(current_path_copy)
    else
        " If no specific path, or if it was the root, just allow user to reopen.
        " Or, could reopen root menu: call vim_bash_runner#ui#CreateOptionsPopup([])
    endif
  endif
endfunction

" Placeholder for a text translation function if needed directly in UI (e.g. for dynamic submenus not pre-translated)
" This would ideally call a function in lang.vim or lang.vim ensures all menu parts are translated.
function! vim_bash_runner#lang#translate_text_if_needed(text, lang)
    " For now, this is a stub. Proper implementation would look up in s:translations from lang.vim
    " However, current design aims to have lang.vim prepare all g:term_... menus fully.
    return a:text
endfunction
