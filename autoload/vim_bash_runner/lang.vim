if exists('g:loaded_vim_bash_runner_lang')
  finish
endif
let g:loaded_vim_bash_runner_lang = 1

let s:translations = {
\    'ja': {
\        'Terminal': 'ターミナル',
\        'Options': 'オプション',
\        'Execute Current Line': '現在の行を実行',
\        'Execute Current Line As Vimscript': '現在の行をVimscriptとして実行',
\        'Execute Current Line As Bash': '現在の行をBashとして実行',
\        'Show Click Position': 'クリック位置を表示',
\        'New Terminal': '新しいターミナル',
\        'Close Terminal': 'ターミナルを閉じる',
\        'Show Terminals': 'ターミナルを表示',
\        'Language: English': '言語: 英語',
\        'Language: Japanese': '言語: 日本語',
\        'Language: Korean': '言語: 韓国語',
\        'Language: Chinese': '言語: 中国語',
\        'Bash Runner Options': 'Bashランナーオプション',
\        'Terminal List': 'ターミナルリスト',
\        'Close Terminal: Select': '閉じるターミナルを選択',
\        'Show Terminal: Select': '表示するターミナルを選択'
\    },
\    'ko': {
\        'Terminal': '터미널',
\        'Options': '옵션',
\        'Execute Current Line': '현재 줄 실행',
\        'Execute Current Line As Vimscript': '현재 줄을 Vimscript로 실행',
\        'Execute Current Line As Bash': '현재 줄을 Bash로 실행',
\        'Show Click Position': '클릭 위치 표시',
\        'New Terminal': '새 터미널',
\        'Close Terminal': '터미ナル 닫기',
\        'Show Terminals': '터미널 보기',
\        'Language: English': '언어: 영어',
\        'Language: Japanese': '언어: 일본어',
\        'Language: Korean': '언어: 한국어',
\        'Language: Chinese': '언어: 중국어',
\        'Bash Runner Options': 'Bash 러너 옵션',
\        'Terminal List': '터미널 목록',
\        'Close Terminal: Select': '닫을 터미널 선택',
\        'Show Terminal: Select': '표시할 터미널 선택'
\    },
\    'zh': {
\        'Terminal': '终端',
\        'Options': '选项',
\        'Execute Current Line': '执行当前行',
\        'Execute Current Line As Vimscript': '作为Vimscript执行当前行',
\        'Execute Current Line As Bash': '作为Bash执行当前行',
\        'Show Click Position': '显示点击位置',
\        'New Terminal': '新建终端',
\        'Close Terminal': '关闭终端',
\        'Show Terminals': '显示终端',
\        'Language: English': '语言: 英语',
\        'Language: Japanese': '语言: 日语',
\        'Language: Korean': '语言: 韩语',
\        'Language: Chinese': '语言: 中文',
\        'Bash Runner Options': 'Bash Runner 选项',
\        'Terminal List': '终端列表',
\        'Close Terminal: Select': '选择要关闭的终端',
\        'Show Terminal: Select': '选择要显示的终端'
\    }
\}

function! s:translate(text, lang) abort
  if a:lang ==# 'en' || !has_key(s:translations, a:lang) || !has_key(s:translations[a:lang], a:text)
    return a:text
  endif
  return s:translations[a:lang][a:text]
endfunction

function! s:translate_menu_items(items, lang) abort
  let new_items = []
  for item_template in a:items
    let new_item = deepcopy(item_template)
    let new_item.name = s:translate(new_item.name, a:lang)
    if has_key(new_item, 'sub_menu_ref') " sub_menu_ref itself is not translated
      " Sub-menus are resolved at display time or handled by structure
    endif
    call add(new_items, new_item)
  endfor
  return new_items
endfunction

function! vim_bash_runner#lang#SetupMenuLanguage() abort
  let lang = g:vim_bash_runner_language

  let g:term_root_menu = s:translate_menu_items(vim_bash_runner#config#get_menu_template('g:vim_bash_runner_menu_templates.root'), lang)
  let g:term_terminal = s:translate_menu_items(vim_bash_runner#config#get_menu_template('g:vim_bash_runner_menu_templates.terminal'), lang)
  let g:term_options = s:translate_menu_items(vim_bash_runner#config#get_menu_template('g:vim_bash_runner_menu_templates.options'), lang)

  let g:term_title = {}
  for [key, value] in items(g:vim_bash_runner_title_templates)
    let g:term_title[key] = s:translate(value, lang)
  endfor
endfunction

function! vim_bash_runner#lang#SetLanguage(lang_code) abort
  let g:vim_bash_runner_language = a:lang_code
  call vim_bash_runner#lang#SetupMenuLanguage()
  " UI refresh might be needed if a menu is currently open
  if exists('s:popup_ids') && !empty(s:popup_ids) " s:popup_ids is in ui.vim
      call vim_bash_runner#ui#RefreshCurrentMenu()
  endif
endfunction
