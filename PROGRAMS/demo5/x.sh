#!/bin/bash
set -v
 demo5
 demo5 -x aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
 demo5 -y aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
 demo5 -xarr ' ABCDE FGHIJ KLMNO PQRS '
 demo5 -xarr ' ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz'
 demo5 -x 'abcd"efg'
 demo5 -x 'abcd""efg'
 demo5 -xarr a,b,c,d,e,f,g
 demo5 -xarr ' a b c d e f g'
 demo5 -xarr ' a b c d e f g h,i,j k:l:m   '
 demo5 -xarr ' a  '
 : BUGS
 demo5 -xarr A
