#! vim -u NONE
" プラグイン名 vim_bash_runner
:set viminfo= " viminfoを読み込まない。
:set history=1000 " コマンドライン履歴の保存数を設定（例：1000個）。
:set wildmenu " コマンドラインでメニューによる補完を有効化。
:set wildmode=longest,list " 補完方法を設定（例：共通部分を補完後、候補をリスト表示）。
:set wildignore=*.o,*.obj,*~ " 補完対象から除外するファイルパターンを設定。
:set hlsearch " 検索語をハイライト表示。
:set noincsearch " 検索語をインクリメンタルにハイライト表示。
:set cpo-=< " <>記法を有効とする。
:set cpo-=C " 連結行のコメント継続を有効にする
:set laststatus=2 " ステータスラインを常に表示する。
:set mouse=a

: " トリガーキーの定義。存在しない場合、デフォルトで <F8> を設定。
:if !exists('g:term_trigger_key')
  :let g:term_trigger_key = "<F8>"
:endif

: " ルートメニューの定義
: " 各要素:
: "   name: メニュー名 (内部識別用)
: "   color: 通常時の前景/背景色 (ハイライト名にも使用)
: "   clicked: クリック状態 (0: 非アクティブ, 1: アクティブ)
: "   menu_str: 表示文字列 (日本語)
: "   menu_str_en: 表示文字列 (英語)
: "   width: 表示幅
: "   popup_winid: ポップアップウィンドウID
:let g:term_root_menu = [
      \ {'name': 'options',  'color': 'lightmagenta', 'clicked': 0, 'menu_str': 'options',  'menu_str_en': 'Options',  'width': 8,  'popup_winid': 0},
      \ {'name': 'terminal', 'color': 'lightgreen',   'clicked': 0, 'menu_str': 'terminal', 'menu_str_en': 'Terminal', 'width': 10, 'popup_winid': 0},
      \ {'name': 'title',    'color': 'lightcyan',    'clicked': 0, 'menu_str': 'TERMEXEC', 'menu_str_en': 'TERMEXEC', 'width': 10, 'popup_winid': 0}]

: " "options" 子メニューの定義
: " 各要素:
: "   name: オプション名 (内部識別用)
: "   flag: 有効/無効フラグ (1: 有効, 0: 無効)
: "   menu_str: 表示文字列 (日本語)
: "   menu_str_en: 表示文字列 (英語)
: "   menupid: ポップアップウィンドウID
:let g:term_options = [
      \ {'name': 'last_line', 'flag': 1, 'menu_str': '実行行マーク', 'menu_str_en': 'Mark Executed Line', 'menupid': 0, 'use_flag': 1},
      \ {'name': 'next_line', 'flag': 1, 'menu_str': '次の行に移動', 'menu_str_en': 'Move to Next Line', 'menupid': 0, 'use_flag': 1},
      \ {'name': 'trim_spce', 'flag': 1, 'menu_str': '実行時行頭の空白を削除', 'menu_str_en': 'Trim Leading Spaces', 'menupid': 0, 'use_flag': 1}]

: " "terminal" 子メニューの定義
: " 各要素:
: "   name: 機能名 (内部識別用)
: "   flag: チェックボックス用フラグ (1: オン, 0: オフ)
: "   menu_str: 表示文字列 (日本語)
: "   menu_str_en: 表示文字列 (英語)
: "   menupid: ポップアップウィンドウID
: "   use_flag: チェックボックスとして使用するか (1: する, 0: しない)
: "   func: クリック時に実行する関数名 (use_flagが0の場合)
:let g:term_terminal = [
      \ {'name': 'add_term', 'flag': 0, 'menu_str': 'Terminalを追加', 'menu_str_en': 'Add Terminal', 'menupid': 0, 'use_flag': 0, 'func': 'CreateNewTerminal'},
      \ {'name': 'fukusuu', 'flag': 0, 'menu_str': '複数対応', 'menu_str_en': 'Multiple Targets', 'menupid': 0, 'use_flag': 1},
      \ {'name': 'sayuu', 'flag': 0, 'menu_str': '左右に並べる', 'menu_str_en': 'Side by Side', 'menupid': 0, 'use_flag': 1}]
      " {'name': 'jyouge','flag': 0,'menu_str': '上下に並べる', 'menu_str_en': 'Top and Bottom', 'menupid': 0,'use_flag': 1} "未使用の定義例

: " "title" 子メニューの定義 (現在は空)
:let g:term_title = []

" ターミナル一覧管理用変数
:let g:term_list_max_cnt = 1 " 新規ターミナル名生成時のカウンター
:let g:term_lists = []
: " g:term_lists の要素のサンプル:
: " {'term_name': 'term001', 'target_flg': 1, 'log_name': "", 'last_wrote_line': 1, 'menupid': 0}
: "   term_name: ターミナルバッファ名
: "   target_flg: コマンド実行対象フラグ (1: 対象, 0: 非対象)
: "   log_name: ログファイル名 (未使用)
: "   last_wrote_line: 最後に書き込んだ行番号 (未使用)
: "   menupid: ポップアップウィンドウID

" --- ヘルパー関数 ---

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
  
  let fukusuu_item = s:get_item_by_kv(g:term_terminal, "name", "fukusuu")
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

: " "options" 子メニュー処理関数群
:let g:options_func = {}
  " "options" 子メニューを作成する関数
  function! g:options_func.CreatePopup()
    for c in range(len(g:term_options))
      let menu_text = (g:term_options[c].flag ? '[x]' : '[ ]') . ' ' . g:term_options[c].menu_str
      let option_popup_opts = {'line': 2 + c, 'col': winwidth(0) - 30, 'minwidth': 30, 'highlight': 'hloptions', 'padding': [0, 1, 0, 1], 'border': [0, 0, 0, 0]}
      let g:term_options[c].menupid = popup_create(menu_text, option_popup_opts)
    endfor
  endfunction

  " "options" 子メニューを削除する関数
  function! g:options_func.DeletePopup()
    for c in range(len(g:term_options))
      if g:term_options[c].menupid != 0
        call popup_close(g:term_options[c].menupid)
        let g:term_options[c].menupid = 0
      endif
    endfor
  endfunction

  " "options" 子メニューを更新する関数
  function! g:options_func.UpdatePopup()
    for c in range(len(g:term_options))
      if g:term_options[c].menupid != 0
        let menu_text = (g:term_options[c].flag ? '[x]' : '[ ]') . ' ' . g:term_options[c].menu_str
        call popup_settext(g:term_options[c].menupid, menu_text)
      endif
    endfor
  endfunction

: " "terminal" 子メニュー処理関数群
:let g:terminal_func = {}
  " "terminal" 子メニューを作成する関数
  function! g:terminal_func.CreatePopup()
    " terminal一覧
    for cnt_term in range(len(g:term_lists))
      call s:create_or_update_terminal_list_item_popup(g:term_lists[cnt_term], cnt_term, winwidth(0) - 64)
    endfor

    " terminal操作メニュー
    for c in range(len(g:term_terminal))
      let menu_text = ''
      if g:term_terminal[c].use_flag
        let menu_text = (g:term_terminal[c].flag ? '[x]' : '[ ]') . ' ' . g:term_terminal[c].menu_str
      else
        let menu_text = '    ' . g:term_terminal[c].menu_str
      endif
      let option_popup_opts = {'line': 2 + c, 'col': winwidth(0) - 30, 'minwidth': 30, 'highlight': 'hlterminal', 'padding': [0, 1, 0, 1], 'border': [0, 0, 0, 0]}
      let g:term_terminal[c].menupid = popup_create(menu_text, option_popup_opts)
    endfor
  endfunction

  " "terminal" 子メニューを削除する関数
  function! g:terminal_func.DeletePopup()
    " terminal一覧
    for cnt_term in range(len(g:term_lists))
      if g:term_lists[cnt_term].menupid != 0
        call popup_close(g:term_lists[cnt_term].menupid)
        let g:term_lists[cnt_term].menupid = 0
      endif
    endfor

    " terminal操作メニュー
    for c in range(len(g:term_terminal))
      if g:term_terminal[c].menupid != 0
        call popup_close(g:term_terminal[c].menupid)
        let g:term_terminal[c].menupid = 0
      endif
    endfor
  endfunction

  " "terminal" 子メニューを更新する関数
  function! g:terminal_func.UpdatePopup()
    " terminal一覧
    for cnt_term in range(len(g:term_lists))
      call s:create_or_update_terminal_list_item_popup(g:term_lists[cnt_term], cnt_term, winwidth(0) - 64)
    endfor

    " terminal操作メニュー
    for c in range(len(g:term_terminal))
      if g:term_terminal[c].menupid != 0
        let menu_text = ''
        if g:term_terminal[c].use_flag
          let menu_text = (g:term_terminal[c].flag ? '[x]' : '[ ]') . ' ' . g:term_terminal[c].menu_str
        else
          let menu_text = '    ' . g:term_terminal[c].menu_str
        endif
        call popup_settext(g:term_terminal[c].menupid, menu_text)
      endif
    endfor
  endfunction

: " "title" 子メニュー処理関数群
:let g:title_func = {}
  " "title" 子メニューを作成する関数
  function! g:title_func.CreatePopup()
    for c in range(len(g:term_title))
      let menu_text = (g:term_title[c].flag ? '[x]' : '[ ]') . ' ' . g:term_title[c].menu_str
      let option_popup_opts = {'line': 2 + c, 'col': winwidth(0) - 30, 'minwidth': 30, 'highlight': 'hlterminal', 'padding': [0, 1, 0, 1], 'border': [0, 0, 0, 0]}
      let g:term_title[c].menupid = popup_create(menu_text, option_popup_opts)
    endfor
  endfunction

  " "title" 子メニューを削除する関数
  function! g:title_func.DeletePopup()
    for c in range(len(g:term_title))
      if g:term_title[c].menupid != 0
        call popup_close(g:term_title[c].menupid)
        let g:term_title[c].menupid = 0
      endif
    endfor
  endfunction

  " "title" 子メニューを更新する関数
  function! g:title_func.UpdatePopup()
    for c in range(len(g:term_title))
      if g:term_title[c].menupid != 0
        let menu_text = (g:term_title[c].flag ? '[x]' : '[ ]') . ' ' . g:term_title[c].menu_str
        call popup_settext(g:term_title[c].menupid, menu_text)
      endif
    endfor
  endfunction

" --- 主要関数 ---

" ターミナルウィンドウの表示/非表示を制御し、レイアウトを調整する関数。
function! ShowTerminal()
  let current_winid = win_getid() " 現在のウィンドウIDを保持

  " 全ての既存ターミナルウィンドウを一旦隠す
  for term_info in g:term_lists
    let term_winid = bufwinid(term_info.term_name)
    if term_winid != -1
      call win_gotoid(term_winid)
      execute "hide"
    endif
  endfor
  call win_gotoid(current_winid) " 元のウィンドウに戻る

  let first_split = 1
  let sayuu_item = s:get_item_by_kv(g:term_terminal, "name", "sayuu")
  let is_sayuu_split = (sayuu_item != v:null && sayuu_item.flag)

  " target_flg がオンのターミナルを表示する
  for term_info in filter(copy(g:term_lists), 'v:val.target_flg')
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

  " g:term_lists一覧の表示更新
  let terminal_menu_item = s:get_item_by_kv(g:term_root_menu, "name", "terminal")
  if terminal_menu_item != v:null && terminal_menu_item.clicked
    call g:terminal_func.UpdatePopup()
  endif
endfunction

" 新しいターミナルを作成する関数。
function! CreateNewTerminal()
  let term_name = 'term' . printf('%03d', g:term_list_max_cnt)
  let g:term_list_max_cnt += 1

  call term_start(['bash'], {'term_name': term_name, 'term_finish': 'close', 'hidden': 1})

  " 複数フラグをチェックしてオフの時の処理
  let fukusuu_item = s:get_item_by_kv(g:term_terminal, "name", "fukusuu")
  if fukusuu_item != v:null && !fukusuu_item.flag
    " 複数オプションオフなら既存は全てオフに
    for term_item in g:term_lists
      let term_item.target_flg = 0
    endfor
  endif

  " g:term_lists に追加
  call add(g:term_lists, {'term_name': term_name, 'target_flg': 1, 'log_name': "", 'last_wrote_line': 1, 'menupid': 0})

  " g:term_lists の表示を更新
  call ShowTerminal()

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

" カレント行のテキストをVimスクリプトとして実行する関数。
function! ExecuteCurrentLineAsVimscript(line_content)
  " 取得したテキストをVimスクリプトとして実行。
  try
    execute a:line_content
  catch /^Vim\%((\a\+)\)\=:E\d+:/
    echohl ErrorMsg
    echomsg "Error executing: " . v:exception
    echohl None
  endtry
endfunction

" カレント行のテキストをBashコマンドとして実行する関数。
function! ExecuteCurrentLineAsBash(line_content)
  " ターミナルが未作成であれば作成
  if empty(g:term_lists)
    call CreateNewTerminal()
  endif

  for term_info in g:term_lists " ターミナル情報を取得。
    if !has_key(term_info, 'term_name') " 基本的にこの条件は満たされないはず
      echomsg "term information is not found."
      return
    endif
    if term_info.target_flg
      " コマンドを実行する。
      if empty(a:line_content)
        call term_sendkeys(bufnr(term_info.term_name), "\<CR>")
      else
        call term_sendkeys(bufnr(term_info.term_name), a:line_content . "\<CR>")
      endif
    endif
  endfor
endfunction

" カレント行をVimscriptまたはBashで実行する関数。
function! ExecuteCurrentLine()
  let line_content = getline(line('.')) " カレント行のテキストを取得。

  " 実行した行のsign処理。
  let last_line_opt = s:get_item_by_kv(g:term_options, 'name', 'last_line')
  if last_line_opt != v:null && last_line_opt.flag
    call sign_define('TermExecuted', {'text': '->', 'texthl': 'Search'})
    call sign_unplace('*', {'group': 'TermExecuted'}) " 同じグループの既存サインを全て削除
    call sign_place(0, 'TermExecuted', 'TermExecuted', bufnr('%'), {'lnum': line('.')})
  else
    call sign_unplace('*', {'group': 'TermExecuted'})
  endif

  " 次の非コメント行へ移動 (複数行コメントに対応)
  let next_line_opt = s:get_item_by_kv(g:term_options, 'name', 'next_line')
  if next_line_opt != v:null && next_line_opt.flag
    let current_line_num = line('.')
    let next_line_num = current_line_num + 1
    while next_line_num <= line('$') && getline(next_line_num) =~# '^\s*#'
      let next_line_num += 1
    endwhile
    if next_line_num <= line('$') && next_line_num != current_line_num " 同じ行に留まらないように
      call cursor(next_line_num, 1)
    endif
  endif

  " あたまの空白のトリム
  let trim_spce_opt = s:get_item_by_kv(g:term_options, 'name', 'trim_spce')
  if trim_spce_opt != v:null && trim_spce_opt.flag
    let line_content = substitute(line_content, '^\s\+', '', '')
  endif

  " 実行
  if line_content =~# '^\s*:'
    call ExecuteCurrentLineAsVimscript(line_content) " 行の先頭が : ならvimscriptとして実行。
  else
    call ExecuteCurrentLineAsBash(line_content)
  endif
endfunction

" 子メニュー項目がクリックされた場合の処理
function! s:ProcessSubMenuClick(root_item_data, mouse_winid)
  let sub_menu_list_var_name = "term_" . a:root_item_data.name
  if !exists('g:' . sub_menu_list_var_name)
    return 0 " 処理対象なし
  endif
  let sub_menu_list_ref = get(g:, sub_menu_list_var_name)

  for item_idx in range(len(sub_menu_list_ref))
    let item_ref = sub_menu_list_ref[item_idx]
    if a:mouse_winid == item_ref.menupid
      if item_ref.use_flag " チェックボックス形式のメニュー
        let item_ref.flag = !item_ref.flag
        let func_dict_name = a:root_item_data.name . "_func"
        let func_dict = get(g:, func_dict_name, {})
        if has_key(func_dict, 'UpdatePopup')
          call func_dict.UpdatePopup()
        endif
      else " 関数呼び出し形式のメニュー
        if has_key(item_ref, 'func') && !empty(item_ref.func)
          let Func = function(item_ref.func)
          call Func()
          " CreateNewTerminal後はterminalメニューの更新が必要
          if a:root_item_data.name ==# 'terminal'
            call g:terminal_func.UpdatePopup()
          endif
        endif
      endif
      return 1 " 処理完了
    endif
  endfor
  return 0 " 処理対象なし
endfunction

" ルートメニュー項目がクリックされた場合の処理
function! s:ProcessRootMenuClick(root_item_ref, mouse_winid)
  if a:mouse_winid != a:root_item_ref.popup_winid
    return 0 " 処理対象なし
  endif

  let func_dict_name = a:root_item_ref.name . "_func"
  let func_dict = get(g:, func_dict_name, {})

  if a:root_item_ref.clicked == 0 " クリックされていなかったメニューを開く
    " 他の開いているルートメニューを閉じる
    for other_root_item_idx in filter(range(len(g:term_root_menu)), 'g:term_root_menu[v:val].clicked == 1')
      let other_root_item_ref = g:term_root_menu[other_root_item_idx]
      let other_func_dict_name = other_root_item_ref.name . "_func"
      let other_func_dict = get(g:, other_func_dict_name, {})

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
  else " クリックされていたメニューを閉じる
    let a:root_item_ref.clicked = 0
    call popup_setoptions(a:root_item_ref.popup_winid, {'highlight': 'hl' . a:root_item_ref.name})
    if has_key(func_dict, 'DeletePopup')
      call func_dict.DeletePopup()
    endif
  endif
  return 1 " 処理完了
endfunction

" ターミナル一覧の項目がクリックされた場合の処理
function! s:ProcessTerminalListItemClick(term_item_ref, mouse_winid, is_fukusuu_enabled, item_idx)
  if a:mouse_winid != a:term_item_ref.menupid
    return 0 " 処理対象なし
  endif

  if bufnr(a:term_item_ref.term_name) == -1 " 押されたterm_nameがbufを持ってなければg:term_listsから削除
    call popup_close(a:term_item_ref.menupid) " 先にポップアップを閉じる
    call remove(g:term_lists, a:item_idx)
    call g:terminal_func.UpdatePopup() " リスト更新
    return 1 " 処理完了
  endif

  if !a:is_fukusuu_enabled " 「複数対応」がオフか？
    " target_flgをゼロクリアして押されたもののみtarget_flgを1に変更
    for item_in_list in g:term_lists
      let item_in_list.target_flg = 0
    endfor
    let a:term_item_ref.target_flg = 1
  else " 「複数対応」がオン時の処理
    let a:term_item_ref.target_flg = !a:term_item_ref.target_flg
  endif
  call ShowTerminal() " 表示更新
  return 1 " 処理完了
endfunction

" 「複数対応」ボタンがクリックされた場合の処理
function! s:ProcessFukusuuButtonClick(fukusuu_item, mouse_winid)
  if a:fukusuu_item == v:null || a:mouse_winid != a:fukusuu_item.menupid
    return 0 " 処理対象なし
  endif

  " フラグのトグルは s:ProcessSubMenuClick で既に行われている前提
  if !a:fukusuu_item.flag " 「複数対応」がオフになった場合
    " 全てのターミナルの target_flg をオフにする
    for term_in_list in g:term_lists
      let term_in_list.target_flg = 0
    endfor
    " 必要であれば、最初のターミナルを選択状態にするなどの処理を追加
    " if !empty(g:term_lists)
    "    let g:term_lists[0].target_flg = 1
    " endif
  endif
  call ShowTerminal() " 表示更新
  return 1 " 処理完了
endfunction

" マウスクリック時に実行される関数。各種メニュー操作を処理する。
function! ShowClickPosition()
  redir >> log.txt " デバッグ用ログ開始
  call getchar() " マウスイベントを消費
  echo "行番号: " . v:mouse_lnum . ", 列番号: " . v:mouse_col . ", winid: " . v:mouse_winid

  " 子メニュー項目がクリックされたか確認
  for root_item_idx in range(len(g:term_root_menu))
    let current_root_item_data = g:term_root_menu[root_item_idx]
    if current_root_item_data.clicked " 対応するルートメニューが開いている場合のみ子メニューを処理
      if s:ProcessSubMenuClick(current_root_item_data, v:mouse_winid)
        redraw
        redir END
        return
      endif
    endif
  endfor

  " ルートメニューがクリックされたか確認
  for root_item_idx in range(len(g:term_root_menu))
    if s:ProcessRootMenuClick(g:term_root_menu[root_item_idx], v:mouse_winid)
      redraw
      redir END
      return
    endif
  endfor

  " ターミナル一覧項目がクリックされたか確認
  let fukusuu_item = s:get_item_by_kv(g:term_terminal, "name", "fukusuu")
  let is_fukusuu_enabled = (fukusuu_item != v:null && fukusuu_item.flag)
  for term_idx in range(len(g:term_lists))
    if s:ProcessTerminalListItemClick(g:term_lists[term_idx], v:mouse_winid, is_fukusuu_enabled, term_idx)
      redraw
      redir END
      return
    endif
  endfor

  " 「複数対応」ボタンがクリックされたか確認
  if s:ProcessFukusuuButtonClick(fukusuu_item, v:mouse_winid)
    redraw
    redir END
    return
  endif

  redraw " 上記いずれにも該当しない場合も再描画
  redir END " デバッグ用ログ終了
  " 元のマウスクリックイベントを実行したい場合はここに記述するが、
  " :normal! <LeftMouse> は再帰呼び出しになるため注意が必要。
  " 通常はポップアップ操作で完결するため不要。
endfunction

" --- 言語設定 ---
" 環境変数 LANG に基づいてメニューの表示言語を設定する
function! s:SetupMenuLanguage()
  let lang_env = $LANG
  let is_japanese = 0
  if lang_env =~? '^ja'
    let is_japanese = 1
  endif

  if !is_japanese
    for item in g:term_root_menu
      if has_key(item, 'menu_str_en')
        let item.menu_str = item.menu_str_en
      endif
    endfor
    for item in g:term_options
      if has_key(item, 'menu_str_en')
        let item.menu_str = item.menu_str_en
      endif
    endfor
    for item in g:term_terminal
      if has_key(item, 'menu_str_en')
        let item.menu_str = item.menu_str_en
      endif
    endfor
    for item in g:term_title " 現在は空だが将来のために
      if has_key(item, 'menu_str_en')
        let item.menu_str = item.menu_str_en
      endif
    endfor
  endif
endfunction

" Vimスクリプトファイルでロードされたときだけこの設定を有効にする。
augroup ExecuteCurrentLine
  autocmd!
  " キーマッピングを定義する際に、g:term_trigger_key を使用する。
  execute 'autocmd VimEnter,BufEnter,BufReadPost * nnoremap <buffer><silent>' . g:term_trigger_key . ' :call ExecuteCurrentLine()<CR>'
  noremap <script> <LeftMouse> :call ShowClickPosition()<CR>
augroup END

" 言語設定を適用
call s:SetupMenuLanguage()

" ルートメニューのハイライト定義と表示
for item_dict in g:term_root_menu
  execute printf('highlight hl%sr ctermfg=%s ctermbg=black', item_dict.name, item_dict.color)
  execute printf('highlight hl%s ctermfg=black ctermbg=%s', item_dict.name, item_dict.color)
endfor

let s:posx = winwidth(0)
for item_idx in range(len(g:term_root_menu))
  let current_item = g:term_root_menu[item_idx]
  let opts = {}
  let opts.line = 1
  let s:posx -= current_item.width
  let opts.col = s:posx
  let s:posx -= 1 " メニュー間のスペース
  let opts.pos = 'botleft'
  let opts.padding = [0, 1, 0, 1]
  let opts.border = [0, 0, 0, 0]
  let opts.highlight = 'hl' . current_item.name
  let g:term_root_menu[item_idx].popup_winid = popup_create(current_item.menu_str, opts)
endfor
unlet s:posx
