## Testing
rm -f test.log
source cutest_env.bashrc

for pkg in gen77 gen90 genc
do
  echo "Testing $pkg"
  ./bin/runcutest -p $pkg -D ROSENBR >> test.log
done
