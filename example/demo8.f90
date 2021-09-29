program demo8
!!  multiple keyword and variable pairs on get_args(3f) for limited cases
!! SOMETIMES YOU CAN PUT MULTIPLE VALUES ON GETARGS(3f)
use M_CLI2,  only : set_args, get_args
implicit none
integer           :: x, y
logical           :: l
real              :: size
character(len=80) :: title
character(len=*),parameter :: pairs='(1("[",g0,"=",g0,"]":,1x))'
   ! DEFINE COMMAND AND PARSE COMMAND LINE
   ! set all values, double-quote strings
   call set_args('-x 1 -y 10 --size 12.34567 -l F --title "my title"' )
   ! GET THE VALUES
   ! only fixed scalar values (including only character variables that
   ! are fixed length) may be combined in one GET_ARGS(3f) call
   call get_args('x',x, 'y',y, 'l',l, 'size',size, 'title',title)
   ! USE THE VALUES
   write(*,fmt=pairs)'X',x,'Y',y,'size',size,'L',l,'TITLE',title
end program demo8
