program basic
!! CHARACTER
!! OS shells typically process quoted strings and remove one level of quoting
!! This parser knows if a value is supposed to be a string because the 
!! prototype definition requires a string be supplied with double quotes when
!! defined. So it the string the program gets does not have its first character
!! as a double-quote the entire string is quoted. But if not, it leaves the
!! string as-is and assumes it is suitable for use as NAMELIST input. so to
!! pass an array of string values you need to enter something like:
!!
!!    ./demo7 -arr '"ONE","TWO","THREE"'
!!
!! unless the NOQUOTE=.TRUE. is used, in which case a list of words with no
!! spaces or commas can simply be
!!
!!    ./demo7 -arr ONE,TWO,THREE
!!
!! for single values if you pass in the double-quotes make sure you follow the
!! NAMELIST rules. For example, both of these should set X to A"B 
!!
!!    ./demo7 -x 'A"B'
!!    ./demo7 -x '"A""B"' ! you supplies the quotes so internal double-quotes are doubled
!!
!! Since NAMELIST requires CHARACTER variables to be allocated, you must declare the
!! variables of sufficient length or the values will be truncated.
!!

use M_CLI2,  only : commandline, check_commandline
implicit none
character(len=:),allocatable :: readme ! stores updated namelist
character(len=256)           :: message
integer                      :: ios
character(len=10)            :: x, y, z, arr(3)
character(len=:),allocatable :: allo
namelist /args/ x, y, z, arr, allo
integer                      :: maxlen, leni, i

   ! find length of longest argument and allocate a CHARACTER variable
   ! to be big enough to hold that so it will not be truncated
   maxlen=0
   do i=1,command_argument_count()
      call get_command_argument(i,length=leni)
      maxlen=max(maxlen,leni)
   enddo
   leni=max(leni,len("Allocated")) ! longest of my default value and longest argument on command line
   allocate(character(len=leni) :: allo)
   !! initialize arr(3) to blanks using NAMELIST repeat format
   readme=commandline('-x "A" -y "B" -z "C" -arr 3*" " -allo "Allocated"',noquote=.true.)
   read(readme,nml=args,iostat=ios,iomsg=message)
   call check_commandline(ios,message)
   allo=trim(allo)
   write(*,'(*("[",g0,"]":))')x,y,z,arr,allo
end program basic
