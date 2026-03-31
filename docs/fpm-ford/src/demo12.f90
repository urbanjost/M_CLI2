program demo12
!!  @(#) using the convenience functions
use M_CLI2, only : set_args, set_mode, rget
implicit none
real :: x,  y,  z

   print *,'demo12: using the convenience functions'

!! ENABLE USING RESPONSE FILES
   call set_mode('response file')

   call set_args('-x 1.1 -y 2e3 -z -3.9 ')
   x = rget('x')
   y = rget('y')
   z = rget('z')
!! USE THE VALUES IN YOUR PROGRAM.
   write(*, '(*(g0:,1x))')'x=',x, 'y=',y, 'z=',z, 'SUM=',x+y+z

end program demo12
