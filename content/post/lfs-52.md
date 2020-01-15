---
title: "Linux from Scratch - Automation Part 2"
date: 2020-01-14T18:35:15+09:00
categories:
- F²LFS
tags:
- LFS
---

I am writing a sphinx domain and directives for describing package and its build script.

It only parses and stores package information for now. I'm implementing its visual representation now.

<!--more-->

```plain
.. f2lfs:package:: foo 1.3.37
   :license: WTFPL
   :deps: - bar OR baz
          - qux
   :build-deps: - quux
   :sources: - http: http://example.com/src1.tar.xz
               gpgsig: http://example.com/src1.tar.xz.sig
               gpgkey: src1-key.gpg
             - http: http://example.com/src2.patch
               sha256sum: DEADBEEFDEADBEEFDEADBEEFDEADBEEF
             - git: git://example.com/src3.git
               branch: branch_or_tag
             - git: https://example.com/src4.git
               commit: deadbeef
   :bootstrap:

.. f2lfs:buildstep::

   $ foo block 1 command 1

.. f2lfs:buildstep::

   $ foo block 2 command 1
   foo block 2 command 1 expected output
   # foo block 2 command 2 line 1 \
   > foo block 2 command 2 line 2
   foo block 2 command 2 expected output line 1
   foo block 2 command 2 expected output line 2
```

```python
packages = app.env.domains['f2lfs'].data['packages']

foo = packages['foo']
assert foo.name == 'foo'
assert foo.version == '1.3.37'
assert foo.license == 'WTFPL'
assert foo.deps == [
    ('bar', 'baz'),
    'qux'
]
assert foo.build_deps == ['bar']
assert foo.sources == [
    {
        'type': 'http',
        'url': 'http://example.com/src1.tar.xz',
        'gpgsig': 'http://example.com/src1.tar.xz.sig',
        'gpgkey': 'src1-key.gpg'
    },
    {
        'type': 'http',
        'url': 'http://example.com/src2.patch',
        'sha256sum': 'DEADBEEFDEADBEEFDEADBEEFDEADBEEF'
    },
    {
        'type': 'git',
        'url': 'git://example.com/src3.git',
        'branch': 'branch_or_tag'
    },
    {
        'type': 'git',
        'url': 'https://example.com/src4.git',
        'commit': 'deadbeef'
    }
]
assert foo.bootstrap

step1 = foo.build_steps[0]
assert step1.command == 'foo block 1 command 1'
assert step1.expected_output is None

step2 = foo.build_steps[1]
assert step2.command == 'foo block 2 command 1'
assert step2.expected_output == 'foo block 2 command 1 expected output'

step3 = foo.build_steps[2]
assert step3.command == r'''foo block 2 command 2 line 1 \
foo block 2 command 2 line 2'''
assert step3.expected_output == '''foo block 2 command 2 expected output line 1
foo block 2 command 2 expected output line 2'''
```

- https://github.com/ngkz/my-lfs-setup/blob/42db78a5f5da596f3aedb9078380964789dc3a75/_ext/af2lfs.py
- https://github.com/ngkz/my-lfs-setup/blob/42db78a5f5da596f3aedb9078380964789dc3a75/tests/test_af2lfs.py
