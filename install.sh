#!/bin/bash

packs=(archdefs cutest mastsif sifdecode)
versions=(0.1 0.2 0.1 0.3)

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

