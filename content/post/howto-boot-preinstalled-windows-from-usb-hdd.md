---
title: "内蔵HDDに入ってるWindows 10をUSB HDDから起動できるようにする方法"
date: 2019-06-02T13:14:41+09:00
categories:
- howto
tags:
- windows
#thumbnailImage: //example.com/image.jpg
---

Windowsが入った内蔵HDDをUSB経由で接続し、そこから起動しようとするとSTOPエラーで失敗するが、レジストリの`HKEY_LOCAL_MACHINE\SYSTEM`の`HardwareConfig`キー中の`BootDriverFlags`を`0x14`に設定すると、USBストレージから起動できるようになる。

ただし、このHDDを使ってWindowsを起動すると、接続したマシンのUEFIのブートエントリにWindowsが登録されてしまう。

<!--more-->
