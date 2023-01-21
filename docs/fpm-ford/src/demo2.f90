program demo2
!!  putting everything including **help** and **version** information
!!  into a contained procedure.
use M_CLI2,  only : unnamed
implicit none
integer            :: i

!! DEFINE "ARGS" VALUES
integer            :: x, y, z
real               :: point(3)
character(len=80)  :: title
logical            :: l, l_

   call parse() !! DEFINE AND PARSE COMMAND LINE

   !! ALL DONE CRACKING THE COMMAND LINE USE THE VALUES IN YOUR PROGRAM.
   write(*,*)x+y+z
   write(*,*)point*2
   write(*,*)title
   write(*,*)l,l_

   !! THE OPTIONAL UNNAMED VALUES ON THE COMMAND LINE ARE
   !! ACCUMULATED IN THE CHARACTER ARRAY "UNNAMED"
   if(size(unnamed) > 0)then
      write(*,'(a)')'files:'
      write(*,'(i6.6,3a)')(i,'[',unnamed(i),']',i=1,size(unnamed))
   endif

contains
   subroutine parse()
   !! PUT EVERYTHING TO DO WITH COMMAND PARSING HERE FOR CLARITY
   use M_CLI2,  only : set_args, get_args
   use M_CLI2,  only : get_args_fixed_size,get_args_fixed_length
   character(len=:),allocatable  :: help_text(:), version_text(:)

   !! DEFINE COMMAND PROTOTYPE
   !!  o All parameters   must be listed with a default value
   !!  o string values    must be double-quoted
   !!  o numeric lists    must be comma-delimited. No spaces are allowed
   !!  o long keynames    must be all lowercase

   character(len=*),parameter :: cmd='&
   & -x 1 -y 2 -z 3     &
   & --point -1,-2,-3   &
   & --title "my title" &
   & -l F -L F          &
   & '

      help_text=[character(len=80) :: &
         'NAME                                                    ', &
         '   myprocedure(1) - make all things possible            ', &
         'SYNOPSIS                                                ', &
         '   function myprocedure(stuff)                          ', &
         '   class(*) :: stuff                                    ', &
         'DESCRIPTION                                             ', &
         '   myprocedure(1) makes all things possible given STUFF ', &
         'OPTIONS                                                 ', &
         '   STUFF  things to do things to                        ', &
         'RETURNS                                                 ', &
         '   MYPROCEDURE  the answers you want                    ', &
         'EXAMPLE                                                 ', &
         '' ]

      version_text=[character(len=80) :: &
         '@(#)PROGRAM:     demo2            >', &
         '@(#)DESCRIPTION: My demo program  >', &
         '@(#)VERSION:     1.0 20200115     >', &
         '@(#)AUTHOR:      me, myself, and I>', &
         '@(#)LICENSE:     Public Domain    >', &
         '' ]

      call set_args(cmd, help_text, version_text)
      call get_args('x',x)
      call get_args('y',y)
      call get_args('z',z)
      call get_args_fixed_size('point',point)
      call get_args_fixed_length('title',title)
      call get_args('l',l)
      call get_args('L',l_)

   end subroutine parse

end program demo2
