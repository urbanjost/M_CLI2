program demo11
!! @(#) examples of validating values with ALL(3f) and ANY(3f)
use, intrinsic :: iso_fortran_env, only : stderr=>ERROR_UNIT, stdin=>INPUT_UNIT, stdout=>OUTPUT_UNIT
implicit none
type point
   integer           :: x=0
   integer           :: y=0
   character(len=20) :: color='red'
endtype point

type(point) :: dot; namelist /nml_dot/ dot

character(len=:),allocatable :: name
character(len=:),allocatable :: string
character(len=:),allocatable :: list(:)
character(len=80)            :: readme !(3)
integer                      :: i

print *,'demo11: examples of validating values with ALL(3f) and ANY(3f)'

! M_CLI2 intentionally does not have complex validators except for SPECIFIED(3f) and
! a check whether the input conforms to the type with get_args(3f)
! or the convenience functions like inum(3f). 
!
! Fortran already has powerful validation capabilities.  Logical
! expressions ANY(3f) and ALL(3f) are standard Fortran features easily
! allow performing the common validations for command line arguments
! without having to learn any additional syntax or methods.

do i=1,100
   if(all([i >= 10,i <= 30,(i/2)*2 == i]))then
      write(*,*)i,' is an even number from 10 to 30 inclusive'
   endif
enddo

name='red'
list = [character(len=10) :: 'red','white','blue']
if( any(name == list) )then
   write(*,*)name,' matches a value in the list'
else
   write(*,*)name,' not in the list'
endif

if(size(list).eq.3)then
   write(*,*)' list has expected number of values'
else
   write(*,*)' list does not have expected number of values'
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

end program demo11
