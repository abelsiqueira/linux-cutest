#!/bin/bash

VERSION=0.4.1
LIBGFORTRANDEST=/usr/local/lib
packs=(ARCHDefs CUTEst sif SIFDecode)
packnames=(archdefs cutest mastsif sifdecode)
versions=(2.0.3 2.0.2 master 2.0.1)
service=(github github bitbucket github)

set -e

function usage() {
  echo "Usage:
./install.sh [OPTIONS]

    This command installs CUTEst downloading the required packages and creating
    a file in the end with the configuration to be added to your .bashrc file.

    Options:

      -v, --version        Shows the version.
      -h, --help           Show this help.
      --link-gfortran      Add a link to libgfortran on LIBGFORTRANDEST,
                           which default to /usr/local/lib.
      --install-deps       Install the required dependencies. Mainly gsl-1.16 and
                           gfortran, but some distributions may require other
                           packages too.
      "
}

function header() {
  echo "linux-cutest $VERSION Copyright (C) 2016-2019  Abel Soares Siqueira
This program comes with ABSOLUTELY NO WARRANTY;
This is free software, and you are welcome to redistribute it
under certain conditions; see LICENSE.md for details.
"
}

# Objective: Link libgfortran.so to LIBGFORTRANDEST
function link_libgfortran() {
  [ -z "$LIBGFORTRANDEST" ] && echo "Warning: LIBGFORTRANDEST is empty. Not linking." && return
  SUDO=""
  [ -f "$LIBGFORTRANDEST/libgfortran.so" ] && echo "Warning: libgfortran.so already found on $LIBGFORTRANDEST." && return
  if ! command -v gfortran &> /dev/null; then
    echo "ERROR: gfortran not installed"
    exit 1
  fi
  lib=$(gfortran --print-file libgfortran.so)
  [ ! -f "$lib" ] && echo "ERROR: libgfortran.so not found by gfortran --print-file" && exit 1

  mkdir -p $LIBGFORTRANDEST
  if [ ! -w "$LIBGFORTRANDEST" ]; then
    SUDO=sudo
    echo -e "Warning: Need sudo to link libgfortran.so from\n$lib\nto\n$LIBGFORTRANDEST"
  fi
  $SUDO ln -s $lib $LIBGFORTRANDEST
}

function install_deps() {
  [ ! -z "$cmd" ] && echo -e "Installing dependencies\n$cmd" && $cmd

  ## Install libgsl
  if ! ldconfig -p | grep libgsl.so > /dev/null; then
    wget ftp://ftp.gnu.org/gnu/gsl/gsl-1.16.tar.gz
    tar -zxf gsl-1.16.tar.gz
    cd gsl-1.16
    ./configure && make -j5 && sudo make install
    cd ..
  fi

}

# Compare two version A and B
# true if A > B
function version_compare() {
  if [ $# -lt 2 ]; then
    echo "Needs two arguments"
    exit 1
  fi
  lowest=$(echo -e "$1\n$2" | sort -V | head -n 1)
  [ "$lowest" != "$1" ] && echo "yes" || echo "no"
}

# --------------------------------------------------------------

force="no"
while [[ $# -gt 0 ]]
do
  key=$1
  case $key in
    --link-gfortran)
      create_libgfortran_link="yes"
      ;;
    --install-deps)
      force="yes"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -v|--version)
      echo $VERSION
      exit 0
      ;;
    *)
      echo "ERROR: unrecognized option '$key'"
      usage
      exit 1
      ;;
  esac
  shift
done

header

if [ "$force" == "yes" ]; then
  install_deps
fi

if [ "$create_libgfortran_link" == "yes" ]; then
  link_libgfortran
fi

## Download and unpack everything

d_packs=(no no no no)
cutest_file=cutest_env.bashrc

# Check if cutest_file exists, and if only an updated is required
if [ -f $cutest_file ]; then
  source $cutest_file
  # For old installations
  if [ -z "$cutest_version" ]; then
    d_packs=(yes yes yes yes)
  else
    for i in $(seq 0 3)
    do
      eval installed_version=\$${packs[$i]}_version
      d_packs[$i]=$(version_compare ${versions[$i]} $installed_version)
    done
  fi
else
  d_packs=(yes yes yes yes)
fi
if [ "${d_packs[1]}" == "yes" -o "${d_packs[3]}" == "yes" ]; then
  compile=yes
else
  compile=no
fi

export MYARCH=pc64.lnx.gfo
export CUTEST=$PWD/cutest
export SIFDECODE=$PWD/sifdecode
export ARCHDEFS=$PWD/archdefs
export MASTSIF=$PWD/mastsif

for i in $(seq 0 3)
do
  p=${packs[$i]}
  v=${versions[$i]}
  pname=${packnames[$i]}
  if [ "${d_packs[$i]}" == "no" ]; then
    echo "$p already downloaded. Skipping"
    continue
  elif [ -d ${packs[$i]} ]; then
    rm -rf ${packs[$i]}
  fi
  if [ ${service[$i]} == "github" ]; then
    url="https://github.com/ralna/${p}/archive/v$v.tar.gz"
  elif [ ${service[$i]} == "gitlab" ]; then
    url="https://gitlab.com/dpo/${p}-mirror/repository/archive.tar.gz?ref=v$v"
  elif [ ${service[$i]} == "bitbucket" ]; then
    url="https://bitbucket.org/optrove/${p}/get/$v.tar.gz"
  fi
  wget $url -O $p.tar.gz
  output_dir=$(tar --exclude='*/*' -ztf $p.tar.gz)
  tar -zxf $p.tar.gz
  mv $output_dir $pname
  rm -f $p.tar.gz
done

#### Fix ARCHDefs - remove when new version is release
sed -i 's/CC=gcc-4.9/CC=gcc/g' $ARCHDEFS/ccompiler.pc64.lnx.gcc
#### End fix

if [ "$compile" == "yes" ]; then
  ## Sifdecode
  cd sifdecode
  # Uninstall current sifdecode, if any
  if [ -d objects/$MYARCH/double ]; then
    echo -e "1\ny\nn" | ./uninstall_sifdecode
  fi
  echo -e "6\n2\n5\nnny" | ./install_sifdecode
  cd ..

  ## CUTEst
  cd cutest
  if [ -d objects/$MYARCH/double ]; then
    echo -e "1\ny\nn" | ./uninstall_cutest
  fi
  echo -e "6\n2\n5\n2\n7\nnnyDn" | ./install_cutest
  cd ..
fi

for prec in double
do
  cd cutest/objects/$MYARCH/$prec
  l=libcutest.a
  lname="$(basename $l .a)_$prec.so"
  ld -fPIC -shared --whole-archive $l --no-whole-archive -o $lname \
    $(gfortran --print-file libgfortran.so)
  cd ../../../..
done

## Linking
mkdir -p {bin,lib,man}
for f in classall select sifdecoder
do
  ln -sf $PWD/sifdecode/bin/$f bin/$f
done
for f in cutest2matlab runcutest
do
  ln -sf $PWD/cutest/bin/$f bin/$f
done
for l in $(ls {sifdecode,cutest}/objects/$MYARCH/double/*.{a,so})
do
  ln -sf $PWD/$l lib/
done

for n in 1 3
do
  for f in $(ls {sifdecode,cutest}/man/man$n/*.$n)
  do
    ln -sf $PWD/$f man/
  done
done

## Creating bashrc
cat > $cutest_file << EOF
export ARCHDEFS=$PWD/archdefs
export CUTEST=$PWD/cutest
export SIFDECODE=$PWD/sifdecode
export MASTSIF=$PWD/mastsif
export MYARCH=$MYARCH
export PATH=$CUTEST/bin:$SIFDECODE/bin:\$PATH
export MANPATH=$CUTEST/man:$SIFDECODE/man:\$MANPATH
export LD_LIBRARY_PATH=$PWD/lib:\$LD_LIBRARY_PATH

EOF
for i in $(seq 0 3)
do
  echo "export ${packs[$i]}_version=${versions[$i]}" >> $cutest_file
done

echo "---"
echo "CUTEst installed"
echo "To use globally, issue the command"
echo "  cat $cutest_file >> \$HOME/.bashrc"
echo "---"
