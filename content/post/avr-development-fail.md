---
title: "GCCインラインアセンブラとplatformioの嵌りどころ"
date: 2019-09-23T07:30:10+09:00
categories:
- failure
tags:
- GCC
- platformio
#thumbnailImage: //example.com/image.jpg
---

AVRでファンコントローラを作っていたら、いろいろなところで嵌って何時間も無駄にしたので、後学のために何があったかを書いておく。

## GCC拡張インラインアセンブラ構文の嵌りどころ
GCCの拡張インラインアセンブラ構文を使うときはマニュアルをよく読まないとこういう目にあう

### 入力オペランドと出力オペランドは同じレジスタに割り当てられることがある
同じレジスタに割り当てられるとまずい場合は出力オペランドの制約に`&`をつける。付け忘れていたら最適化をかけたときに入力と出力が同じレジスタに割り当てられて嵌った。

NG: `asm volatile("..." : [output] "=r" (...) : [input] "r" (...));` \
OK: `asm volatile("..." : [output] "=&r" (...) : [input] "r" (...));`

### 入力オペランドを割り当てたレジスタが変更されないこと前提で最適化が行われる

<!--more-->

インラインアセンブラ中で入力オペランドを書き換える場合は、同じレジスタを出力オペランドにも割り当てておかないと最適化で破壊されることがある。 (https://stackoverflow.com/questions/48381184/can-i-modify-input-operands-in-gcc-inline-assembly)

インラインアセンブラを書いた関数がループ中にインライン展開されたときに、入力オペランドの初期化処理がループの外に移動されて、2回目以降に処理がおかしくなったことでこれに気づいた。

NG: `asm volatile("(inputを変更するコード)" : : [input] "r" (...));` \
OK:
```
uint8_t dummy;
asm volatile("..." : "=r" (dummy) : [input] "0" (...)); //inputの制約の"0"は0番目の出力オペランド("=r" (dummy))と同じレジスタを割り当てるという意味
```

## platformioの嵌りどころ
### ATtiny系のマイコンで`pio run -t uploadeep`するとプログラムが消去される

platformioのATtiny系マイコンのボード定義にはバグがある。ボード定義中の`"extra_flags": "-e"`が原因で、avrdudeを実行するときに必ず`-e`(Perform a chip erase)オプションが渡されてしまい、EEPROMの書き込みとヒューズの設定を行うときにもチップ全体が消去されてしまう。

バグトラッカーに報告があるがすぐには修正されなさそうな雰囲気なので、下の方法で回避している。

1. プロジェクトのディレクトリにboardsディレクトリを作り、その中に`"extra_flags": "-e"`を削除したボード定義を作る
   ```sh
   (ATtiny85の場合)
   PROJECT $ mkdir boards
   PROJECT $ cat <<'EOS' >hoge.json
   {
     "build": {
       "core": "tiny",
       "extra_flags": "-DARDUINO_AVR_ATTINYX5",
       "f_cpu": "8000000L",
       "mcu": "attiny85",
       "variant": "tinyX5"
     },
     "frameworks": [
       "arduino"
     ],
     "name": "HOGEHOGEHOGE",
     "upload": {
       "maximum_ram_size": 512,
       "maximum_size": 8192,
       "protocol": "usbtiny"
     },
     "url": "https://HOGEHOGE",
     "vendor": "HOGEHOGEHOGE"
   }
   EOS
   ```
1. platformio.iniを変更
   ```
   -[env:attiny85]
   +[env:hoge]
    platform = atmelavr
   -board = attiny85
   +board = hoge
    upload_protocol = buspirate
    upload_flags =
        -P$UPLOAD_PORT
        -b$UPLOAD_SPEED
    upload_port = /dev/ttyUSB0
    upload_speed = 115200
   +extra_scripts = extra_script.py
   ```
2. platformio.iniと同じディレクトリにextra_script.pyを作成し、プログラムの書き込み時だけChip Eraseオプションを渡すよう設定
   ```
   Import('env')
   env.Replace(UPLOADCMD='$UPLOADER $UPLOADERFLAGS -e -U flash:w:$SOURCES:i')
   ```
