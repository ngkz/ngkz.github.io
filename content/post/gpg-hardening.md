---
title: "GnuPG Hardening"
date: 2020-01-12T01:31:22+09:00
categories:
- howto
tags:
- GPG
---

SHA-1 is [completely](https://sha-mbles.github.io/) [dead](https://shattered.io/). And I noticed legacy GPG signed my PGP key with SHA-1.

## Improving GPG Configuration
```
$ vim ~/.gnupg/gpg.conf
# use SHA-512 when signing a key
cert-digest-algo SHA512
# override recipient key cipher preferences
# remove 3DES and prefer AES256
personal-cipher-preferences AES256 AES192 AES CAST5
# override recipient key digest preferences
# remove SHA-1 and prefer SHA-512
personal-digest-preferences SHA512 SHA384 SHA256 SHA224
# remove SHA-1 and 3DES from cipher preferences of newly created key
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
# reject SHA-1 signature
weak-digest SHA1
# never allow use 3DES
disable-cipher-algo 3DES
# use AES256 when symmetric encryption
s2k-cipher-algo AES256
# use SHA-512 when symmetric encryption
s2k-digest-algo SHA-512
# mangle password many times as possible when symmetric encryption
s2k-count 65011712
# both short and long key IDs are insecure
keyid-format none
# use full fingerprint instead
with-subkey-fingerprint
```

## Migrating signature digest to SHA-512
<!--more-->
Renew the key to regenerate its signature with SHA-512 (an algorithm specified with cert-digest-algo).

```
$ gpg --edit-key <SIGNATURE>
gpg> list

pub  rsa4096/06B8106665DD36F3
     作成: 2016-12-31  有効期限: 2021-12-30  利用法: SC  
     信用: 究極        有効性: 究極
ssb  rsa4096/99124A4267F56B75
     作成: 2016-12-31  有効期限: 2021-12-30  利用法: E   
[  究極  ] (1). Kazutoshi Noguchi <REDACTED>

gpg> 
# renew primary key
gpg> expire
2y
# renew all subkeys
# first subkey
gpg> key 1
gpg> expire
2y
```

## Removing SHA-1 and 3DES from cipher/hash preferences
```
gpg> setpref SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES CAST5 ZLIB BZIP2 ZIP Uncompressed
gpg> save
```

## Updating revocation certificate
Generate SHA512-signed revocation ceriticate and store it in safe place.

```sh
$ gpg -a --gen-revoke <SIGNATURE>
```

## Offline primary private key
### Adding a subkey for signing
By default, GnuPG uses the primary key for signing. You should create a subkey for signing because it is timesome restoring offline primary private key whenever signing. 

```
$ gpg --edit-key <SIGNATURE>
gpg> addkey
Please select what kind of key you want:
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
Your selection? 4
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 2y
Key expires at Wed Jan 12 06:12:20 2022 JST
Is this correct? (y/N) y
Really create? (y/N) y
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.

sec  rsa4096/0x06B8106665DD36F3
     created: 2016-12-31  expires: 2022-01-11  usage: SC  
     trust: ultimate      validity: ultimate
ssb  rsa4096/0x99124A4267F56B75
     created: 2016-12-31  expires: 2022-01-11  usage: E   
ssb  rsa4096/0xC2AC8CAE60CEDC4F
     created: 2020-01-12  expires: 2022-01-11  usage: S   
[ultimate] (1). Kazutoshi Noguchi <REDACTED>

gpg> save
```

### Backing up primary secret key
Backup `~/.gnupg` to safe place like encrypted USB stick.
(Warning: data in flash drives evaporates slowly)

```sh
$ cp -a ~/.gnupg <BACKUP>
```

If you need the primary secret key, mount the stick and use `--homedir` option.

```
$ gpg --homedir=<BACKUP> <OPERATION>
```

### Deleting primary secret key
Verify backup of `~/.gnupg` before deleting the primary secret key!

```sh
$ gpg --output subkeys_privkey.gpg --export-secret-subkeys <SIGNATURE>
$ gpg --delete-secret-key <SIGNATURE>
$ gpg --import subkeys_privkey.gpg
$ shred subkeys_privkey.gpg
$ rm subkeys_privkey.gpg
```

If the primary key is listed as `sec#`, the primary secret key is deleted successfully.

```sh
$ gpg --list-secret-keys
/home/<REDACTED>/.gnupg/pubring.kbx
------------------------------------
sec#  rsa4096 2016-12-31 [SC] [有効期限: 2022-01-11]
      BC6DCFE03513A9FA4F55D70206B8106665DD36F3
uid           [  究極  ] Kazutoshi Noguchi <REDACTED>
ssb   rsa4096 2016-12-31 [E] [有効期限: 2022-01-11]
      685C0C2243FC78BB8D26932F99124A4267F56B75
ssb   rsa4096 2020-01-12 [S] [有効期限: 2022-01-11]
      7081B0647E5CB6567F1836FAC2AC8CAE60CEDC4F
```
