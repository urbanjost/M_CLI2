program demo16
!> @(#) unnamed to numbers
!! The default for inums, rnums, ... is to convert all unnamed argument values in "unnamed"
use, intrinsic :: iso_fortran_env, only : stderr=>ERROR_UNIT, stdin=>INPUT_UNIT, stdout=>OUTPUT_UNIT
use M_CLI2,  only : set_args, sget, igets, rgets, dgets
implicit none
character(len=*),parameter :: all='(1x,*(g0,1x))'
   call set_args('-type test')
   select case(sget('type'))
   case('i','int','integer');  print all, igets()
   case('r','real');           print all, rgets()
   case('d','double');         print all, dgets()
   case('test')
      print *,'demo16: convert all arguments to numerics'
      ! positive BOZ whole number values are allowed
      ! e-format is allowed, ints(3f) truncates
      call runit('-type i 10 b10 o10 z10 14.1 14.5 14.999 45.67e3')
      call runit('-type r 10 b10 o10 z10 14.1 14.5 14.999 45.67e3')
      call runit('-type d 10 b10 o10 z10 14.1 14.5 14.999 45.67e3')
   case default
      print all,'unknown type'
   end select
contains
subroutine runit(string)
character(len=*),intent(in) :: string
character(len=4096) :: cmd
   call get_command_argument(0,cmd)
   write(stdout,*)'RUN:',trim(cmd)//' '//string
   call execute_command_line(trim(cmd)//' '//string)
end subroutine runit
end program demo16
