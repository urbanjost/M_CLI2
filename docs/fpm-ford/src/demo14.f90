program demo14
!> @(#) ignorecase mode
!!
!! long keynames are internally converted to lowercase
!! when ignorecase mode is on these are equivalent
!!
!!     demo14 --longName
!!     demo14 --longname
!!     demo14 --LongName
!!
!! Values and short names remain case-sensitive
!!
use M_CLI2,  only : set_args, lget, set_mode
implicit none
character(len=*),parameter :: all='(*(g0))'

   print *,'demo14: ignorecase mode'

   call set_mode('ignorecase')
   call set_args(' --longName:N F ')
   print all,'--longName or -N ... ',lget('longName')
end program demo14
