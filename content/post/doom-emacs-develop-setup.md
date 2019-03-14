---
title: "DOOM Emacsの導入方法 & 設定例"
date: 2018-10-20T10:50:27+09:00
categories:
  - howto
tags:
  - Emacs
---

## 動機

1. 収録ソフトウェアがかなり古くなってきている Ubuntu 14.04 から Linux From Scratch に移行しよう
2. この機会に neovim に移行して、vim の設定を一から書き直そう
3. エディタ部分は大量に設定を書かないと使い勝手が悪いし、プラグインの導入と設定も面倒だ
4. vim 風のキーバインディングで、よりすぐれた操作性を持つ [Kakoune というエディタがあるらしい](http://kakoune.org/why-kakoune/why-kakoune.html)。[試してみよう](https://github.com/ngkz/kakrc)
5. たしかに、設計・デフォルト設定や操作性は vim より良いが、プラグインが足りない
6. じゃあプラグインが充実している Emacs だ。素の Emacs は設定が大変らしいから、[spacemacs](http://spacemacs.org/)も試してみよう。
7. 起動が遅い
8. Spacemacs より軽い DOOM Emacs というのがあるらしい。これにしよう

<!--more-->

## インストール

現在、[master ブランチは動作しない](https://github.com/hlissner/doom-emacs/issues/739) 状態なので、[develop ブランチ](https://github.com/hlissner/doom-emacs/tree/develop)をインストールする。

```sh
~$ rm -rf ~/.emacs.d
~$ git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
~$ cd .emacs.d
~$ git checkout develop
#設定を~/.doom.dに置く場合
~/.emacs.d$ bin/doom quickstart
#設定を~/.config/doomに置く場合
~/.emacs.d$ bin/doom -p ~/.config/doom quickstart
```

master ブランチの README と Wiki の情報は古くなっているので、develop ブランチの README と DOOM Emacs のコードを参考に設定する。

### DOOM Emacs の一部をバイトコンパイルして起動を高速化

私の環境ではほとんど効果がなかった。

```sh
~/.emacs.d $ bin/doom compile :core
```

## 使い方

- キーバインドは各モジュールの`config.el`や`+binding.el`で定義されている。
  - 基本的なキーバインドは[config/default モジュールで定義されている](https://github.com/hlissner/doom-emacs/blob/develop/modules/config/default/%2Bbindings.el)
- Space, g, C-x などのプレフィックスキーを押した後、2 秒くらい何もしないでいると、キーの一覧と短い説明が自動で出てくる。
- `SPC :`または`M-x`で emacs コマンドの検索と実行ができる。キーバインドも表示される(ただし複数のキーにマップされている場合 1 つだけしか表示されない)。  
  キーバインドを覚えていない機能を使うときに便利
- `SPC h` で現在使用中のモード・選択したシンボル・指定した関数などのヘルプが出せる。
- `doom update` でプラグインをアップデート
- `doom upgrade` で DOOM Emacs をアップデート
- `doom doctor` を実行すると、DOOM Emacs が正しくインストールされているか、依存プログラムがインストールされているかをチェックしてくれる

## カスタマイズ方法

1.  `.doom.d` ディレクトリ内の以下のファイルを編集する。

    | ファイル名  | 役割                                                                                                    |
    | ----------- | ------------------------------------------------------------------------------------------------------- |
    | init.el     | DOOM のコアが初期化された後、モジュールがロードされる前に実行される。ここで使用するモジュールを指定する |
    | packages.el | ここに追加でインストールするパッケージを書く                                                            |
    | config.el   | 依存パッケージのロード後に実行される。ここにキーバインドやパッケージの設定を書く                        |

2.  `init.el`か`packages.el`を編集した場合、`doom refresh`を叩き、プラグインのインストール、不要なプラグインの削除と autoload ファイルの更新 を行う。

    ```sh
    ~/.emacs.d$ bin/doom refresh
    ```

3.  `SPC q r` で再起動

### 機能を有効にする

デフォルト状態では基本的な機能以外は無効になっている。

`init.el`を開き、コメントアウトを外し、`doom refresh`すると使えるようになる。モジュールによっては `(format +onsave)`にように、モジュール名を括弧で囲み、`+`でオプション名を付けるとオプション機能を有効にできる。

機能の使い方、必要な外部プログラム、使えるオプションはモジュールの README やソースコードで調べられる。

### キーバインドの追加

#### キーに関数をマップ

```elisp
;(map! :<モード> "<キー>" <キーが押されたとき実行する関数>)
;複数のキーを同時にマップできる
(map! :nvi "C-h" #'evil-window-left ;#'<関数名>
      :nvi "C-j" #'evil-window-down)
```

モードには以下の値が使える

| 文字 | 対応するモード |
| ---- | -------------- |
| n    | ノーマル       |
| v    | ビジュアル     |
| i    | インサート     |
| e    | emacs          |
| o    | オペレータ     |
| m    | モーション     |
| r    | replace        |
| g    | global         |

#### vim の:map と同等のことをする

```elisp
(map! :n "C-;" (kbd "itest"))
```

## カスタマイズ例

https://github.com/ngkz/doom.d

### フォントの変更

https://github.com/hlissner/doom-emacs/tree/develop/modules/ui/doom#changing-fonts

**config.el** に以下のコードを追加

```elisp
(setq doom-font (font-spec :family "NasuM" :size 14)
      doom-variable-pitch-font (font-spec :family "Nasu")
      doom-unicode-font (font-spec :family "NasuM")
      doom-big-font (font-spec :family "NasuM" :size 22))
```

### コメントを見やすくする

`<テーマ名>-brighter-comments` を真にするとコメントの文字色と背景色が明るくなる。背景が白っぽいと見栄えが悪いので、`<テーマ名>-comment-bg`で戻す。テーマによっては使えないので注意 ([テーマのソースコード](https://github.com/hlissner/emacs-doom-themes) 参照)

**config.el**

```elisp
(setq doom-one-brighter-comments t)
;; don't lighten the background of the comment
(setq doom-one-comment-bg nil)
```

### 保存時に自動フォーマット

**init.el**

```elisp
       :editor
       (format +onsave)  ; automated prettiness
```

### デフォルトのコメント開始文字を#に設定

**config.el**

```elisp
(setq-default comment-start "# ")
```

### 行末の空白文字をハイライト

terminal では無効にする

**config.el**

```elisp
;; Highlight trailing whitespace
(setq-default show-trailing-whitespace t)

;; Disable trailing whitespace highlighting when in some modes
;; https://qiita.com/tadsan/items/df73c711f921708facdc
(defun my/disable-trailing-mode-hook ()
  "Disable show tail whitespace."
  (setq show-trailing-whitespace nil))

(defvar my/disable-trailing-modes
  '(comint-mode
    eshell-mode
    eww-mode
    term-mode
    twittering-mode))

(mapc
 (lambda (mode)
   (add-hook (intern (concat (symbol-name mode) "-hook"))
             'my/disable-trailing-mode-hook))
 my/disable-trailing-modes)
```

### タブ・全角スペース・ハードスペースを記号に変換して表示

`␣`は曖昧幅なので、`␣`が半角になるフォントを使用している場合は、`□`などの全角文字に変更しないと表示がおかしくなる。

**config.el**

```elisp
; highlight tab, hard space, and full-width space
(require 'whitespace)
(setq whitespace-style '(
    face
    tabs
    spaces
    space-mark
    tab-mark
))
(setq whitespace-display-mappings '(
    (space-mark ?\u3000 [?␣])       ;full-width space AMBIGUOUS WIDTH!
    (space-mark ?\u00A0 [?\uFF65])   ;hard space
    (tab-mark   ?\t     [?» ?\t])    ;tab
))
(setq whitespace-space-regexp "\\([\u3000]+\\)") ; highlight only full-width space
(global-whitespace-mode t)
```

### Markdown モードの auto-fill を切る

Markdown モードの Auto-Fill (行が長くなったら自動で改行を入れる機能) が鬱陶しいのでオフにする。

**config.el**

```elisp
;turn off auto-fill
(add-hook 'markdown-mode-hook (lambda () (auto-fill-mode -1)))
```

### 画面端で行を折り返す (soft wrap)

**config.el**

```elisp
;soft wrapping
(global-visual-line-mode t)
```

### ウィンドウをリサイズしやすくする

[Re: 分割したウィンドウの大きさをインタラクティヴに変更する](http://d.hatena.ne.jp/khiker/20100119/window_resize) の改変

`Ctrl-W SPC` を押すと、HJKL でウィンドウのサイズが変更できるようになる。(HJKL で大まかに調整、Shift+HJKL で微調整)。他のキーを押すとノーマルモードに戻る。

**config.el**

```elisp
;resize window quickly
;http://d.hatena.ne.jp/khiker/20100119/window_resize
(defun my-window-resizer ()
  "Control window size and position."
  (interactive)
  (let ((window-obj (selected-window))
        (current-width (window-width))
        (current-height (window-height))
        (dx (if (= (nth 0 (window-edges)) 0) 1
              -1))
        (dy (if (= (nth 1 (window-edges)) 0) 1
              -1))
        action c)
    (catch 'end-flag
      (while t
        (setq action
              (read-key-sequence-vector (format "size[%dx%d]"
                                                (window-width)
                                                (window-height))))
        (setq c (aref action 0))
        (cond ((= c ?l)
               (enlarge-window-horizontally (* dx 5)))
              ((= c ?L)
               (enlarge-window-horizontally dx))
              ((= c ?h)
               (shrink-window-horizontally (* dx 5)))
              ((= c ?H)
               (shrink-window-horizontally dx))
              ((= c ?j)
               (enlarge-window (* dy 2)))
              ((= c ?J)
               (enlarge-window dy))
              ((= c ?k)
               (shrink-window (* dy 2)))
              ((= c ?K)
               (shrink-window dy))
              ;; otherwise
              (t
               (let ((last-command-char (aref action 0))
                     (command (key-binding action)))
                 (when command
                   (call-interactively command)))
               (message "Quit")
               (throw 'end-flag t)))))))

(map! :map evil-window-map
      "SPC" #'my-window-resizer) ; CTRL-w SPC or SPC w SPC
```

### Ctrl-hjkl でウィンドウを切り替え

**config.el**

```elisp
;; switch between window with C-hjkl
(map! :nvi "C-h" #'evil-window-left
      :nvi "C-j" #'evil-window-down
      :nvi "C-k" #'evil-window-up
      :nvi "C-l" #'evil-window-right)
```

### Ctrl-Shift-hjkl でウィンドウを移動

**config.el**

```elisp
;; move the window with C-S-hjkl
(map! :nvi "C-S-h" #'+evil/window-move-left
      :nvi "C-S-j" #'+evil/window-move-down
      :nvi "C-S-k" #'+evil/window-move-up
      :nvi "C-S-l" #'+evil/window-move-right)
```

### 画面の上下左右に余裕を持たせてスクロール (scrolloff, sidescrolloff)

**config.el**

```elisp
;; minimal number of screen lines to keep above and below the cursor
(setq-default scroll-margin 3)
;; minimal number of screen columns to keep to the left and to the right of the cursor
(setq-default hscroll-margin 5)
```

### x で文字を削除するとき yank しない

**config.el**

```elisp
;; delete character without yanking
(map! :n "x" #'delete-char)
```

### テキストファイルを編集するとき 角括弧の内側に自動でスペースを挿入・削除しない

角括弧でチェックボックスを作るときに鬱陶しいので

**config.el**

```elisp
;; Don't do square-bracket space-expansion where it doesn't make sense to
(after! smartparens-text
  (sp-local-pair 'text-mode
                 "[" nil :post-handlers '(:rem ("| " "SPC"))))
```

### インサートモードで C-d が使えるようにする

**config.el**

```elisp
;; Make C-d usable in insert mode
(map! :i "C-d" #'delete-char)
```

### org-mode の TODO アイテムの完了時刻を記録する

**config.el**

```elisp
;; log when a certain todo item was finished
(setq org-log-done t)
```

### org-mode の日付の曜日を英語にする

**config.el**

```elisp
; Make sure that the weekdays in the time stamps of your Org mode files and in the agenda appear in English.
(setq system-time-locale "C")
```

### 端末を有効化

`SPC o t`, `SPC o T` で端末を開けるようにする

**init.el**

```elisp
       term              ; terminals in Emacs
```

## ansible サポートを有効化

**init.el**

```elisp
       ansible
```

## docker サポートを有効化

Docker の操作と Dockerfile の編集のサポートを有効にする

**init.el**

```elisp
       docker
```

## magit を有効化

便利な git のフロントエンドを使えるようにする

**init.el**

```elisp
       magit             ; a git porcelain for Emacs
```

## その他の言語のサポートを有効化

:lang セクションの使うやつをアンコメントしたりオプションをつけたりする

**init.el**

```elisp
       :lang
       assembly          ; assembly for fun or debugging
       (cc +irony +rtags); C/C++/Obj-C madness
       ;;clojure           ; java with a lisp
       ;;common-lisp       ; if you've seen one lisp, you've seen them all
       ;;coq               ; proofs-as-programs
       ;;crystal           ; ruby at the speed of c
       ;;csharp            ; unity, .NET, and mono shenanigans
       data              ; config/data formats
       ;;erlang            ; an elegant language for a more civilized age
       ;;elixir            ; erlang done right
       ;;elm               ; care for a cup of TEA?
       emacs-lisp        ; drown in parentheses
       ;;ess               ; emacs speaks statistics
       go                ; the hipster dialect
       ;;(haskell +intero) ; a language that's lazier than I am
       ;;hy                ; readability of scheme w/ speed of python
       ;;idris             ;
       ;;(java +meghanada) ; the poster child for carpal tunnel syndrome
       javascript        ; all(hope(abandon(ye(who(enter(here))))))
       ;;julia             ; a better, faster MATLAB
       ;;latex             ; writing papers in Emacs has never been so fun
       ;;ledger            ; an accounting system in Emacs
       ;;lua               ; one-based indices? one-based indices
       markdown          ; writing docs for people to ignore
       ;;nim               ; python + lisp at the speed of c
       ;;nix               ; I hereby declare "nix geht mehr!"
       ;;ocaml             ; an objective camel
       (org              ; organize your plain life in plain text
        +attach          ; custom attachment system
        +babel           ; running code in org
        +capture         ; org-capture in and outside of Emacs
        +export          ; Exporting org to whatever you want
        +present)        ; Emacs for presentations
       ;;perl              ; write code no one else can comprehend
       ;;php               ; perl's insecure younger brother
       ;;plantuml          ; diagrams for confusing people more
       ;;purescript        ; javascript, but functional
       (python            ; beautiful is better than ugly
        +pyenv
        +pyvenv)
       ;;qt                ; the 'cutest' gui framework ever
       ;;racket            ; a DSL for DSLs
       ;;rest              ; Emacs as a REST client
       ruby              ; 1.step do {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
       rust              ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
       ;;scala             ; java, but good
       (sh +fish)        ; she sells (ba|z|fi)sh shells on the C xor
       ;;solidity          ; do you need a blockchain? No.
       ;;swift             ; who asked for emoji variables?
       web               ; the tubes
       ;;vala              ; GObjective-C
```

## smartparensを無効にする
```elisp
;; smartparens is more annoying than useful
(after! smartparens (smartparens-global-mode -1))
```
