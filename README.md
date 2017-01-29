# Linux CUTEst Installer

[![Build Status](https://travis-ci.org/abelsiqueira/linux-cutest.svg?branch=master)](https://travis-ci.org/abelsiqueira/linux-cutest)

This repository is solely for installing
CUTEst in an easy way including shared libraries.
My only objective is to give support to a simple installation for a
64 bits linux computer with gcc and gfortran.
If you are using OSX, I suggest the great
[homebrew-cutest](http://github.com/optimizers/homebrew-cutest).

This script uses the git versions of the CUTEst repository, namely
[cutest-mirror](http://github.com/optimizers/cutest-mirror),
[sifdecode-mirror](http://github.com/optimizers/sifdecode-mirror),
[archdefs-mirror](http://github.com/optimizers/archdefs-mirror),
[sifdecode-mirror](http://github.com/optimizers/sifdecode-mirror).

The Julia interface for CUTEst,
[CUTEst.jl](http://github.com/JuliaOptimizers/CUTEst.jl),
uses this script to install CUTEst for linux.

## Install

CUTEst has a few dependencies. If you want to let te script tries to install
them to you, issue

    ./install.sh --install-deps

If you tried to install automatically the dependencies and the script failed,
you can help me by opening a pull-request or at least an issue informing what
went wrong.

To install manually the dependencies, check the [Requirements](#requirements),
and then enter the command

    ./install.sh

The script will download the required packages, uncompress, and install.
Then you'll need to add some lines to your `.bashrc`, with the command

    cat cutest_env.bashrc >> $HOME/.bashrc

## Requirements

You need at least `wget`, `gfortran` and `gsl` version 1.16. You also need
`libgfortran.so` to be visible by your system, which may need additional
commands.

### Ubuntu 14.04

On Ubuntu 14.04, this can be done with
```
sudo apt-get install wget gfortran libgsl0-dev
```
and then you have to find `libgfortran.so`, which is probably
```
ls /usr/lib/gcc/x86_64-linux-gnu/XXX/
```
where XXX is some version number (for instance 5.4.0).
After found, use
```
sudo ln -s /usr/lib/gcc/x86_64-linux-gnu/XXX/libgfortran.so /usr/local/lib
```

### Ubuntu 16.04

Install `wget` and `gfortran`.
```
sudo apt-get install wget gfortran
```

You'll have to manually install gsl-1.16.
Download gsl-1.16 from http://mirror.nbtelecom.com.br/gnu/gsl/gsl-1.16.tar.gz
then issue the following commands
```
tar -zxf gsl-1.16.tar.gz
cd gsl-1.16
./configure
make
sudo make install
```
Finally, you'll need to make `libgfortran.so` visible. Probably with
```
sudo ln -s /usr/lib/x86_64-linux-gnu/libgfortran.so.3 /usr/local/lib/libgfortran.so
```

### Other systems

Open an issue so I can help you, or a Pull Request helping me.
