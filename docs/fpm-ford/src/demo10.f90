program demo1
!!  full usage and even equivalencing
use M_CLI2,  only : set_args, get_args, unnamed
use M_CLI2,  only : get_args_fixed_size, get_args_fixed_length
use M_CLI2,  only : specified ! only needed if equivalence keynames
implicit none
integer            :: i

!! DECLARE "ARGS"
real               :: x, y, z
real               :: point(3), p(3)
character(len=80)  :: title
logical            :: l, l_
equivalence(point,p)

!! WHEN DEFINING THE PROTOTYPE
   !  o All parameters must be listed with a default value
   !  o string values  must be double-quoted
   !  o numeric lists must be comma-delimited. No spaces are allowed
   !  o long keynames must be all lowercase

   !! SET ALL ARGUMENTS TO DEFAULTS AND THEN ADD IN COMMAND LINE VALUES
   call set_args('-x 1 -y 2 -z 3 --point -1,-2,-3 --p -1,-2,-3 --title "my title" -l F -L F')
   !! ALL DONE CRACKING THE COMMAND LINE. GET THE VALUES
   call get_args('x',x)
   call get_args('y',y)
   call get_args('z',z)

   ! note these are equivalenced so one of the calls must be conditional
   call get_args_fixed_size('point',point)
   if(specified('p')) call get_args_fixed_size('p',p)

   ! if for some reason you want to use a fixed-length string use
   ! get_args_fixed_length(3f) instead of get_args(3f)
   call get_args_fixed_length('title',title)

   call get_args('l',l)
   call get_args('L',l_)
   !! USE THE VALUES IN YOUR PROGRAM.
   write(*,*)'x=',x,'y=',y,'z=',z,'SUM=',x+y+z
   write(*,*)'point=',point,'p=',p
   write(*,*)'title=',trim(title)
   write(*,*)'l=',l,'L=',l_
   !
   ! the optional unnamed values on the command line are
   ! accumulated in the character array "UNNAMED"
   if(size(unnamed).gt.0)then
      write(*,'(a)')'files:'
      write(*,'(i6.6,3a)')(i,'[',unnamed(i),']',i=1,size(unnamed))
   endif

end program demo1
