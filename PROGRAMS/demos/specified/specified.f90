           program demo_specified
           use M_CLI2,  only : set_args, get_args, specified
           implicit none
           ! DEFINE ARGS
           character(len=:),allocatable   :: title
           integer                        :: flag,f
           equivalence (flag,f)
              call set_args(' -title "my title" -flag 1 -f 1')
           ! ASSIGN VALUES TO ELEMENTS
              call get_args('title',title)

              ! if equivalenced, call the long name and then only call the short name
              ! if the short name was present on the command line
              call get_args('flag',flag)
              if(specified('f'))call get_args('f',f)

           ! USE VALUES
              write(*,*)'title=',title
              write(*,*)'flag=',flag,' f=',f
           end program demo_specified
