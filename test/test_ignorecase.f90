program test_ignorecase
!> @(#) unnamed to numbers
!! The default for inums, rnums, ... is to convert all unnamed argument values in "unnamed"
use, intrinsic :: iso_fortran_env, only : stderr=>ERROR_UNIT, stdin=>INPUT_UNIT, stdout=>OUTPUT_UNIT
use M_CLI2,  only : set_args, sget, igets, rgets, dgets, lget, set_mode
implicit none
character(len=*),parameter :: it='(1x,*(g0,1x))'
character(len=:),allocatable :: whichone
character(len=:),allocatable :: arr(:)
   call set_mode('ignorecase')

   call set_args(' --type run -a "a AA a" -b "B bb B"  -A AAA -B BBB --longa:O " OoO " --longb:X "xXx"')
   whichone=sget('type')
   arr=[character(len=17) :: sget('a'),sget('b'),sget('A'),sget('B'),sget('longa'),sget('longb'),sget('O'),sget('X') ]
   select case(whichone)
   case('one')   ; call testit(whichone,all([character(len=17)::'a AA a','B bb B','AAA','BBB',' OoO','xXx',' OoO','xXx']==arr))
   case('two')   ; call testit(whichone,all([character(len=17)::'a','b','A','B','longa O','longb X','longa O','longb X']==arr))
   case('three') ; call testit(whichone,all([character(len=17)::'a','b','A','B','longa O','longb X','longa O','longb X']==arr))
   case('four')  ; call testit(whichone,all([character(len=17)::'a A','b B','SET A','SET B',' OoO','xXx',' OoO','xXx']==arr))
   case('five')  ; call testit(whichone,all([character(len=17)::'a AA a','B bb B','AAA','BBB', &
                   & 'a b c d e f g h i','xXx','a b c d e f g h i','xXx']==arr))
   case('six')   ; !call testit(whichone,  all(arr))
   case('run')
      print *,'test_ignorecase: ignorecase mode'
      call runit('--type one ')
      call runit('--type two   -a  a -b b  -A A -B B   -longa longa -longb   longb -O  O -X X ')
      call runit('--type three -a a -b  b -A A  -B B -LONGA   longa -LONGB   longb -O O -X  X')
      call runit('--type four -a a -b  b -a A  -b B -A "SET A" -B "SET B"')
      call runit('--type five --LongA "a b c" -longa "d e f" -longA "g h i"')
!      call runit('--type six -ox -t --ox --xo --longa --longb')
   case default
      print it,'unknown type'
   end select
contains

subroutine testit(string,test)
character(len=*),intent(in) :: string
logical,intent(in) :: test
integer :: i

   if(test)then
      write(*,it,advance='no')':ignorecase:',string,'passed'
      write(*,it)(trim(arr(i)),i=1,size(arr))
   else
      write(*,it,advance='no')':ignorecase:',string,'failed'
      write(*,it)(trim(arr(i)),i=1,size(arr))
      stop 1
   endif

end subroutine testit

subroutine runit(string)
character(len=*),intent(in) :: string
character(len=4096) :: cmd
   call get_command_argument(0,cmd)
   !write(stdout,*)'RUN:',trim(cmd)//' '//string
   write(stdout,it,advance='yes')'RUN:',string
   call execute_command_line(trim(cmd)//' '//string)
end subroutine runit

end program test_ignorecase
