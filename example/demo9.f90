program demo9
!> @(#) long and short names using --LONGNAME:SHORTNAME
!!
!!  When all keys have a long and short name "strict mode" is invoked where
!!  "-" is required for short names; and Boolean values may be bundled
!!  together. For example:
!!
!!    demo9 -XYZ
!!
use M_CLI2,  only : set_args, sget, rget, lget
implicit none
character(len=*),parameter :: all='(*(g0))'

   print *,'demo9: long and short names using --LONGNAME:SHORTNAME'

   call set_args('    &
   & --length:l 10    &
   & --height:h 12.45 &
   & --switchX:X F    &
   & --switchY:Y F    &
   & --switchZ:Z F    &
   & --title:T "my title"')
   print all,'--length or -l .... ',rget('length')
   print all,'--height or -h .... ',rget('height')
   print all,'--switchX or -X ... ',lget('switchX')
   print all,'--switchY or -Y ... ',lget('switchY')
   print all,'--switchZ or -Z ... ',lget('switchZ')
   print all,'--title or -T ..... ',sget('title')
end program demo9
