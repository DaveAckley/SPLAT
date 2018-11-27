# SPLAT
Repository for programming language SPLAT: **S**patial **P**rogramming **L**anguage, **A**SCII **T**ext

###### MIGHT-CONCEIVABLY-WORK QUICK-START FOR PROGRAMMERS

```
$ sudo apt-get install git g++ libsdl1.2-dev libsdl-image1.2-dev libsdl-ttf2.0-dev libcrypt-openssl-bignum-perl libcrypt-openssl-rsa-perl libcapture-tiny-perl
$ mkdir REPOS
$ cd REPOS
$ git clone https://github.com/DaveAckley/MFM.git
$ git clone https://github.com/DaveAckley/ULAM.git
$ git clone https://github.com/DaveAckley/SPLAT.git
$ pushd MFM; make realclean; make; popd  # wait a while
$ pushd MFM/bin
$ ./mfzmake keygen `whoami`              # Note those are backquotes
$ ./mfzmake default `whoami`
$ popd
$ pushd ULAM; make -f rebuild.mk; popd   # wait a loooong while
$ cd SPLAT
$ make
$ ls demos
$ cd demos/FB
$ make
$ # If all went well, mfms appears and you can
$ # lay down a nice red FB atom to destroy the world
```
