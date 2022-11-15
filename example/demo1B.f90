program demo1B
use M_CLI2, only : set_args, lget, rget, sget, igets
implicit none
real                          :: sum
integer,allocatable           :: p(:)
character(len=:),allocatable  :: title
   !
   ! Define command and default values and parse supplied command line options
   call set_args('-x 1 -y 2.0 -z 3.5e0 -p 11,-22,33 --title "my title" -B F',&

       & help_text=[character(len=80):: &

       & 'NAME                                                             ',&
       & '   show(1) -- my little show and tell                            ',&
       & 'DESCRIPTION                                                      ',&
       & '   Lets create an argument.                                      ',&
       & 'OPTIONS                                                          ',&
       & '    x,y,z    some REAL arguments                                 ',&
       & '    p        make a point                                        ',&
       & '    title    duke, marquis, honorable, esquire, etc.             ',&
       & '    B        to be or not to be                                  ',&
       & ''], &

       & version_text=[character(len=20):: &
       & 'version 0.0.0'] )
   !
   ! Get values using convenience functions
   sum=rget('x') + rget('y') + rget('z')
   title=sget('title')
   p=igets('p')
   !
   ! use the values
   if (lget('B'))then
      write(*,*)'to be'
   else
      write(*,*)'not to be'
   endif
   write(*,*)sum,p,title
end program demo1B
