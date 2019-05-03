---
title: "Ubuntu 19.04 タッチパッドの誤タップ対策"
date: 2019-05-03T13:57:33+09:00
categories:
- howto
---

Ubuntu 19.04へアップグレードしたら、手のひら検知と入力中にタッチパッドを無効にする機能がオフになり、入力中にカーソルが勝手にあちこちに飛ぶようになってしまった。

以下の手順で設定して、Xサーバーを再起動(再ログイン)すると再有効化できる。

```sh
sudo -e /etc/X11/xorg.conf.d/90-libinput.conf
```

```sh
Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Tapping" "True"
    Option "DisableWhileTyping" "True"
EndSection
```

<!--more-->
