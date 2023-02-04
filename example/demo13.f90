program demo13
!> @(#) underdash mode
!! Any dash in a key name is treated as an underscore
!! when underdash mode is on 
!!
!!     demo13 --switch-X
!!     demo13 --switch_X
!!
!! are equivalent when this mode is on
!!
use M_CLI2,  only : set_args, lget, set_mode
implicit none
character(len=*),parameter :: all='(*(g0))'

   print *,'demo13: underdash mode'

   call set_mode('underdash')
   call set_args(' --switch_X:X F --switch-Y:Y F ')
   print all,'--switch_X or -X ... ',lget('switch_X')
   print all,'--switch_Y or -Y ... ',lget('switch_Y')
end program demo13
