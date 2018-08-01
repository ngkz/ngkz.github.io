---
title: "テストをrootとして動かす方法 (Rust)"
date: 2018-08-01T17:37:33+09:00
categories:
- howto
tags:
- rust
---

https://github.com/rust-lang/cargo/issues/1924 によると、`cargo test --no-run --message-format=json | jq -r "select(.profile.test == true) | .filenames[]"` でテストバイナリの一覧が取得できる。これをsudoで実行するスクリプトを作ればOK

<!--more-->

```sh
#!/bin/sh
#Public Domain
cargo test --no-run --message-format=json | jq -r "select(.profile.test == true) | .filenames[]" | while read -r bin; do
    sudo -- "$bin"
done
```
