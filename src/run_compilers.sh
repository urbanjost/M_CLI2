
make clean
make ifort
../demos/demo1 -x 1111111 -y 2222222 -u -z 33333.9 -lL -u -v 
quiet ../demos/demo1 -usage 
quiet make run >x.if

make clean
make nvfortran
../demos/demo1 -x 1111111 -y 2222222 -u -z 33333.9 -lL -u -v 
quiet ../demos/demo1 -usage 
quiet make run >x.nf

make clean
make gfortran
../demos/demo1 -x 1111111 -y 2222222 -u -z 33333.9 -lL -u -v 
quiet ../demos/demo1 -usage 
quiet make run >x.gf

make clean
