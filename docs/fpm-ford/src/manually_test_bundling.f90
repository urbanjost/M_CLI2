program demo18
!!  @(#) using the convenience functions
use M_CLI2, only : set_args, set_mode, get_args
implicit none
logical :: o,x,t,ox,xo,x_up,o_up,a,b

   print *,'demo18: using the bundling option'

   call set_mode('strict')
   call set_mode('ignorecase')

   call set_args('-x F -o F -X F -O F -t F --ox F -xo F -longa:a F -longb:b')
   call get_args('x',x,'o',o,'t',t,'xo',xo,'ox',ox,'X',x_up,'O',o_up)
   call get_args('longa',a,'longb',b)
!! USE THE VALUES IN YOUR PROGRAM.
   write(*, '(*(g0:,1x))')'x=',x, 'o=',o, 't=',t 
   write(*, '(*(g0:,1x))')'ox=',ox, 'xo=',xo
   write(*, '(*(g0:,1x))')'O=',o_up, 'X=',x_up
   write(*, '(*(g0:,1x))')'longa=',a, 'longb=',b

end program demo18
