           program demo_get_args
           use M_CLI2,  only : filenames=>unnamed, set_args, get_args, unnamed
           implicit none
           integer                      :: i
           integer,parameter            :: dp=kind(0.0d0)
           ! DEFINE ARGS
           real                         :: x, y, z
           real                         :: p(3)
           character(len=:),allocatable :: title
           logical                      :: l, lbig
           ! DEFINE AND PARSE (TO SET INITIAL VALUES) COMMAND LINE
           !   o only quote strings
           !   o set all logical values to F or T.
           call set_args(' -x 1 -y 2 -z 3 -p -1,-2,-3 --title "my title" &
                   & -l F -L F  &
                   & --label " " &
                   & ')
           ! ASSIGN VALUES TO ELEMENTS
           ! SCALARS
           call get_args('x',x)
           call get_args('y',y)
           call get_args('z',z)
           call get_args('l',l)
           call get_args('L',lbig)
           ! ALLOCATABLE STRING
           call get_args('title',title)
           ! NON-ALLOCATABLE ARRAYS
           ! for non-allocatable arrays pass size
           call get_args('p',p,size(p))
           ! USE VALUES
           write(*,*)'x=',x
           write(*,*)'y=',y
           write(*,*)'z=',z
           write(*,*)'p=',p
           write(*,*)'title=',title
           write(*,*)'l=',l
           write(*,*)'L=',lbig
           if(size(filenames).gt.0)then
              write(*,'(i6.6,3a)')(i,'[',filenames(i),']',i=1,size(filenames))
           endif
           if(size(unnamed).gt.0)then
              write (*,'(a)')'files:'
              write (*,'(i6.6,3a)') (i,'[',unnamed(i),']',i=1,size(unnamed))
           endif
           end program demo_get_args
