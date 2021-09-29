program demo7
!!  controlling array delimiter characters
use M_CLI2,  only : set_args, get_args, get_args_fixed_size, get_args_fixed_length
implicit none
integer,parameter              :: dp=kind(0.0d0)

character(len=20),allocatable  :: flen(:)   ! allocatable array with fixed length
character(len=4)               :: fixed(2)  ! fixed-size array wih fixed length

integer,allocatable            :: integers(:)
real,allocatable               :: reals(:)
real(kind=dp),allocatable      :: doubles(:)
real(kind=dp),allocatable      :: normal(:)
complex,allocatable            :: complexs(:)
character(len=:),allocatable   :: characters(:)  ! allocatable array with allocatable length

   ! ARRAY DELIMITERS
   !
   ! NOTE SET_ARGS(3f) DELIMITERS MUST MATCH WHAT IS USED IN GET_ARGS*(3f)
   !
   call set_args('-flen A,B,C -fixed X,Y --integers z --reals 111/222/333 -normal , --doubles | --complexs 0!0 --characters @')
   call get_args('integers',integers,delimiters='abcdefghijklmnopqrstuvwxyz')
   call get_args('reals',reals,delimiters='/')
   call get_args('doubles',doubles,delimiters='|')
   call get_args('complexs',complexs,delimiters='!')
   call get_args('normal',normal)
   call get_args('characters',characters,delimiters='@')

   call get_args_fixed_length('flen',flen)
   call get_args_fixed_size('fixed',fixed) ! fixed length and fixed size array

   write(*,'(g0,1x,a,*("[",g0,"]":,1x))')size(flen),'flen=',flen
   write(*,'(g0,1x,a,*("[",g0,"]":,1x))')size(characters),'characters=',characters
   write(*,'(g0,1x,a,*("[",g0,"]":,1x))')size(integers),'integers=',integers
   write(*,'(g0,1x,a,*("[",g0,"]":,1x))')size(reals),'reals=',reals
   write(*,'(g0,1x,a,*("[",g0,"]":,1x))')size(doubles),'doubles=',doubles
   write(*,'(g0,1x,a,*("[",g0,"]":,1x))')size(complexs),'complexs=',complexs
   write(*,'(g0,1x,a,*("[",g0,"]":,1x))')size(normal),'normal=',normal
   write(*,'(g0,1x,a,*("[",g0,"]":,1x))')size(fixed),'fixed=',fixed
end program demo7
!==================================================================================================================================
! EXAMPLE CALL
! demo7 -integers 1a2b3c4d5e6 -reals 1/2/3/4 -doubles '40|50|60' -complexs '2!3!4!5' --characters aaa@BBBB@c,d,e
! EXPECTED OUTPUT
! 3 characters=[aaa  ] [BBBB ] [c,d,e]
! 6 integers=[1] [2] [3] [4] [5] [6]
! 4 reals=[1.00000000] [2.00000000] [3.00000000] [4.00000000]
! 3 doubles=[40.000000000000000] [50.000000000000000] [60.000000000000000]
! 0 normal=[
! 2 complexs=[2.00000000] [3.00000000] [4.00000000] [5.00000000]
! 2 fixed=[X   ] [Y   ]
!==================================================================================================================================
