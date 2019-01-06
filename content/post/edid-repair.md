---
title: "EDIDが壊れて認識しないモニターの修理"
date: 2019-01-06T17:19:12+09:00
categories:
- howto
#thumbnailImage: //example.com/image.jpg
---

Acer H243HをDVIで接続すると認識しない。VGA接続とHDMI接続では正常に動作するが、DVIで接続するとsyslogに以下のエラーが出る。

```
Jan  5 23:48:32 haramaki kernel: [97894.621687] amdgpu 0000:01:00.0: DVI-D-1: EDID is invalid:
Jan  5 23:48:32 haramaki kernel: [97894.621694]         [00] BAD  00 ff ff ff ff ff ff 00 ff ff ff ff ff ff ff ff
Jan  5 23:48:32 haramaki kernel: [97894.621696]         [00] BAD  2b 13 01 03 80 35 1d 78 ea 60 85 a6 56 4a 9c 25
Jan  5 23:48:32 haramaki kernel: [97894.621697]         [00] BAD  12 50 54 af cf 00 81 80 71 4f 95 00 95 0f a9 40
Jan  5 23:48:32 haramaki kernel: [97894.621698]         [00] BAD  b3 00 01 01 01 01 1a 36 80 a0 70 38 1f 40 30 20
Jan  5 23:48:32 haramaki kernel: [97894.621699]         [00] BAD  35 00 13 2a 21 00 00 1a 00 00 00 fc 00 48 32 34
Jan  5 23:48:32 haramaki kernel: [97894.621700]         [00] BAD  33 48 0a 20 20 20 20 20 20 20 00 00 00 fd 00 38
Jan  5 23:48:32 haramaki kernel: [97894.621701]         [00] BAD  4c 1f 53 12 00 0a 20 20 20 20 20 20 00 00 00 ff
Jan  5 23:48:32 haramaki kernel: [97894.621702]         [00] BAD  00 4c 45 57 30 43 30 31 34 34 30 31 31 0a 00 33
```

どうやらEDIDが壊れているようだ。

<!--more-->

## LinuxからモニターのEDID ROMを読み書きするには

モニターには [EDID(利用可能な解像度・リフレッシュレート・メーカー名・型番などの情報)](http://read.pudn.com/downloads110/ebook/456020/E-EDID%20Standard.pdf)が格納されたROMが搭載されており、PCとVESA Display Data Channel(I2Cベースのバス)で接続されている。

このROMはLinuxからI2Cデバイスとして認識されているので、I2Cバス操作用のツールでROMを読み書きすることができる。

## DVIのEDID ROMが繋っているバスを探す
rootで`i2cdetect -l` を実行し、バスの一覧を出す

```
# i2cdetect -l
i2c-3	i2c       	AMDGPU DM i2c hw bus 2          	I2C adapter
i2c-1	i2c       	dmdc                            	I2C adapter
i2c-2	i2c       	AMDGPU DM i2c hw bus 1          	I2C adapter
i2c-0	i2c       	AMDGPU DM i2c hw bus 0          	I2C adapter
```

出力からバス0,2,3がGPUのものであることが分かるが、どのポートのものであるかまでは分からないので総当たりでダンプする。
rootで`i2cdump (バス番号) 0x50` を実行するとEDIDをダンプできる。

```plain
# echo Y | i2cdump 0 0x50
No size specified (using byte-data access)
WARNING! This program can confuse your I2C bus, cause data loss and worse!
I will probe file /dev/i2c-0, address 0x50, mode byte
Continue? [Y/n] 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f    0123456789abcdef
00: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
10: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
20: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
30: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
40: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
50: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
60: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
70: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
80: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
90: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
a0: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
b0: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
c0: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
d0: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
e0: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX
f0: XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX XX    XXXXXXXXXXXXXXXX

# echo Y | i2cdump 2 0x50
No size specified (using byte-data access)
WARNING! This program can confuse your I2C bus, cause data loss and worse!
I will probe file /dev/i2c-2, address 0x50, mode byte
Continue? [Y/n] 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f    0123456789abcdef
00: 00 ff ff ff ff ff ff 00 2a 59 00 28 00 00 00 00    ........*Y.(....
10: 19 19 01 03 80 3e 22 78 ea 1e c5 ae 4f 34 b1 26    ?????>"x????O4?&
20: 0e 50 54 af cf 00 d1 00 d1 c0 b3 00 a9 c0 95 00    ?PT??.?.???.???.
30: 81 81 81 00 71 40 04 74 00 30 f2 70 5a 80 30 20    ???.q@?t.0?pZ?0 
40: 36 00 70 fe 31 00 00 1a 56 5e 00 a0 a0 a0 29 50    6.p?1..?V^.???)P
50: 30 20 36 00 70 fe 31 00 00 1a 00 00 00 fd 00 1e    0 6.p?1..?...?.?
60: a0 17 50 19 00 0a 20 20 20 20 20 20 00 00 00 fc    ??P?.?      ...?
70: 00 55 48 44 20 48 44 4d 49 0a 20 20 20 20 01 63    .UHD HDMI?    ?c
80: 02 03 43 f3 58 61 90 05 04 60 65 66 03 02 07 16    ??C?Xa???`ef????
90: 01 1f 12 13 14 20 15 11 06 5d 5e 5f 62 23 09 07    ????? ???]^_b#??
a0: 07 83 01 00 00 e3 05 03 01 e2 0f 71 6e 03 0c 00    ???..??????qn??.
b0: 10 00 38 3d 20 00 80 01 02 03 04 67 d8 5d c4 01    ?.8= .?????g?]??
c0: 78 c0 00 02 3a 80 18 71 38 2d 40 58 2c 45 00 13    x?.?:??q8-@X,E.?
d0: 2b 21 00 00 1a 02 3a 80 d0 72 38 2d 40 30 20 45    +!..??:??r8-@0 E
e0: 00 06 44 21 00 00 1a 01 1d 80 18 71 1c 16 20 58    .?D!..?????q?? X
f0: 2c 25 00 06 44 21 00 00 9e 00 00 00 00 00 00 a0    ,%.?D!..?......?

# echo Y | i2cdump 3 0x50
No size specified (using byte-data access)
WARNING! This program can confuse your I2C bus, cause data loss and worse!
I will probe file /dev/i2c-3, address 0x50, mode byte
Continue? [Y/n] 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f    0123456789abcdef
00:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
10:  2b 13 01 03 80 35 1d 78 ea 60 85 a6 56 4a 9c 25   +....5.x.`..VJ.%
20:  12 50 54 af cf 00 81 80 71 4f 95 00 95 0f a9 40   .PT.....qO.....@
30:  b3 00 01 01 01 01 1a 36 80 a0 70 38 1f 40 30 20   .......6..p8.@0 
40:  35 00 13 2a 21 00 00 1a 00 00 00 fc 00 48 32 34   5..*!........H24
50:  33 48 0a 20 20 20 20 20 20 20 00 00 00 fd 00 38   3H.       .....8
60:  4c 1f 53 12 00 0a 20 20 20 20 20 20 00 00 00 ff   L.S...      ....
70:  00 4c 45 57 30 43 30 31 34 34 30 31 31 0a 00 33   .LEW0C0144011..3
80:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
90:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
a0:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
b0:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
c0:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
d0:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
e0:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
f0:  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff   ................
```

EDIDの内容から、このカードではバス番号2がHDMIのバスで、バス番号3がDVIポートのバスであることがわかる。

## 正常なEDIDを吸い出す
モニタを正常なポート(HDMI)で接続し、正常なEDIDを吸い出す

```plain
# echo Y | i2cdump 2 0x50 > edid-h243h-hdmi.txt
$ vim edid-h243h-hdmi.txt
(マクロで余計なデータを取り除いてhex dumpに変換)
$ xxd -r -p < edid-h243h-hdmi.txt > edid-h243h-hdmi.bin
```

## DVIポートのEDIDの修復
モニタをDVIで接続し、正常なEDIDを書き込む

```plain
$ cat <<'EOS' >edidwrite.py
#!/usr/bin/python3
import sys
import os

with open(sys.argv[2], "rb") as f:
    edid = f.read()

for i, byt in enumerate(edid):
    os.system("echo Y | i2cset %d 0x50 0x%02x 0x%02x b" % (int(sys.argv[1]), i, byt))
    os.system("sleep 0.1")
EOS
$ sudo python3 edidwrite.py 3 edid-h243h-hdmi.bin
```

{{<image classes="fancybox center" src="/assets/edid-repair/edid-ok.png" title="正常に認識されるようになった">}}

## おまけ

EDIDをいじるとこういうこともできる

{{<image classes="fancybox center" src="/assets/edid-repair/flexscan.png" title="💰FlexScan💰 になったH243H">}}
