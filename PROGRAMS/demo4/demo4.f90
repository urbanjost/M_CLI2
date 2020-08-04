program quick_and_dirty
!! COMPLEX VALUES
use M_CLI2,  only : set_args, get_args
implicit none
complex                      :: x, y, z

   write(*,*)'complex values:'
   write(*,*)'demo4 -x 11.1,22.2 -y 333,444'
   write(*,*)"demo4 -x '(11.1,22.2)'"

   call set_args('-x (1,2) -y (10,20) -z (100,200)')
   call get_args('x',x)
   call get_args('y',y)
   call get_args('z',z)
   write(*,*)x,y,z, x+y+z
end program quick_and_dirty
