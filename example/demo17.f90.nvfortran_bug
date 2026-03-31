program demo17
!!  @(#) using the unnamed parameters as filenames
!!  For example, this should list the files in the current directory
!!
!!     demo17 *
!!
!!  Also demonstrates setting --help and --version text.
!!
!!     demo17 --help
!!     demo17 --version
!!     demo17 --usage
!!
use M_CLI2,  only : get_args
use M_CLI2,  only : sget, lget, iget, rget, dget, cget
use M_CLI2,  only : sgets, lgets, igets, rgets, dgets, cgets
use M_CLI2,  only : filenames=>unnamed
implicit none
type(character(len=*)),parameter    :: all='(*(g0))'
type(integer)                       :: indx

!! argument values to set
type(integer)                       :: i,j,k
type(real)                          :: x,y,z
type(character(len=:)),allocatable  :: title
type(logical)                       :: l,m,n
type(character(len=:)),allocatable  :: fnames(:)

   print all,'demo17: using the unnamed parameters as filenames'
   print all,'example: demo17 -x 100  * '

   call parse() !! Define and parse command line
   !! Get argument values 
   call get_args('x',x,'y',y,'z',z)
   call get_args('i',i,'j',j,'k',k)
   call get_args('l',l,'m',m,'n',n)
   title=sget('title')

   !! All done cracking the command line use the values in your program.
   print all,'x=',x ,' y=',y ,' z=',z
   print all,'i=',i ,' j=',j ,' k=',k
   print all,'l=',l ,' m=',m ,' n=',n
   print all,'title=',title

   !! The optional unnamed values on the command line are
   !! accumulated in the character array "UNNAMED" which was 
   !! renamed to "FILENAMES" on the use statement
   if(allocated(filenames))then
      if(size(filenames) > 0)then
         print all,'files:'
         print '(i6.6,1x,3a)',(indx,'[',filenames(indx),']',indx=1,size(filenames))
      endif
   endif

   ! alternate method, additionally can be used when desired result is numeric
   ! by using igets(3f), rgets(3f), ... instead of sgets(3f).

   fnames=sgets() ! also gets all the unnamed arguments
   if(size(fnames) > 0)then
      print all,'files:'
      print '(i6.6,1x,3a)',(indx,'[',fnames(indx),']',indx=1,size(fnames))
   endif

contains
subroutine parse()
!! Put everything to do with command parsing here 
!!
use M_CLI2,  only : set_args, set_mode
call set_mode([character(len=20) :: 'strict','ignorecase'])
! a single call to set_args can define the options and their defaults, set help
! text and version information, and crack command line.
call set_args(&
!! DEFINE COMMAND OPTIONS AND DEFAULT VALUES
' &
 -i 1 -j 2 -k 3     &
 -l F -m F -n F     &
 -x 1 -y 2 -z 3     &
 --title "my title" &
!! ## HELP TEXT ##
', [character(len=80) :: &
!12345678901234567890123456789012345678901234567890123456789012345678901234567890
'NAME                                                                            ', &
'   myprogram(1) - make all things possible                                      ', &
'SYNOPSIS                                                                        ', &
'   myprogram [-i NNN] [-j NNN] [-k NNN] [-l] [-m] [-n] ]                        ', &
'             [-x NNN.mm] [-y NNN.mm] [-z NNN.mm] [FILENAMES]                    ', &
'DESCRIPTION                                                                     ', &
'   myprogram(1) makes all things possible given stuff.                          ', &
'OPTIONS                                                                         ', &
'   -i,-j,-k   some integer values                                               ', &
'   -l,-m,-n   some logical values                                               ', &
'   -x,-y,-z   some real values                                                  ', &
'   --title    a string argument                                                 ', &
'   FILENAMES  any additional strings                                            ', &
'EXAMPLE                                                                         ', &
'   Typical usage:                                                               ', &
'                                                                                ', &
'     demo17 *.*                                                                 ', &
'                                                                                ', &
!! ## VERSION TEXT (with optional @(#) prefix for what(1) command) ##
'' ], [character(len=80) :: &
'@(#)PROGRAM:     demo17           >', &
'@(#)DESCRIPTION: My demo program  >', &
'@(#)VERSION:     1.0 20200115     >', &
'@(#)AUTHOR:      me, myself, and I>', &
'@(#)LICENSE:     Public Domain    >', &
'' ])

end subroutine parse

end program demo17
