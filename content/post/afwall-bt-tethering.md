---
title: "AFWall+ を有効にするとBluetoothテザリングで通信できなくなるのをなおす"
date: 2019-01-13T20:20:09+09:00
categories:
- howto
#thumbnailImage: //example.com/image.jpg
---

AFWall+を有効にしていると、Bluetoothテザリングで接続したクライアントが通信できなくなるのをなんとかする。

## 原因
ログと検索エンジンで調べたところ、AFWall+がBluetoothテザリングに対応していないため、クライアントにDHCPとDNS Proxyを提供しているdnsmasqからのDNS通信がブロックされてしまっていることが分かった。

## 解決策1: DNSを手動設定する
<!--more-->

AFWall+はFORWARDチェインを素通し状態にしているので、DNSを手動設定してdnsmasqを通さずに名前解決すれば通信できるようになる。

クライアント機器がDNSを手動設定できない仕様なので、今回この方法は使えない。

## 解決策2: カスタムスクリプトを使う
AFWall+には、ファイアウォールの起動時と停止時にスクリプトを実行する機能がある。これを使ってiptablesにルールを追加し、dnsmasqからのDNS通信を許可すれば、クライアントが名前解決できるようになる。

iptablesは、対応カーネルならばownerモジュールの`--pid-owner`, `--sid-owner`, `--cmd-owner` で特定プロセスからの通信のみを許可することができるようだが、Androidのiptablesバイナリはこれらのオプションに対応していない。代わりに、AFWall+がテザリング時に設定するルールと同じように、`--uid-owner`でdnsmasqの動作ユーザー(UID 9999)からのDNS通信を許可する。

AFWall+がわざわざテザリング時に限定している通信を常に許可することになるのでセキュリティは落ちることになるが、
ざっと見たかぎり、UID 9999は特定のシステムプロセスしか使用していないようなので問題はないだろう。

心配な場合は、Bluetoothテザリングの開始・終了を検知してiptablesのルールを追加・削除するアプリを作れば解決できる。

以下のコマンドで、`/data/local/afwall_bluetooth.sh` にカスタムスクリプトを作成する。
```plain
host $ adb shell
device $ su
device # cat <<'EOS' >/data/local/afwall_bluetooth.sh
#!/system/bin/sh
IPTABLES=/system/bin/iptables

# 追加済みのルールは自動で削除されない上 、カスタムスクリプトはルールの適用中に複数回実行されるので、最初にこれから追加するルールを削除しておかないとルールがどんどん増殖していく。
$IPTABLES -D OUTPUT -m owner --uid-owner 9999 -p udp --dport 53 -j ACCEPT
# UID 9999から UDP/53への通信を許可
$IPTABLES -I OUTPUT -m owner --uid-owner 9999 -p udp --dport 53 -j ACCEPT
EOS
device # chmod 700 /data/local/afwall_bluetooth.sh #root権限で実行されるので、絶対に他のユーザーが書き込めるパーミッションにしないこと
#ファイアウォール停止時に残っていても実害はないので、停止スクリプトは作成しない。
```

AFWall+のメニューで `カスタムスクリプト設定` を開き、「**下記にカスタムスクリプトを記入してください。**」 の入力欄を `/data/local/afwall_bluetooth.sh`に設定する。

これでBluetoothテザリングで通信できるようになる。
