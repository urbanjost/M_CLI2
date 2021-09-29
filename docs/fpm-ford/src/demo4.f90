program demo4
!!  _COMPLEX_ type values
use M_CLI2,  only : set_args, get_args, get_args_fixed_size
implicit none
complex                      :: x, y, z   ! scalars
complex,allocatable          :: aarr(:)   ! allocatable array
complex                      :: three(3)  ! fixed-size array

! formats to pretty-print a complex value and small complex vector
character(len=*),parameter   :: form='("(",g0,",",g0,"i)":,1x)'
character(len=*),parameter   :: forms='(*("(",g0,",",g0,"i)":,",",1x))'

   ! COMPLEX VALUES
   !
   !  o parenthesis are optional and are ignored in complex values.
   !
   !  o base#value is acceptable for base 2 to 32 for whole numbers,
   !    which is why "i" is not allowed as a suffix on imaginary values
   !    (because some bases include "i" as a digit).
   !
   !  o normally arrays are allocatable. if a fixed size array is used
   !    call get_args_fixed_size(3f) and all the values must be
   !    specified. This is useful when you have something that requires
   !    a specific number of values. Perhaps a point in space must always
   !    have three values, for example.
   !
   !  o default delimiters are whitespace, comma and colon. Note that
   !    whitespace delimiters should not be used in the definition,
   !    but are OK on command input if the entire parameter value is
   !    quoted. Using space delimiters in the prototype definition is
   !    not supported (but works) and requires that the value be quoted
   !    on input in common shells. Adjacent delimiters are treated as
   !    a single delimiter.
   !
   call set_args('-x (1,2) -y 10,20 -z (2#111,16#-AB) -three 1,2,3,4,5,6 -aarr 111::222,333::444')
   call get_args('x',x)
   call get_args('y',y)
   call get_args('z',z)
   call get_args_fixed_size('three',three)
   call get_args('aarr',aarr)
   write(*,form)x,y,z, x+y+z
   write(*,forms)three
   write(*,forms)aarr
end program demo4
!
! expected output:
!
! (1.00000000,2.00000000i)
! (10.0000000,20.0000000i)
! (7.00000000,-171.000000i)
! (18.0000000,-149.000000i)
! (1.00000000,2.00000000i), (3.00000000,4.00000000i), (5.00000000,6.00000000i)
! (111.000000,222.000000i), (333.000000,444.000000i)
