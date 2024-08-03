program test_lastonly
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
   call set_mode('lastonly')
   call set_args(' --type run -o F -t F -x F --ox F --xo F --longa:O F --longb:X F -a "aaa" --stringb:b "bbb BBB" -c "cc c C CC"')
   whichone=sget('type')
   arr=[lget('o'),lget('t'),lget('x'),lget('ox'),lget('xo'),lget('longa'),lget('longb')]
   select case(whichone)
   case('one')   ; call testit(whichone,.not.any(arr))
   case('two')   ; call testit(whichone,all(arr))
   case('three') ; call testit(whichone,all(arr))
   case('four')  ; call testit(whichone,all(arr.eqv.[F,F,F,F,F,T,F]))
   case('five')  ; call testit(whichone,all(arr.eqv.[T,T,T,F,F,T,T]))
   case('six')   ; call testit(whichone,all(arr))
   case('seven') ; print it,'a=',sget('a');             call testit(whichone,sget('a')=='a b c')
   case('eight') ; print it,'stringb=',sget('stringb'); call testit(whichone,sget('stringb')=='a b c')
   case('nine')  ; print it,'stringb=',sget('stringb'); call testit(whichone,sget('stringb')=='a b c')
   case('run')
      print *,'test_lastonly: lastonly mode'
      call runit('--type one')
      call runit('--type two -oxt --ox --xo -OX --longa --longb')
      call runit('--type three -t -o -x  --ox --xo -O -X --longa --longb')
      call runit('--type four --longa --longa --longa --longa')
      call runit('--type five -t -o -x --longa --longb -O -X -OX -XO --longb')
      call runit('--type six -ox -t --ox --xo --longa --longb -xt -o --ox --xo --longa --longb')
      call runit('--type seven -a "a b c"')
      call runit('--type eight -b "a b c"')
      call runit('--type nine  --stringb "a b c"')
   case default
      print it,'unknown type'
   end select
contains

subroutine testit(string,test)
character(len=*),intent(in) :: string
logical,intent(in) :: test

   write(*,it,advance='no')arr
   if(test)then
      print it,':lastonly:',string,'passed'
   else
      print it,':lastonly:',string,'failed'
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

end program test_lastonly
