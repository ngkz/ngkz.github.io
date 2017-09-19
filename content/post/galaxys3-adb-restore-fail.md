---
date: '2013-09-12T13:29:56+09:00'
title: Galaxy S3(SC-06D)がadbバックアップを戻した後再起動を繰り返すようになったときの対処方法
categories:
 - howto
tags:
#thumbnailImage: //example.com/image.jpg
---

## リカバリモードに入ってファクトリーリセットする

galaxy S3 リカバリモードの入り方:

<iframe width="560" height="315" src="https://www.youtube.com/embed/QVa3yfxP0Zs" frameborder="0" allowfullscreen></iframe>

## バックアップを展開

[Android backup extractor](https://github.com/nelenkov/android-backup-extractor)
でバックアップを展開\

    android-backup-extractor $ ant build jar
    android-backup-extractor $ java -jar abe.jar unpack galaxys3.bak
    galaxys3.tar

## com.sec.android.gallery3dをバックアップから削除

tarアーカイブ内のcom.sec.android.gallery3d フォルダを削除する。

### バックアップを作成

    android-backup-extractor $ java -jar abe.jar pack galaxys3.tar galaxys3.bak

### バックアップを端末に戻す

あとは普通にadb restore

    android-backup-extractor $ adb restore galaxys3.bak
