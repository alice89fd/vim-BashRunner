if exists('g:loaded_vim_bash_runner') && g:loaded_vim_bash_runner
  finish
endif
let g:loaded_vim_bash_runner = 1

" トリガーキーの定義。存在しない場合、デフォルトで <F8> を設定。
if !exists('g:vim_bash_runner_trigger_key')
  let g:vim_bash_runner_trigger_key = "<F8>"
endif

" ルートメニューの定義
if !exists('g:vim_bash_runner_root_menu')
  let g:vim_bash_runner_root_menu = [
        \ {'name': 'options',  'color': 'lightmagenta', 'clicked': 0, 'menu_str': 'options',  'menu_str_en': 'Options',  'width': 8,  'popup_winid': 0},
        \ {'name': 'terminal', 'color': 'lightgreen',   'clicked': 0, 'menu_str': 'terminal', 'menu_str_en': 'Terminal', 'width': 10, 'popup_winid': 0},
        \ {'name': 'title',    'color': 'lightcyan',    'clicked': 0, 'menu_str': 'TERMEXEC', 'menu_str_en': 'TERMEXEC', 'width': 10, 'popup_winid': 0}]
endif

" "options" 子メニューの定義
if !exists('g:vim_bash_runner_options')
  let g:vim_bash_runner_options = [
        \ {'name': 'last_line', 'flag': 1, 'menu_str': '実行行マーク', 'menu_str_en': 'Mark Executed Line', 'menupid': 0},
        \ {'name': 'next_line', 'flag': 1, 'menu_str': '次の行に移動', 'menu_str_en': 'Move to Next Line', 'menupid': 0},
        \ {'name': 'trim_spce', 'flag': 1, 'menu_str': '実行時行頭の空白を削除', 'menu_str_en': 'Trim Leading Spaces', 'menupid': 0}]
endif

" "terminal" 子メニューの定義
if !exists('g:vim_bash_runner_terminal')
  let g:vim_bash_runner_terminal = [
        \ {'name': 'add_term', 'flag': 0, 'menu_str': 'Terminalを追加', 'menu_str_en': 'Add Terminal', 'menupid': 0, 'use_flag': 0, 'func': 'vim_bash_runner#CreateNewTerminal'},
        \ {'name': 'fukusuu', 'flag': 0, 'menu_str': '複数対応', 'menu_str_en': 'Multiple Targets', 'menupid': 0, 'use_flag': 1},
        \ {'name': 'sayuu', 'flag': 0, 'menu_str': '左右に並べる', 'menu_str_en': 'Side by Side', 'menupid': 0, 'use_flag': 1}]
endif

" "title" 子メニューの定義 (現在は空)
if !exists('g:vim_bash_runner_title')
  let g:vim_bash_runner_title = []
endif

" ターミナル一覧管理用変数
if !exists('g:vim_bash_runner_lists')
  let g:vim_bash_runner_lists = []
endif

" Vimスクリプトファイルでロードされたときだけこの設定を有効にする。
augroup VimBashRunner
  autocmd!
  " キーマッピングを定義する際に、g:vim_bash_runner_trigger_key を使用する。
  execute 'autocmd VimEnter,BufEnter,BufReadPost * nnoremap <buffer><silent>' . g:vim_bash_runner_trigger_key . ' :call vim_bash_runner#ExecuteCurrentLine()<CR>'
  " マウスクリック処理のマッピング。 <script> を使用してこのスクリプト内でのみ有効にするか、
  " より堅牢なコールバックメカニズムを検討する必要があるかもしれません。
  " ここでは元のスクリプトの動作を維持するために <script> を使用します。
  noremap <script> <LeftMouse> :call vim_bash_runner#ShowClickPosition()<CR>
augroup END

" 言語設定を適用
call vim_bash_runner#SetupMenuLanguage()

" ルートメニューのハイライト定義と表示
for item_dict in g:vim_bash_runner_root_menu
  execute printf('highlight hl%sr ctermfg=%s ctermbg=black', item_dict.name, item_dict.color)
  execute printf('highlight hl%s ctermfg=black ctermbg=%s', item_dict.name, item_dict.color)
endfor

let s:posx = winwidth(0)
for item_idx in range(len(g:vim_bash_runner_root_menu))
  let current_item = g:vim_bash_runner_root_menu[item_idx]
  let opts = {}
  let opts.line = 1
  let s:posx -= current_item.width
  let opts.col = s:posx
  let s:posx -= 1 " メニュー間のスペース
  let opts.pos = 'botleft' " Note: pg2.vim did not specify 'pos', this might change layout slightly. Default is 'topleft'.
  let opts.padding = [0, 1, 0, 1]
  let opts.border = [0, 0, 0, 0]
  let opts.highlight = 'hl' . current_item.name
  let g:vim_bash_runner_root_menu[item_idx].popup_winid = popup_create(current_item.menu_str, opts)
endfor
unlet s:posx