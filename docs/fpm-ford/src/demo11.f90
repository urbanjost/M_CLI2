program testit
use, intrinsic :: iso_fortran_env, only : stderr=>ERROR_UNIT, stdin=>INPUT_UNIT, stdout=>OUTPUT_UNIT

type point
   integer           :: x=0
   integer           :: y=0
   character(len=20) :: color='red'
endtype point

type(point) :: dot; namelist /nml_dot/ dot

character(len=:),allocatable :: name
character(len=:),allocatable :: string
character(len=80)           :: readme !(3)

! M_CLI2 does not have validators except for SELECTED(3f) and
! a check whether the input conforms to the type with get_args(3f)
! and the convenience functions like inum(3f). But Fortran already
! has powerful validation capabilities, especially with the use
! of logical expressions, and ANY(3f) and ALL(3f). 

! A somewhat contrived example of using ALL(3f):

! even number from 10 to 30 inclusive
do i=1,100
   if(all([i.ge.10,i.le.30,i/2*2.eq.i]))then
      write(*,*)'good',i
   endif
enddo

! an example of using ANY(3f)

! matched
name='red'
if(any(name.eq.[character(len=10) :: 'red','white','blue']))then
   write(*,*)'matches ', name
endif
! not matched
name='teal'
if(any(name.eq.[character(len=10) :: 'red','white','blue']))then
   write(*,*)'matches ', name
endif

! and even user-defined types can be processed by reading the input
! as a string and using a NAMELIST(3f) group to convert it. Note that
! if input values are strings that have to be quoted (ie. more than one
! word) or contain characters special to the shell that how you have to
! quote the command line can get complicated.

string='10,20,"green"'

readme='&nml_dot dot='//string//'/'

! some compilers might require the input to be on three lines
!readme=[ character(len=80) ::&
!'&nml_dot', &
!'dot='//string//' ,', &
!'/']

read(readme,nml=nml_dot)

write(*,*)dot%x,dot%y,dot%color
! or
write(*,nml_dot)

! Hopefully it is obvious how the options can be read from values gotten
! with SGET(3f) and SGETS(3f) in this case, and with functions like IGET(3f)
! in the first case, so this example just uses simple declarations to highlight
! some useful Fortran expressions that can be useful for validating the input
! or even reading user-defined types or even intrinsics via NAMELIST(7f) groups.

! another alternative would be to validate expressions from strings using M_calculator(3f)
! but I find it easier to validate the values using regular Fortran code than doing it
! via M_CLI2(3f), although if TLI (terminal screen GUIs) or GUIs are supported later by
! M_CLI2(3f) doing validation in the input forms themselves would be more desirable.

end program testit
