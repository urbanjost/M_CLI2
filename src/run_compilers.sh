#!/bin/bash

(
exec 2>&1
make clean
make ifort
../example/demo1 -x 1111111 -y 2222222 -u -z 33333.9 -lL -u -v 
../example/demo1 -usage 
make run
)>x.if

(
exec 2>&1
make clean
make nvfortran
../example/demo1 -x 1111111 -y 2222222 -u -z 33333.9 -lL -u -v 
../example/demo1 -usage 
make run 
) >x.nf

(
exec 2>&1
make clean
make gfortran
../example/demo1 -x 1111111 -y 2222222 -u -z 33333.9 -lL -u -v 
../example/demo1 -usage 
make run 
) >x.gf

make clean
