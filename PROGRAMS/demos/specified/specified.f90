          program demo_specified
          use M_CLI2,  only : set_args, get_args, specified
          implicit none
          ! DEFINE ARGS
          character(len=:),allocatable   :: title

          ! EQUIVALENCING TWO VALUES
          integer                        :: flag,f
          equivalence (flag,f)

          ! POINTER FOR TWO VALUES
          integer,target,allocatable     :: ints(:)
          integer,pointer                :: i(:)

          ! REALLY DO NOT NEED TO USE EQUIVALENCE OR POINTER IF DO NOT SPECIFY BOTH NAMES ON COMMAND LINE
          real,allocatable               :: twonames(:)

          integer :: longest

          ! IT IS A BAD IDEA TO NOT HAVE THE SAME DEFAULT VALUE FOR ALIASED NAMES
             call set_args(' -title "my title" -flag 1 -f 1 -ints 1,2,3 -i 1,2,3 -twonames 11.3 -T 11.3')
          ! ASSIGN VALUES TO ELEMENTS
             call get_args('title',title)

             ! if equivalenced, call the long name and then only call the short name
             ! if the short name was present on the command line
             ! WITH EQUIVALENCE
             call get_args('flag',flag); if(specified('f'))call get_args('f',f)
             ! WITH POINTER
             call get_args('ints',ints); i=>ints;if(specified('i'))call get_args('i',ints)
             ! WITHOUT EQUIVALENCE OR POINTER
             call get_args('twonames',twonames);if(specified('T'))call get_args('T',twonames)

             ! IF YOU WANT TO KNOW IF GROUPS OF PARAMETERS WERE SPECIFIED USE ANY(3f) and ALL(3f)
             longest=len('twonames')
             ! gfortran bug?
             !write(*,*)specified([character(len=longest) :: 'twonames','T'])
             !write(*,*)'ANY:',any(specified([character(len=longest) :: 'twonames','T']))
             !write(*,*)'ALL:',all(specified([character(len=longest) :: 'twonames','T']))
             write(*,*)specified(['twonames','T       '])
             write(*,*)'ANY:',any(specified(['twonames','T       ']))
             write(*,*)'ALL:',all(specified(['twonames','T       ']))

          ! USE VALUES
             write(*,*)'title=',title
             write(*,*)'flag=',flag,' f=',f
             write(*,*)'ints=',ints,' i=',i
             write(*,*)'twonames=',twonames
          end program demo_specified
