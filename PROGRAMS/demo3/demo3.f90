program basic
!! QUICK PROTOTYPE: JUST THE BARE ESSENTIALS
use M_CLI2,  only : set_args, get_args
implicit none
integer                      :: x, y, z
   call set_args('-x 1 -y 10 -z 100')
   call get_args('x',x)
   call get_args('y',y)
   call get_args('z',z)
   write(*,'(*(g0,1x))')x,y,z, x+y+z
end program basic
