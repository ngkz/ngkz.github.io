---
date: '2012-12-24T05:03:22+09:00'
title: SECCON CTF 横浜大会 (SECCON 2012 予選) writeup
categories:
 - CTF
 - writeup
tags: 
 - SECCON
#thumbnailImage: //example.com/image.jpg
---

[SECCON CTF 横浜大会](http://www.seccon.jp/)にチーム 0x0として参加しました。\
チームメンバーは nash氏、wasao氏、waidotto氏、nullmineral氏と私です。

## 成績

score: たぶん8120

{{<image classes="fancybox" src="/assets/seccon-2012-yokohama-quals-writeup/514d338eaff15827c0309966508eddbb.png" title="終了数分前の問題一覧">}}

\

{{<image classes="fancybox" src="/assets/seccon-2012-yokohama-quals-writeup/seccon-yokohama.jpg" title="賞状 第三位" thumbnail-width="295px" thumbnail-height="400px">}}

\
✌('ω')

<!--more-->

## 解けた問題の解説

### パスワードを答えよ (Binary)

問題ページにあるzipファイルを解凍するとtlscb-iwa.exeが出てくる。

    $ file tlscb-iwa.exe
    tlscb-iwa.exe: PE32 executable (console) Intel 80386, for MS Windows

\

OllyDbgで実行すると、[エントリポイントに到達する前に TLS
Callbacksでコードを実行している](http://www.netagent-blog.jp/archives/51735398.html)ことが分かります。

\
IDA に食わせると TlsCallbacksという怪しい配列があることが分かります。

この配列の関数が スレッドの起動時と終了時に呼ばれます。\

    .rdata:0040610C TlsCallbacks    dd offset TlsCallback_0_copy_commandline
    .rdata:0040610C                                         ; DATA XREF: .rdata:TlsCallbacks_ptr.o
    .rdata:00406110                 dd offset TlsCallback_3_encode
    .rdata:00406114                 dd offset TlsCallback_4_xor
    .rdata:00406118                 dd offset TlsCallback_3_encode
    .rdata:0040611C                 dd offset TlsCallback_4_xor
    .rdata:00406120                 dd offset TlsCallback_5_check
    .rdata:00406124                 dd 0

\

これらの関数を読み進めていくと、

-   TlsCallback\_0では コマンドラインを取得してバッファにコピー
-   TlsCallback\_3では 256バイトのバイト列(以下encval)を使って
    バッファを置換
-   TlsCallback\_4では 0xab, 0xcd, 0xefでバッファをXOR
-   TlsCallback\_5では TlsCallback\_3
    とTlsCallback\_4をさらに実行した後、バイト列(以下checkval)とバッファが一致していたら正解とする

ことが分かる。

つまり、checkvalから入力を逆算すると答えが分かる。

    checkval = [0xd4, 0x46, 0xf0, 0x4f, 0xb6, 3, 6, 0xaa, 0xfe, 0x31, 0xae, 0x8a]
    encval = open("tlscb-iwa.exe").read()[0x6a00:0x6a00 + 256]
    xorval = [0xab, 0xcd, 0xef]

    def callback_reverse4():
        for i in range(len(checkval)):
            checkval[i] ^= xorval[i % 3]

    def callback_reverse3():
        #answer[i] = encval[answer[i]]
        for i in range(len(checkval)):
            checkval[i] = encval.index(chr(checkval[i]))

    callback_reverse4()
    callback_reverse3()
    callback_reverse4()
    callback_reverse3()
    callback_reverse4()
    callback_reverse3()

    print "".join([chr(c) for c in checkval])

答えは「7LSCaLL13aCK」\

### Find the key. (Network)

USB通信のキャプチャからkeyを取り出す問題。

\

    $ file 7d157d658655465f35a6e06fc95b1446 
    7d157d658655465f35a6e06fc95b1446: tcpdump capture file (little-endian) - version 2.4, capture length 65535)

\

{{<image classes="fancybox" src="/assets/seccon-2012-yokohama-quals-writeup/87f4d2e05067c8c23a2419bf46322187.png" title="ブートセクタのRead要求" thumbnail-width="400px" thumbnail-height="206px">}}

{{<image classes="fancybox" src="/assets/seccon-2012-yokohama-quals-writeup/c4d4b2e05f2f9403e258c05cae650b05.png" title="Read 結果" thumbnail-width="400px" thumbnail-height="390px">}}

\

\

Wiresharkでパケットを眺めてみると、
USBメモリとの通信をキャプチャしたものであることと、 

SCSI Read パケットで LBAとセクタ数を指定して read要求をし、 直後のSCSI
Data In パケットでその結果を受け取っていることが分かる。

Mass
Storageのプロトコルを調べるのが面倒なので、かなり適当な方法でパケットをパースしてディスクイメージを組立てた。

    #-*- coding: utf-8 -*-
    from struct import *
    from scapy.all import *
    pcap = rdpcap("7d157d658655465f35a6e06fc95b1446")
    disk = open("disk.img", "w")
    lba = 0
    skip = False

    for pkt in pcap:
        signature = pkt.load[0x40:0x40 + 4]
        
        urb_type = pkt.load[8]
        transfer_type = ord(pkt.load[9])
        endpoint = ord(pkt.load[0x0a])
        device = ord(pkt.load[0x0b])
        bus_id = unpack('<H', pkt.load[0x0c:0x0c + 2])[0]

        #SCSI Read Inパケットのみを取り出す。汚い
        if urb_type == 'C' and transfer_type == 3 and endpoint == 0x81 and device == 4 and bus_id == 1:
            if signature == 'USBS':
                continue
            if skip:
                #read 以外のSCSIコマンドの結果
                continue
            #read の結果
            data = pkt.load[0x40:]
            disk.seek(lba * 512)
            disk.write(data)
        
        #SCSI Readコマンドのみを取り出す。汚い
        if urb_type == 'S' and transfer_type == 3 and endpoint == 0x02 and device == 4 and bus_id == 1:
            if signature != "USBC":
                continue

            scsi_type = ord(pkt.load[0x4f])
            if scsi_type != 0x28:
                #other request
                skip = True
                continue

            #scsi read コマンド
            lba = unpack('>L', pkt.load[0x51:0x51 + 4])[0]
            skip = False

\

ディスクイメージをバイナリエディタで見ると最後の方に答えらしき文字列があることが分かる。

答えは「Haiyore! Yuzuharatan!」でした。

\

ちなみに、ディスクイメージの中身は↓こんな感じでした。

$ sudo mount -t vfat -o
loop,offset=4194304,rw,iocharset=utf8,codepage=932 disk.img mnt

mnt$ ls -al

    合計 1892
    drwxr-xr-x 2 root        root          32768  1月  1  1970 .
    drwxrwxr-x 3 superbacker superbacker    4096 12月 24 03:39 ..
    -rwxr-xr-x 1 root        root        1811122 10月  6 16:52 dame.bmp
    -rwxr-xr-x 1 root        root             21 10月  6 16:41 key.txt
    -rwxr-xr-x 1 root        root           4632  7月 16 01:56 やる夫.png

mnt$ cat key.txt\
Haiyore! Yuzuharatan!\

mnt$ xdg-open dame.bmp\
{{<image classes="fancybox" src="/assets/seccon-2012-yokohama-quals-writeup/dame.jpg" thumbnail-width="400px" thumbnail-height="163px" title="dame.bmp">}}

mnt$ xdg-open やる夫.png\
{{<image classes="fancybox" src="/assets/seccon-2012-yokohama-quals-writeup/%E3%82%84%E3%82%8B%E5%A4%AB.png" title="やる夫.png">}}

\

#### 別解

{{<image classes="fancybox" src="/assets/seccon-2012-yokohama-quals-writeup/e2d9182e72d7cd282da395b00e3b2bfd.png" title="Haiyore! Yuzuharatan!">}}

\

strings→目grepすると、最後のほうに答えらしきものがあることが分かる。

key.txtはサイズが小さいので、複数のセクタ もしくは
パケットにまたがることはない。そのため、ディスクイメージを組み立てる必要はなかった。

### 動かした気になろう (Binary)

問題文: 忘れた。
"ファイルが出力する最後の行を答えよ"という内容だったと思う。\
\

    $ file mondai 
    mondai: ELF 32-bit MSB executable, PowerPC or cisco 4500, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.18, BuildID[sha1]=0x4d9acce3c74d7d3431fcf3a7d9651902e3b3aa09, with unknown capability 0x41000000 = 0x13676e75, with unknown capability 0x10000 = 0xb0401, not stripped

    # chroot ~/multistrap-debian-squeeze-powerpc
    # (path)/mondai
    Hello Fukuoka
    Hello Kyutech

\

QEMUとPowerPC環境を使い、ファイルを実行すると文字列が出る。

「Hello Kyutech」が答えでした。

## 反省点

Find the
key.をstringsした時答えに気づかなかったため、時間がかかってしまった。

もっと時間があればAccending Orderを解けたと思う。

\

