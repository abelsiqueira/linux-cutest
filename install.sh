#!/bin/bash

VERSION=0.3

set -e

function usage() {
  echo "Usage:
./install.sh [OPTIONS]

    This command installs CUTEst downloading the required packages and creating
    a file in the end with the configuration to be added to your .bashrc file.

    Options:

      -v, --version   Shows the version.
      -h, --help      Show this help.
      --install-deps  Install the required dependencies. Mainly gsl-1.16 and
                      gfortran, but some distributions may require other
                      packages too.
      "
}

function header() {
  echo "linux-cutest $VERSION Copyright (C) 2016-2017  Abel Soares Siqueira
This program comes with ABSOLUTELY NO WARRANTY;
This is free software, and you are welcome to redistribute it
under certain conditions; see LICENSE.md for details.
"
}

function fix_libgfortran() {
  [ ! -z "$(ldconfig -p | grep libgfortran.so$)" ] && return
  possible_paths=("/usr/local/lib" "/usr/lib" "/usr/lib/gcc/x86_64-linux-gnu/")
  echo $possible_paths
  for path in ${possible_paths[@]}
  do
    echo $path
    libs=$(find $path -name "libgfortran.so")
    for lib in $libs
    do
      echo $lib
      if [ ! -z "$(nm $lib | grep 'GFORTRAN_1.3')" ]; then
        ln -s $lib .
        return
      fi
    done
  done
  echo "ERROR: libgfortran.so could not be found"
}

function on_ubuntu() {
  which apt-get &> /dev/null
}

function on_arch() {
  which pacman &> /dev/null
}

function install_deps() {
  on_ubuntu && cmd="sudo apt-get install gfortran"
  on_arch && cmd="sudo pacman -S wget gzip gcc-fortran"
  [ ! -z "$cmd" ] && echo -e "Installing dependencies\n$cmd" && $cmd

  ## Install libgsl
  if ! ldconfig -p | grep libgsl.so > /dev/null; then
    wget ftp://ftp.gnu.org/gnu/gsl/gsl-1.16.tar.gz
    tar -zxf gsl-1.16.tar.gz
    cd gsl-1.16
    ./configure && make -j5 && sudo make install
    cd ..
  fi

  if [ -z "$(ldconfig -p | grep libgfortran.so$)" ]; then
    if on_ubuntu; then
      findout=$(find /usr/lib/gcc/x86_64-linux-gnu/ -name "libgfortran.so")
      if [ -z "$findout" ]; then
        echo "libgfortran.so not found in /usr/lib/gcc/x86_64-linux-gnu"
        findout=$(find /usr/lib -name "libgfortran.so")
      fi
      echo $findout
      sudo ln -s $findout /usr/local/lib/
    fi
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

force="no"
while [[ $# -gt 0 ]]
do
  key=$1
  case $key in
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

fix_libgfortran

## Download and unpack everything

packs=(archdefs cutest mastsif sifdecode)
versions=(0.2 0.3 0.3 0.4)
service=(github github gitlab github)
cutest_file=cutest_env.bashrc
d_packs=(no no no no)

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
  if [ "${d_packs[1]}" == "yes" -o "${d_packs[3]}" == "yes" ]; then
    compile=yes
  else
    compile=no
  fi
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
  if [ "${d_packs[$i]}" == "no" ]; then
    echo "$p already downloaded. Skipping"
    continue
  elif [ -d ${packs[$i]} ]; then
    rm -rf ${packs[$i]}
  fi
  if [ ${service[$i]} == "github" ]; then
    url="https://github.com/optimizers/${p}-mirror/archive/v$v.tar.gz"
  elif [ ${service[$i]} == "gitlab" ]; then
    url="https://gitlab.com/dpo/${p}-mirror/repository/archive.tar.gz?ref=v$v"
  fi
  wget $url -O $p.tar.gz
  output_dir=$(tar --exclude='*/*' -ztf $p.tar.gz)
  tar -zxf $p.tar.gz
  mv $output_dir $p
  rm -f $p.tar.gz
done

if [ "$compile" == "yes" ]; then
  ## Sifdecode
  cd sifdecode
  # Uninstall current sifdecode, if any
  if [ -d objects/$MYARCH/double ]; then
    echo -e "1\ny\nn" | ./uninstall_sifdecode
  fi
  echo -e "6\n2\n4\nnny" | ./install_sifdecode
  cd ..

  ## CUTEst
  cd cutest
  if [ -d objects/$MYARCH/double ]; then
    echo -e "1\ny\nn" | ./uninstall_cutest
  fi
  echo -e "6\n2\n4\n2\n7\nnnyDn" | ./install_cutest
  cd ..
fi

for prec in double
do
  cd cutest/objects/$MYARCH/$prec
  l=libcutest.a
  lname="$(basename $l .a)_$prec.so"
  ld -fPIC -shared --whole-archive $l --no-whole-archive -o $lname -lgfortran
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
cat > cutest_env.bashrc << EOF
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
  echo "export ${packs[$i]}_version=${versions[$i]}" >> cutest_env.bashrc
done

echo "---"
echo "CUTEst installed"
echo "To use globally, issue the command"
echo "  cat $cutest_file >> \$HOME/.bashrc"
echo "---"

# gfortran is installed, but maybe it is "hidden"
if ! ldconfig -p | grep libgfortran.so > /dev/null; then
  # Maybe it's on gcc folder?
  findout=$(find /usr/lib/gcc/x86_64-linux-gnu/ -name "libgfortran.so")
  # Not there
  if [ -z "$findout" ]; then
    echo "libgfortran.so not found. Try 'sudo find / -name "libgfortran.so"'"
    echo "If found this way, use 'sudo ln -s FULLPATH /usr/local/lib'"
  elif [ $(echo $findout | wc -w) == 1 ]; then
    echo "Enter 'ln -s $findout /usr/local/lib'"
  else
    echo "Found more than one libgfortran.so:"
    for f in $findout; do echo "  $f"; done
    echo "Try 'ln -s FULLPATH /usr/local/lib' for one of then."
    echo "If that doesn't work, 'rm -f /usr/local/lib/libgfortran.so'"
    echo "and try with another"
  fi
fi
