program test_syntax
!> @(#) unnamed to numbers
!! The default for inums, rnums, ... is to convert all unnamed argument values in "unnamed"
use, intrinsic :: iso_fortran_env, only : stderr=>ERROR_UNIT, stdin=>INPUT_UNIT, stdout=>OUTPUT_UNIT
use M_CLI2,  only : set_args, sget, sgets, iget, igets, rget, rgets, dget, dgets, lget, lgets
implicit none
character(len=*),parameter :: it='(1x,*(g0,1x))'
logical,parameter :: T=.true., F=.false.
character(len=:),allocatable :: whichone

   call set_args(' --type run -i 1 --ints:I 1,2,3 -s " " --strings " " -r 0.0 --reals:R 11.1,22.2,33.3')
   whichone=sget('type')
   select case(whichone)
   case('one')   
    call testit(whichone//' i',iget('i')==1)
    call testit(whichone//' ints',all(igets('ints')==[1,2,3]))
    call testit(whichone//' r',rget('r')==0.0)
    call testit(whichone//' reals',all(rgets('reals')==[11.1,22.2,33.3]))
    call testit(whichone//' s',sget('s')==" ")
    call testit(whichone//' strings',all(sgets('strings')==[" "]))
   case('two')   
    call testit(whichone//' ints',all(igets('ints')==[0,1,2,20,30,40,300,400,1000,2000]))
   case('three')   
    write(*,it)'three:size=',size(sgets('strings'))
    write(*,'(*("[",a,"]":,1x))')sgets('strings')
   case('run')
      print *,'test_syntax: syntax mode'
      call runit('--type one -u')
      call runit('--type one ')
      call runit('--type two -I 0,1,2 --ints=20:30:40 --ints 300,400 -I=1000,2000')
      call runit('--type three')
   case default
      print it,'unknown type'
   end select
contains

subroutine testit(string,test)
character(len=*),intent(in) :: string
logical,intent(in) :: test

   if(test)then
      print it,':syntax:',string,'passed'
   else
      print it,':syntax:',string,'failed'
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

end program test_syntax
