:" <>記法を有効とする
:set cpo-=<

:" 変数
:let g:term_lists=[{'term_name': 'term001', 'target_flg': 1,'log_name': "", 'last_wrote_line': 1}]
:let g:term_winid = 0
:let g:term_strip_space = 1

" Signの定義
:sign define TermexecLine text=>> texthl=Search

:function! Termexec()
  :" テキストのカレント行の取得
  :let l:current_line=line('.')
  :let l:command=getline(l:current_line)

  :" 次の非コメント行へ移動 (複数行コメントに対応)
  :let l:next_line = line('.') + 1
  :while l:next_line <= line('$') && getline(l:next_line) =~# '^\s*#'
    :let l:next_line += 1
    :endwhile
  :if l:next_line <= line('$')
    :call cursor(l:next_line, 1)
    :endif

  :" :始まりの文字列の場合はexコマンドとして実行します
  :" :::なら:に変換してtermで実行する
  :if l:command =~ "^\\s*:::"
    let l:command = substitute(l:command,"^\\s*:::",":","")
  :else
    :if l:command =~ "^\\s*:" | :exec l:command | :return | :endif
    :endif

  :" term画面が開いてなけばhiddenで開いてspして別windowに表示
  :for c in range(len(g:term_lists))
    :if g:term_lists[c].target_flg != 0
      :if bufnr(g:term_lists[c].term_name) == -1
        :" termを起動
        :call term_start('/bin/bash',{'term_name': g:term_lists[c].term_name, 'term_finish':'close', 'hidden':1})

        :if g:term_winid == 0
          :let l:current_winid = win_getid() " 現在のウィンドウIDを取得します。
          :let l:winid_bef=[] | :for wininfo in getwininfo() | call add(l:winid_bef, wininfo.winid) | :endfor " 現在のウィンドウID一覧を取得します。
          :bo split " ウィンドウを分割します。
          :let l:winid_aft=[] | :for wininfo in getwininfo() | call add(l:winid_aft, wininfo.winid) | :endfor " 新しいウィンドウIDを探します。
          :call filter(l:winid_aft,{idx,val->index(l:winid_bef,val)==-1}) " 現在のウィンドウIDと異なるものを新しいウィンドウIDとします。
          :let g:term_winid = l:winid_aft[0]
          :call win_gotoid(g:term_winid) " termのwindowに移動
          :execute "buffer " . bufnr(g:term_lists[c].term_name)
          :call win_gotoid(l:current_winid) " 元のウィンドウに戻ります。
          :" bashのプロンプトが表示されるまで待機
          :let l:start_time=reltime()
          :while reltime(l:start_time)[0] < 5
            :if getbufline(bufnr(g:term_lists[c].term_name), 1,'$')[-1] =~ '.*[\$#].*' |:break|:endif
            :sleep 100m
            :endwhile
          :" ログファイル名の生成
          :let g:term_lists[c].log_name = fnamemodify(printf('log/%s-%s', g:term_lists[c].term_name, strftime('%Y%m%d-%H%M%S')), ':p') 
          :endif
        :endif

      :" 行頭空白の削除を行う
      :if g:term_strip_space == 1 | :let l:command=substitute(l:command , "^\\s*","","") | :endif

      :" 端末モードの確認
      :if term_getstatus(bufnr(g:term_lists[c].term_name)) =~ 'normal'
        :let l:current_winid = win_getid() " 現在のウィンドウIDを取得します。
        :call win_gotoid(bufwinid(bufnr(g:term_lists[c].term_name))) " g:term_winidを使うか、最初のwinidに行くかどちらもどちら
        :normal i
        :call win_gotoid(l:current_winid) " 元のウィンドウに戻ります。
        :endif

      :" 実行内容の転送
      :call term_sendkeys(bufnr(g:term_lists[c].term_name),l:command . "\<CR>")

      :" コマンド実行ログの書き込み
      :if strlen(l:command) > 0
        :call writefile([printf("[%s] %s", strftime('%Y-%m-%d %H:%M:%S'), l:command)], g:term_lists[c].log_name."command.log", 'a')
        :endif

      :" ターミナルの未書き込みの部分をファイルに書き込み
      :call writefile(getbufline(bufnr(g:term_lists[c].term_name), g:term_lists[c].last_wrote_line , '$'), g:term_lists[c].log_name.".log", 'a')
      :let g:term_lists[c].last_wrote_line = term_getscrolled(bufnr(g:term_lists[c].term_name)) + term_getcursor(bufnr(g:term_lists[c].term_name))[0]
      :echo "last_wrote_line: " . g:term_lists[c].last_wrote_line
      :endif
    :endfor

  :" 今回実行した行にサインを配置
  :call sign_unplace('*', {'group': 'TermexecLine'})
  :call sign_place(0, 'TermexecLine', 'TermexecLine', bufnr('%') , {'lnum': l:current_line })
  :endfunction

:nnoremap <Tab>     :call Termexec()<CR>
:vnoremap <Tab>     y\|:@0<CR>
