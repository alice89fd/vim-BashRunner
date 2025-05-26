if exists('g:loaded_vim_bash_runner_config')
  finish
endif
let g:loaded_vim_bash_runner_config = 1

" Default configuration values
let g:term_list_max_cnt = get(g:, 'term_list_max_cnt', 10)
let g:term_lists = get(g:, 'term_lists', []) " List of active terminal info { 'name': ..., 'bufnr': ..., 'job_id': ... }

" Menu structure templates (English)
" These will be copied and translated by lang.vim into g:term_root_menu etc.

let g:vim_bash_runner_menu_templates = {
\ 'root': [
\    {'key': 'terminal', 'name': 'Terminal', 'sub_menu_ref': 'g:vim_bash_runner_menu_templates.terminal'},
\    {'key': 'options',  'name': 'Options',  'sub_menu_ref': 'g:vim_bash_runner_menu_templates.options'},
\    {'key': 'execute_line', 'name': 'Execute Current Line'},
\    {'key': 'execute_vimscript', 'name': 'Execute Current Line As Vimscript'},
\    {'key': 'execute_bash', 'name': 'Execute Current Line As Bash'},
\    {'key': 'show_click_position', 'name': 'Show Click Position'},
\ ],
\ 'terminal': [
\    {'key': 'new_terminal', 'name': 'New Terminal'},
\    {'key': 'close_terminal', 'name': 'Close Terminal'},
\    {'key': 'show_terminals', 'name': 'Show Terminals'},
\ ],
\ 'options': [
\    {'key': 'language_en', 'name': 'Language: English', 'lang_set': 'en'},
\    {'key': 'language_ja', 'name': 'Language: Japanese', 'lang_set': 'ja'},
\    {'key': 'language_ko', 'name': 'Language: Korean', 'lang_set': 'ko'},
\    {'key': 'language_zh', 'name': 'Language: Chinese', 'lang_set': 'zh'},
\ ]
\}

" Title templates (English)
let g:vim_bash_runner_title_templates = {
\    'main': 'Bash Runner Options',
\    'terminal_list': 'Terminal List',
\    'close_terminal_list': 'Close Terminal: Select',
\    'show_terminal_list': 'Show Terminal: Select'
\}

" Actual menu data to be populated by lang.vim
let g:term_root_menu = []
let g:term_options = []
let g:term_terminal = []
let g:term_title = {}

" Function to get a deep copy of a template
function! vim_bash_runner#config#get_menu_template(template_path) abort
  try
    return deepcopy(eval(a:template_path))
  catch
    echom "Error: Menu template not found: " . a:template_path
    return []
  endtry
endfunction

function! vim_bash_runner#config#get_title_template(key) abort
  return get(g:vim_bash_runner_title_templates, a:key, 'Undefined Title')
endfunction
