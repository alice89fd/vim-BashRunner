let s:list_max_cnt = 1 " 新規ターミナル名生成時のカウンター

" メニューハンドラの定義
let s:options_menu_handler = {}
let s:terminal_menu_handler = {}
let s:title_menu_handler = {}

" リスト内の辞書要素を 'name' キーで検索し、そのインデックスを返す。
" 見つからない場合は -1 を返す。
function! s:get_item_idx_by_name(list, item_name)
  let idx_list = filter(range(len(a:list)), 'a:list[v:val].name ==# a:item_name')
  return len(idx_list) > 0 ? idx_list[0] : -1
endfunction

" リスト内の辞書要素を指定されたキーと値で検索し、その要素自体を返す。
" 見つからない場合は v:null を返す。
function! s:get_item_by_kv(list, key, value)
  let items = filter(copy(a:list), 'v:val[a:key] ==# a:value') " copy() は defensive
  return len(items) > 0 ? items[0] : v:null
endfunction

" terminal一覧のポップアップアイテムを作成または更新する。
function! s:create_or_update_terminal_list_item_popup(term_item_ref, index, base_col)
  let popup_options = {
        \ 'line': a:index + 2,
        \ 'col': a:base_col,
        \ 'minwidth': 30,
        \ 'highlight': 'hlterminal',
        \ 'padding': [0, 1, 0, 1],
        \ 'border': [0, 0, 0, 0]
        \ }

  let fukusuu_item = s:get_item_by_kv(g:vim_bash_runner_terminal, "name", "fukusuu")
  let text_prefix = ''
  if fukusuu_item != v:null && fukusuu_item.flag
    let text_prefix = (a:term_item_ref.target_flg ? '[x]' : '[ ]')
  else
    let text_prefix = (a:term_item_ref.target_flg ? '(x)' : '( )')
  endif

  let item_text = printf('%s %s b(%d) w(%d)',
        \ text_prefix,
        \ a:term_item_ref.term_name,
        \ bufnr(a:term_item_ref.term_name),
        \ bufwinid(a:term_item_ref.term_name))

  if has_key(a:term_item_ref, 'menupid') && a:term_item_ref.menupid != 0
    try
      call popup_settext(a:term_item_ref.menupid, item_text)
    catch
      " ポップアップが存在しない場合 (例: ウィンドウが閉じられた後など)
      let a:term_item_ref.menupid = popup_create(item_text, popup_options)
    endtry
  else
    let a:term_item_ref.menupid = popup_create(item_text, popup_options)
  endif
endfunction

" --- 子メニュー処理関数 ---

function! s:options_menu_handler.CreatePopup()
  for c in range(len(g:vim_bash_runner_options))
    let menu_text = (g:vim_bash_runner_options[c].flag ? '[x]' : '[ ]') . ' ' . g:vim_bash_runner_options[c].menu_str
    let option_popup_opts = {'line': 2 + c, 'col': winwidth(0) - 30, 'minwidth': 30, 'highlight': 'hloptions', 'padding': [0, 1, 0, 1], 'border': [0, 0, 0, 0]}
    let g:vim_bash_runner_options[c].menupid = popup_create(menu_text, option_popup_opts)
  endfor
endfunction

function! s:options_menu_handler.DeletePopup()
  for c in range(len(g:vim_bash_runner_options))
    if g:vim_bash_runner_options[c].menupid != 0
      call popup_close(g:vim_bash_runner_options[c].menupid)
      let g:vim_bash_runner_options[c].menupid = 0
    endif
  endfor
endfunction

function! s:options_menu_handler.UpdatePopup()
  for c in range(len(g:vim_bash_runner_options))
    if g:vim_bash_runner_options[c].menupid != 0
      let menu_text = (g:vim_bash_runner_options[c].flag ? '[x]' : '[ ]') . ' ' . g:vim_bash_runner_options[c].menu_str
      call popup_settext(g:vim_bash_runner_options[c].menupid, menu_text)
    endif
  endfor
endfunction

function! s:terminal_menu_handler.CreatePopup()
  " terminal一覧
  for cnt_term in range(len(g:vim_bash_runner_lists))
    call s:create_or_update_terminal_list_item_popup(g:vim_bash_runner_lists[cnt_term], cnt_term, winwidth(0) - 64)
  endfor

  " terminal操作メニュー
  for c in range(len(g:vim_bash_runner_terminal))
    let menu_text = ''
    if g:vim_bash_runner_terminal[c].use_flag
      let menu_text = (g:vim_bash_runner_terminal[c].flag ? '[x]' : '[ ]') . ' ' . g:vim_bash_runner_terminal[c].menu_str
    else
      let menu_text = '    ' . g:vim_bash_runner_terminal[c].menu_str
    endif
    let option_popup_opts = {'line': 2 + c, 'col': winwidth(0) - 30, 'minwidth': 30, 'highlight': 'hlterminal', 'padding': [0, 1, 0, 1], 'border': [0, 0, 0, 0]}
    let g:vim_bash_runner_terminal[c].menupid = popup_create(menu_text, option_popup_opts)
  endfor
endfunction

function! s:terminal_menu_handler.DeletePopup()
  " terminal一覧
  for cnt_term in range(len(g:vim_bash_runner_lists))
    if g:vim_bash_runner_lists[cnt_term].menupid != 0
      call popup_close(g:vim_bash_runner_lists[cnt_term].menupid)
      let g:vim_bash_runner_lists[cnt_term].menupid = 0
    endif
  endfor

  " terminal操作メニュー
  for c in range(len(g:vim_bash_runner_terminal))
    if g:vim_bash_runner_terminal[c].menupid != 0
      call popup_close(g:vim_bash_runner_terminal[c].menupid)
      let g:vim_bash_runner_terminal[c].menupid = 0
    endif
  endfor
endfunction

function! s:terminal_menu_handler.UpdatePopup()
  " terminal一覧
  for cnt_term in range(len(g:vim_bash_runner_lists))
    call s:create_or_update_terminal_list_item_popup(g:vim_bash_runner_lists[cnt_term], cnt_term, winwidth(0) - 64)
  endfor

  " terminal操作メニュー
  for c in range(len(g:vim_bash_runner_terminal))
    if g:vim_bash_runner_terminal[c].menupid != 0
      let menu_text = ''
      if g:vim_bash_runner_terminal[c].use_flag
        let menu_text = (g:vim_bash_runner_terminal[c].flag ? '[x]' : '[ ]') . ' ' . g:vim_bash_runner_terminal[c].menu_str
      else
        let menu_text = '    ' . g:vim_bash_runner_terminal[c].menu_str
      endif
      call popup_settext(g:vim_bash_runner_terminal[c].menupid, menu_text)
    endif
  endfor
endfunction

function! s:title_menu_handler.CreatePopup()
  for c in range(len(g:vim_bash_runner_title))
    let menu_text = (g:vim_bash_runner_title[c].flag ? '[x]' : '[ ]') . ' ' . g:vim_bash_runner_title[c].menu_str
    let option_popup_opts = {'line': 2 + c, 'col': winwidth(0) - 30, 'minwidth': 30, 'highlight': 'hlterminal', 'padding': [0, 1, 0, 1], 'border': [0, 0, 0, 0]}
    let g:vim_bash_runner_title[c].menupid = popup_create(menu_text, option_popup_opts)
  endfor
endfunction

function! s:title_menu_handler.DeletePopup()
  for c in range(len(g:vim_bash_runner_title))
    if g:vim_bash_runner_title[c].menupid != 0
      call popup_close(g:vim_bash_runner_title[c].menupid)
      let g:vim_bash_runner_title[c].menupid = 0
    endif
  endfor
endfunction

function! s:title_menu_handler.UpdatePopup()
  for c in range(len(g:vim_bash_runner_title))
    if g:vim_bash_runner_title[c].menupid != 0
      let menu_text = (g:vim_bash_runner_title[c].flag ? '[x]' : '[ ]') . ' ' . g:vim_bash_runner_title[c].menu_str
      call popup_settext(g:vim_bash_runner_title[c].menupid, menu_text)
    endif
  endfor
endfunction

function! s:GetMenuHandler(menu_name)
  if a:menu_name ==# 'options'
    return s:options_menu_handler
  elseif a:menu_name ==# 'terminal'
    return s:terminal_menu_handler
  elseif a:menu_name ==# 'title'
    return s:title_menu_handler
  else
    return {}
  endif
endfunction

" --- 主要関数 ---

function! vim_bash_runner#ShowTerminal()
  let current_winid = win_getid() " 現在のウィンドウIDを保持

  " 全ての既存ターミナルウィンドウを一旦隠す
  for term_info in g:vim_bash_runner_lists
    let term_winid = bufwinid(term_info.term_name)
    if term_winid != -1
      call win_gotoid(term_winid)
      execute "hide"
    endif
  endfor
  call win_gotoid(current_winid) " 元のウィンドウに戻る

  let first_split = 1
  let sayuu_item = s:get_item_by_kv(g:vim_bash_runner_terminal, "name", "sayuu")
  let is_sayuu_split = (sayuu_item != v:null && sayuu_item.flag)

  " target_flg がオンのターミナルを表示する
  for term_info in filter(copy(g:vim_bash_runner_lists), 'v:val.target_flg')
    if first_split
      let first_split = 0
      execute "bo sp | buffer! " . bufnr(term_info.term_name)
    else
      if is_sayuu_split
        execute "rightbelow vsplit | buffer! " . bufnr(term_info.term_name)
      else
        execute "bo sp | buffer! " . bufnr(term_info.term_name)
      endif
    endif
  endfor
  call win_gotoid(current_winid) " 元のウィンドウに戻る

  " g:vim_bash_runner_lists一覧の表示更新
  let terminal_menu_item = s:get_item_by_kv(g:vim_bash_runner_root_menu, "name", "terminal")
  if terminal_menu_item != v:null && terminal_menu_item.clicked
    call s:terminal_menu_handler.UpdatePopup()
  endif
endfunction

function! vim_bash_runner#CreateNewTerminal()
  let term_name = 'term' . printf('%03d', s:list_max_cnt)
  let s:list_max_cnt += 1

  call term_start(['bash'], {'term_name': term_name, 'term_finish': 'close', 'hidden': 1})

  " 複数フラグをチェックしてオフの時の処理
  let fukusuu_item = s:get_item_by_kv(g:vim_bash_runner_terminal, "name", "fukusuu")
  if fukusuu_item != v:null && !fukusuu_item.flag
    " 複数オプションオフなら既存は全てオフに
    for term_item in g:vim_bash_runner_lists
      let term_item.target_flg = 0
    endfor
  endif

  " g:vim_bash_runner_lists に追加
  call add(g:vim_bash_runner_lists, {'term_name': term_name, 'target_flg': 1, 'log_name': "", 'last_wrote_line': 1, 'menupid': 0})

  " g:vim_bash_runner_lists の表示を更新
  call vim_bash_runner#ShowTerminal()

  " bashのプロンプトが表示されるまで待機
  let start_time = reltime()
  let timeout_seconds = 5
  while reltime(start_time)[0] < timeout_seconds
    if getbufline(bufnr(term_name), 1, '$')[-1] =~# '.*[\$#].*'
      break
    endif
    sleep 100m
  endwhile
endfunction

function! vim_bash_runner#ExecuteCurrentLineAsVimscript(line_content)
  try
    execute a:line_content
  catch /^Vim\%((\a\+)\)\=:E\d+:/
    echohl ErrorMsg
    echomsg "Error executing: " . v:exception
    echohl None
  endtry
endfunction

function! vim_bash_runner#ExecuteCurrentLineAsBash(line_content)
  if empty(g:vim_bash_runner_lists)
    call vim_bash_runner#CreateNewTerminal()
  endif

  for term_info in g:vim_bash_runner_lists
    if !has_key(term_info, 'term_name')
      echomsg "term information is not found."
      return
    endif
    if term_info.target_flg
      if empty(a:line_content)
        call term_sendkeys(bufnr(term_info.term_name), "\<CR>")
      else
        call term_sendkeys(bufnr(term_info.term_name), a:line_content . "\<CR>")
      endif
    endif
  endfor
endfunction

function! vim_bash_runner#ExecuteCurrentLine()
  let line_content = getline(line('.'))

  let last_line_opt = s:get_item_by_kv(g:vim_bash_runner_options, 'name', 'last_line')
  if last_line_opt != v:null && last_line_opt.flag
    call sign_define('TermExecuted', {'text': '->', 'texthl': 'Search'})
    call sign_unplace('*', {'group': 'TermExecuted'})
    call sign_place(0, 'TermExecuted', 'TermExecuted', bufnr('%'), {'lnum': line('.')})
  else
    call sign_unplace('*', {'group': 'TermExecuted'})
  endif

  let next_line_opt = s:get_item_by_kv(g:vim_bash_runner_options, 'name', 'next_line')
  if next_line_opt != v:null && next_line_opt.flag
    let current_line_num = line('.')
    let next_line_num = current_line_num + 1
    while next_line_num <= line('$') && getline(next_line_num) =~# '^\s*#'
      let next_line_num += 1
    endwhile
    if next_line_num <= line('$') && next_line_num != current_line_num
      call cursor(next_line_num, 1)
    endif
  endif

  let trim_spce_opt = s:get_item_by_kv(g:vim_bash_runner_options, 'name', 'trim_spce')
  if trim_spce_opt != v:null && trim_spce_opt.flag
    let line_content = substitute(line_content, '^\s\+', '', '')
  endif

  if line_content =~# '^\s*:'
    call vim_bash_runner#ExecuteCurrentLineAsVimscript(line_content)
  else
    call vim_bash_runner#ExecuteCurrentLineAsBash(line_content)
  endif
endfunction

function! s:ProcessSubMenuClick(root_item_data, mouse_winid)
  let sub_menu_list_var_name = "vim_bash_runner_" . a:root_item_data.name
  if !exists('g:' . sub_menu_list_var_name)
    return 0
  endif
  let sub_menu_list_ref = get(g:, sub_menu_list_var_name)

  for item_idx in range(len(sub_menu_list_ref))
    let item_ref = sub_menu_list_ref[item_idx]
    if a:mouse_winid == item_ref.menupid
      if item_ref.use_flag
        let item_ref.flag = !item_ref.flag
        let func_dict = s:GetMenuHandler(a:root_item_data.name)
        if has_key(func_dict, 'UpdatePopup')
          call func_dict.UpdatePopup()
        endif
      else
        if has_key(item_ref, 'func') && !empty(item_ref.func)
          let Func = function(item_ref.func) " Assuming func name is global or autoloaded
          if stridx(item_ref.func, '#') == -1 && item_ref.func !=# 'CreateNewTerminal' " Simple global function
             let Func = function(item_ref.func)
             call Func()
          elseif item_ref.func ==# 'CreateNewTerminal' " Special case for CreateNewTerminal
             call vim_bash_runner#CreateNewTerminal()
          else " Autoloaded function
             let Func = function(item_ref.func)
             call Func()
          endif

          if a:root_item_data.name ==# 'terminal'
            call s:terminal_menu_handler.UpdatePopup()
          endif
        endif
      endif
      return 1
    endif
  endfor
  return 0
endfunction

function! s:ProcessRootMenuClick(root_item_ref, mouse_winid)
  if a:mouse_winid != a:root_item_ref.popup_winid
    return 0
  endif

  let func_dict = s:GetMenuHandler(a:root_item_ref.name)

  if a:root_item_ref.clicked == 0
    for other_root_item_idx in filter(range(len(g:vim_bash_runner_root_menu)), 'g:vim_bash_runner_root_menu[v:val].clicked == 1')
      let other_root_item_ref = g:vim_bash_runner_root_menu[other_root_item_idx]
      let other_func_dict = s:GetMenuHandler(other_root_item_ref.name)

      let other_root_item_ref.clicked = 0
      call popup_setoptions(other_root_item_ref.popup_winid, {'highlight': 'hl' . other_root_item_ref.name})
      if has_key(other_func_dict, 'DeletePopup')
        call other_func_dict.DeletePopup()
      endif
    endfor
    let a:root_item_ref.clicked = 1
    call popup_setoptions(a:root_item_ref.popup_winid, {'highlight': 'hl' . a:root_item_ref.name . "r"})
    if has_key(func_dict, 'CreatePopup')
      call func_dict.CreatePopup()
    endif
  else
    let a:root_item_ref.clicked = 0
    call popup_setoptions(a:root_item_ref.popup_winid, {'highlight': 'hl' . a:root_item_ref.name})
    if has_key(func_dict, 'DeletePopup')
      call func_dict.DeletePopup()
    endif
  endif
  return 1
endfunction

function! s:ProcessTerminalListItemClick(term_item_ref, mouse_winid, is_fukusuu_enabled, item_idx)
  if a:mouse_winid != a:term_item_ref.menupid
    return 0
  endif

  if bufnr(a:term_item_ref.term_name) == -1
    call popup_close(a:term_item_ref.menupid)
    call remove(g:vim_bash_runner_lists, a:item_idx)
    call s:terminal_menu_handler.UpdatePopup()
    return 1
  endif

  if !a:is_fukusuu_enabled
    for item_in_list in g:vim_bash_runner_lists
      let item_in_list.target_flg = 0
    endfor
    let a:term_item_ref.target_flg = 1
  else
    let a:term_item_ref.target_flg = !a:term_item_ref.target_flg
  endif
  call vim_bash_runner#ShowTerminal()
  return 1
endfunction

function! s:ProcessFukusuuButtonClick(fukusuu_item, mouse_winid)
  if a:fukusuu_item == v:null || a:mouse_winid != a:fukusuu_item.menupid
    return 0
  endif

  if !a:fukusuu_item.flag
    for term_in_list in g:vim_bash_runner_lists
      let term_in_list.target_flg = 0
    endfor
  endif
  call vim_bash_runner#ShowTerminal()
  return 1
endfunction

function! vim_bash_runner#ShowClickPosition()
  call getchar() " マウスイベントを消費

  for root_item_idx in range(len(g:vim_bash_runner_root_menu))
    let current_root_item_data = g:vim_bash_runner_root_menu[root_item_idx]
    if current_root_item_data.clicked
      if s:ProcessSubMenuClick(current_root_item_data, v:mouse_winid)
        redraw
        return
      endif
    endif
  endfor

  for root_item_idx in range(len(g:vim_bash_runner_root_menu))
    if s:ProcessRootMenuClick(g:vim_bash_runner_root_menu[root_item_idx], v:mouse_winid)
      redraw
      return
    endif
  endfor

  let fukusuu_item = s:get_item_by_kv(g:vim_bash_runner_terminal, "name", "fukusuu")
  let is_fukusuu_enabled = (fukusuu_item != v:null && fukusuu_item.flag)
  for term_idx in range(len(g:vim_bash_runner_lists))
    if s:ProcessTerminalListItemClick(g:vim_bash_runner_lists[term_idx], v:mouse_winid, is_fukusuu_enabled, term_idx)
      redraw
      return
    endif
  endfor

  if s:ProcessFukusuuButtonClick(fukusuu_item, v:mouse_winid)
    redraw
    return
  endif

  redraw
endfunction

function! vim_bash_runner#SetupMenuLanguage()
  let lang_env = $LANG
  let is_japanese = 0
  if lang_env =~? '^ja'
    let is_japanese = 1
  endif

  if !is_japanese
    for item in g:vim_bash_runner_root_menu
      if has_key(item, 'menu_str_en')
        let item.menu_str = item.menu_str_en
      endif
    endfor
    for item in g:vim_bash_runner_options
      if has_key(item, 'menu_str_en')
        let item.menu_str = item.menu_str_en
      endif
    endfor
    for item in g:vim_bash_runner_terminal
      if has_key(item, 'menu_str_en')
        let item.menu_str = item.menu_str_en
      endif
    endfor
    for item in g:vim_bash_runner_title
      if has_key(item, 'menu_str_en')
        let item.menu_str = item.menu_str_en
      endif
    endfor
  endif
endfunction