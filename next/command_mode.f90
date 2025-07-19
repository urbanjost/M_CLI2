program demo_non_commandline
! using the command as a config file or shell instead of for command line
use M_CLI2,  only : set_args, get_args, specified
use M_CLI2,  only : remaining, unnamed, args
use M_CLI2,  only : rget, sget
implicit none
character(len=1024)          :: line, iomsg
integer                      :: iostat,icheck
real                         :: x=0.0, y=0.0, z=0.0
character(len=:),allocatable :: verb, title, font
logical                      :: verbose=.false., quiet=.false., debug=.false.
integer                      :: iend
   title=' '
   font='roman'
   do
      write(*,'(a)',advance='no')'Enter command:'
      read(*,'(a)',iostat=iostat,iomsg=iomsg)line
      if(iostat.ne.0)write(*,'(a)')trim(iomsg)
      if(iostat.ne.0)cycle
      ! get first word as verb
      line=adjustl(line)
      iend=index(line,' ')
      if(iend.eq.0)iend=len(line)
      verb=line(:iend)
      line=line(iend:)
      ! process command 
      select case(verb)
      case('title')
        call set_args('--font:f "roman" --',string=trim(line),ierr=icheck)
        call check()
        if(icheck.ne.0)cycle
        if(specified('font'))font=sget('font')
        title=remaining
      case('label')
        call set_args('--font:f "roman" ',string=trim(line),ierr=icheck)
        call check()
        if(icheck.ne.0)cycle
        if(specified('font'))font=sget('font')
        title=remaining
      case('quit')
        exit
      case('position')
        call set_args('-x 0 -y 0 -z 0' ,string=trim(line),ierr=icheck)
        call check()
        if(icheck.ne.0)cycle
        if(specified('x'))x=rget('x')
        if(specified('y'))y=rget('y')
        if(specified('z'))z=rget('z')
        !call get_args('x',x,'y',y,'z',z)
      case default
        write(*,*)'unknown verb. commands are:'
        write(*,*)'   title [--font|-f font] TITLE'
        write(*,*)'   position -x XVAL -y YVAL -z ZVAL'
        write(*,*)'   quit'
        cycle
      end select
      write(*,*)repeat('-',80)
      write(*,*)'LINE=',trim(line)
      write(*,*)'REMAINING=',remaining
      write(*,*)'UNNAMED=',unnamed
      write(*,*)'ARGS=',args
      ! all done cracking the command line; use the values in your program.
      write(*,'(*(g0,1x))')'x=',x,'y=',y,'z=',z
      write(*,'(*(g0,1x))')'title=',title
      write(*,'(*(g0,1x))')'font=',font
      write(*,*)repeat('-',80)
   enddo
contains 
subroutine check()
   if(icheck.ne.0)then
       write(*,*)'ERROR',icheck
   endif
end subroutine check

end program demo_non_commandline
