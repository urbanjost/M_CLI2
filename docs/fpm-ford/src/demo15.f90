program demo15
!> @(#) strict mode
!!
!! In strict mode short single-character names may be bundled but it is
!! required that a single dash is used, where normally single and double
!! dashes are equivalent.
!!
!!     demo15 -o -t -x
!!     demo15 -otx
!!     demo15 -xto      
!!
!! Only Boolean keynames may be bundled together
!!
use M_CLI2,  only : set_args, lget, set_mode
implicit none
character(len=*),parameter :: all='(*(g0))'
   call set_mode('strict')
   call set_args(' -o F -t F -x F --ox F')
   print all,'o=',lget('o'),' t=',lget('t'),' x=',lget('x'),' ox=',lget('ox')
end program demo15
