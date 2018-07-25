---
title: "依存しているパッケージ(crate)の中身を実行せずに調べる方法 (Rust)"
date: 2018-07-25T22:24:30+09:00
categories:
- howto
tags:
- rust
---

`cargo fetch`[^1] でパッケージを取得すると、`~/.cargo/registry/src/github.com-1ecc6299db9ec823/(パッケージ名)-(バージョン)`
にパッケージのソースコードが展開される。 

Cargo.lockにすべての依存クレートの名前とバージョンが記録されているので、これを見てコードに問題がないか調べることができる。

[^1]: cargo buildはビルドスクリプトを実行してしまうのでダメ
