program demo1
!!  using the convenience functions
   use M_CLI2, only : set_args, get_args_fixed_size 
   use M_CLI2, only :  dget,  iget,  lget,  rget,  sget,  cget ! for scalars
   use M_CLI2, only : dgets, igets, lgets, rgets, sgets, cgets ! for allocatable arrays
   implicit none

!! DECLARE "ARGS"
   real                           :: x,  y,  z,  point(3)
   character(len=:), allocatable  :: title, anytitle
   logical                        :: l,  lupper

!! SET ALL ARGUMENTS TO DEFAULTS WITH SHORT NAMES FOR LONG NAMES AND THEN ADD COMMAND LINE VALUES
   call set_args('-x 1.1 -y 2e3 -z -3.9 --point:p -1,-2,-3 --title:T "my title" --anytitle:a "my title" -l F -L F')

!! ALL DONE CRACKING THE COMMAND LINE. GET THE VALUES
   x=rget('x'); y=rget('y'); z=rget('z')
   l=lget('l'); lupper=lget('L')
   title=sget('title') 
   anytitle=sget('anytitle') 

   ! With a fixed-size array to ensure the correct number of values are input use
   call get_args_fixed_size('point',point)

!! USE THE VALUES IN YOUR PROGRAM.
   write(*, '(*(g0:,1x))')'x=',x, 'y=',y, 'z=',z, 'SUM=',x+y+z, ' point=',point
   write(*, '(*(g0:,1x))')'title=', trim(title),  ' l=', l, 'L=', lupper
   write(*, '(*(g0:,1x))')'anytitle=', trim(anytitle)

end program demo1

!! NOTES: WHEN DEFINING THE PROTOTYPE
   !  o All parameters must be listed with a default value
   !  o string values must be double-quoted
   !  o numeric lists must be comma-delimited. No spaces are allowed
   !  o long keynames must be all lowercase but may be followed by :LETTER where LETTER is a
   !    single letter that may be of any case that will act as a short name for the same value.
