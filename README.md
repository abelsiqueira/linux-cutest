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

Also check the Julia interface for CUTEst,
[CUTEst.jl](http://github.com/JuliaOptimizers/CUTEst.jl).

## Install

After installing the [Requirements](#requirements),
simply enter the command

    ./install.sh

The script will download the required packages, uncompress, and install.
Then you'll need to add some lines to your `.bashrc`, with the command

    cat cutest_env.bashrc >> $HOME/.bashrc

## Requirements

You need at least `wget`, `gfortran` and `libgsl`. You also need
`libgfortran.so` to be visible by your system.

### Ubuntu

This was tested on Ubuntu 12.04 from Travis

    sudo apt-get install wget gfortran libgsl0-dev
    sudo ln -s /usr/lib/gcc/x86_64-linux-gnu/$(gfortran -dumpversion | \
      cut -f1,2 -d.)/libgfortran.so /usr/local/lib/
