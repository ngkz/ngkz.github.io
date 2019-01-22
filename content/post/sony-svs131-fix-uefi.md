---
title: "BIOSパスワードをバックドアでリセットしたら設定画面が壊れたから直した"
date: 2017-12-20T01:50:27+09:00
categories:
- howto
tags:
- BIOS Hacking
draft: true
thumbnailImage: /assets/sony-svs131-fix-uefi/2017-12-18 18.42.41.jpg
---

[多くのメーカーのノートPCのBIOSパスワードにはバックドアがある](https://dogber1.blogspot.jp/2009/05/table-of-reverse-engineered-bios.html) ことを知ったので、自分のマシン (SONY VAIO SVS13129CJS)を試しに開錠してみたら、ファームウェア設定のほとんどがグレーアウトして変更できず、デフォルト設定にも戻せなくなってしまった。

{{<image classes="fancybox fig-50" src="/assets/sony-svs131-fix-uefi/2017-12-19 15.09.08.jpg" group="grayedout" title="日付・時刻以外の全ての設定がグレーアウト">}}
{{<image classes="fancybox fig-50 clear" src="/assets/sony-svs131-fix-uefi/2017-12-19 15.06.53.jpg" group="grayedout" title="ファクトリーリセット不可能">}}

いろいろ試しているうちに元に戻せたので、解決までの経緯をメモしておく。

## 1. CMOSクリア -> 失敗
{{<image classes="fancybox center" src="/assets/sony-svs131-fix-uefi/2017-12-18 18.42.41.jpg" thumbnail-width="33%" title="数時間かけて分解と組み立てをしたのに何の収穫もなし">}}

まずCMOSクリアを試してみた。

マザーボードの裏側にあるバックアップ電池を外して30分放電してみたが、日付と時刻しかリセットされなかった。

分解の手順は、[VAIO Sシリーズ（SVS13A2AJ）を分解する手順を写真つきで ｜ 秋葉ネオ](http://akiba-neo.com/sony/vaio/273/)と [サービスマニュアル](https://www.manualslib.com/manual/531863/Sony-Vaio-Svs131-Series.html) が参考になる。


## 2. 設定情報をOSから変更 -> 失敗
何か別の方法がないか調べてみたら、InsydeH2O BIOSの設定は UEFI変数 Setupに保存されており、以下の手順で、OS上からBIOSの設定が変更できることが分かった。

1. [UEFITool](https://github.com/LongSoft/UEFITool) でBIOS ROMから、Subtype = DXE DriverでText = SetupUtilityの項目 (自分の環境ではFE3542FE-C1D3-4EF8-657C-8048606FF670) を右クリックし、データをExtract as is で取り出す。
2. [Universal IFR Extractor](https://github.com/donovan6000/Universal-IFR-Extractor)に 取り出したデータを食わせ、設定項目とその内容がSetup変数のどこに格納されるかが記録されている Internal Forms Representation というデータをテキスト形式に変換し取り出す。
3.

    [ ] efivars路線に再挑戦
        ResetFactoryDefaultをchattr -iして1を書いてみる -> だめ
        PowerOnPasswordをいじってみる->だめ

抽出しても場所がわからん

(4.で実際はIFRの解析がうまくいっていなかっただけだったのが分かった)

## 3. BIOS書き込みツールで設定をリセット -> 失敗
(DOS上でBIOS書き込みツールを動かす -> 失敗)
次に、BIOS ROMを書き込む際に 設定がリセットされることを

レガシーブートを有効にすることができないので、Windows 7のインストールディスクから

Windows 7 のインストールディスクをブータブルUSB化して起動 -> 失敗
Windows PE上でBIOS書き込みツールを動かす -> 失敗

また、マシンによっては、BIOS ROMを格納したUSBメモリを接続して Win + BやFn + Escを押しながら起動することで、BIOSを書き込むことができるので、試してみたが、何も起きなかった。 USBメモリを読みにすら行っていないので、このマシンでは使えないようだ。

    [ ] Windowsのインストールディスクでflash
        [ ] FAT32でフォーマットしたUSBメモリにインストールディスクの中身をコピー
        [ ] c:\windows\boot\efi\bootmgfw.efiをUSBメモリの/efi/boot/bootx64.efiへコピー
        [ ] 起動画面から先に進まない
    [ ] Windows PE路線
        [ ] https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-create-usb-bootable-drive
        [ ] https://713itsupport.com/blog/2012/01/how-to-remove-a-bios-password-from-an-insyde-h2o-efi-bios-updated/の手順でリセット ForceFlashのPasswordを1に
        [ ] アーキテクチャが違うからflasherが動かなくてだめ
    [ ] efivarsでCDドライブを有効にする 0x218 + 4 を1に

## 4. 2 に再挑戦 -> 成功

2.で取ったIFRを見直してみたところ、IFRが正常に取れていないことが分かった。UEFIのコードを仕様してパーサーを書き直したfork ([LongSoft/Universal-IFR-Extractor](https://github.com/LongSoft/Universal-IFR-Extractor)) で
/sys/firmware/efi/efivars/ 中のファイルを読み書きすることで、UEFI変数
他にやりたいことがたくさんあるので、深くは追求しない。

    [ ] LongSoftのforkで再抽出したらSecurityタブまで取れた
    [ ] 0x84, 0x85を0に設定
    [ ] efivarsの保護された値はchattr -i しないと書き換えられない https://www.spinics.net/lists/newbies/msg59024.html

## 

<!--more-->
