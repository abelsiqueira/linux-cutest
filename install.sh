#!/bin/bash

set -e

echo "
linux-installer  Copyright (C) 2016  Abel Soares Siqueira
This program comes with ABSOLUTELY NO WARRANTY;
This is free software, and you are welcome to redistribute it
under certain conditions; see LICENSE.md for details.
"

## Download and unpack everything

packs=(archdefs cutest mastsif sifdecode)
versions=(0.1 0.2 0.1 0.3)
cutest_file=cutest_env.bashrc

export MYARCH=pc64.lnx.gfo
export CUTEST=$PWD/cutest
export SIFDECODE=$PWD/sifdecode
export ARCHDEFS=$PWD/archdefs
export MASTSIF=$PWD/mastsif

for i in $(seq 0 3)
do
  p=${packs[$i]}
  v=${versions[$i]}
  if [ -d ${p} ]; then
    echo "$p already downloaded. Skipping"
    continue
  fi
  wget "https://github.com/optimizers/${p}-mirror/archive/v$v.tar.gz"
  tar -zxf v$v.tar.gz
  mv ${p}-mirror-$v $p
  rm -f v$v.tar.gz
done

## Sifdecode
if [ ! -d sifdecode/objects/$MYARCH ]; then
  cd sifdecode
  echo -e "6\n2\n2\nnny" | ./install_sifdecode
  cd ..
else
  echo "SifDecode already installed for $MYARCH"
fi

## CUTEst
if [ ! -d cutest/objects/$MYARCH ]; then
  cd cutest
  echo -e "6\n2\n2\n2\n4\nnnydn" | ./install_cutest
  cd ..
else
  echo "CUTEst already installed for $MYARCH"
fi

for prec in double
do
  cd cutest/objects/$MYARCH/$prec
  pwd
  for l in $(ls *.a)
  do
    echo "Compiling $l"
    lname="$(basename $l .a)_$prec.so"
    ld -fPIC -shared --whole-archive $l --no-whole-archive -o $lname -lgfortran
  done
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
export PATH=$PWD/bin:\$PATH
export MANPATH=$PWD/man:\$MANPATH
export LD_LIBRARY_PATH=$PWD/lib:\$LD_LIBRARY_PATH
EOF

echo "---"
echo "CUTEst installed"
echo "To use globally, issue the command"
echo "  cat $cutest_file >> \$HOME/.bashrc"
echo "---"
