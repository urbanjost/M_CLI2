program test_strict
!> @(#) unnamed to numbers
!! The default for inums, rnums, ... is to convert all unnamed argument values in "unnamed"
use, intrinsic :: iso_fortran_env, only : stderr=>ERROR_UNIT, stdin=>INPUT_UNIT, stdout=>OUTPUT_UNIT
use M_CLI2,  only : set_args, sget, igets, rgets, dgets, lget, set_mode
implicit none
character(len=*),parameter :: it='(1x,*(g0,1x))'
logical,parameter :: T=.true., F=.false.
character(len=:),allocatable :: whichone
logical,allocatable :: arr(:)
   call set_mode('strict')
   call set_args(' --type run -o F -t F -x F --ox F --xo F --longa:O F --longb:X F')
   whichone=sget('type')
   arr=[lget('o'),lget('t'),lget('x'),lget('ox'),lget('xo'),lget('longa'),lget('longb')]
   select case(whichone)
   case('one')   ; call testit(whichone,.not.any(arr))
   case('two')   ; call testit(whichone,  all(arr))
   case('three') ; call testit(whichone,all(arr.eqv.[T,T,T,F,F,F,F]))
   case('four')  ; call testit(whichone,all(arr.eqv.[F,F,F,T,T,F,F]))
   case('five')  ; call testit(whichone,all(arr.eqv.[T,T,T,F,F,F,F]))
   case('six')   ; call testit(whichone,  all(arr))
   case('run')
      print *,'test_strict: strict mode'
      call runit('--type one ')
      call runit('--type two -ox -t --ox --xo -OX')
      call runit('--type three -tox ')
      call runit('--type four --ox --xo')
      call runit('--type five -t -o -x ')
      call runit('--type six -ox -t --ox --xo --longa --longb')
   case default
      print it,'unknown type'
   end select
contains

subroutine testit(string,test)
character(len=*),intent(in) :: string
logical,intent(in) :: test

   write(*,it,advance='no')arr
   if(test)then
      print it,':strict:',string,'passed'
   else
      print it,':strict:',string,'failed'
      stop 1
   endif

end subroutine testit

subroutine runit(string)
character(len=*),intent(in) :: string
character(len=4096) :: cmd
   call get_command_argument(0,cmd)
   write(stdout,*)'RUN:',trim(cmd)//' '//string
   call execute_command_line(trim(cmd)//' '//string)
end subroutine runit

end program test_strict
