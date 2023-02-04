     program demo_specified
     use M_CLI2,  only : set_args, get_args, specified
     implicit none
     ! DEFINE ARGS
     integer                 :: flag
     integer,allocatable     :: ints(:)
     real,allocatable        :: two_names(:)

     ! IT IS A BAD IDEA TO NOT HAVE THE SAME DEFAULT VALUE FOR ALIASED
     ! NAMES BUT CURRENTLY YOU STILL SPECIFY THEM
      call set_args('&
         & --flag 1 -f 1 &
         & --ints 1,2,3 -i 1,2,3 &
         & --two_names 11.3 -T 11.3')

     ! ASSIGN VALUES TO ELEMENTS CONDITIONALLY CALLING WITH SHORT NAME
      call get_args('flag',flag)
      if(specified('f'))call get_args('f',flag)
      call get_args('ints',ints)
      if(specified('i'))call get_args('i',ints)
      call get_args('two_names',two_names)
      if(specified('T'))call get_args('T',two_names)

      ! IF YOU WANT TO KNOW IF GROUPS OF PARAMETERS WERE SPECIFIED USE
      ! ANY(3f) and ALL(3f)
      write(*,*)specified(['two_names','T        '])
      write(*,*)'ANY:',any(specified(['two_names','T        ']))
      write(*,*)'ALL:',all(specified(['two_names','T        ']))

      ! FOR MUTUALLY EXCLUSIVE
      if (all(specified(['two_names','T        '])))then
          write(*,*)'You specified both names -T and -two_names'
      endif

      ! FOR REQUIRED PARAMETER
      if (.not.any(specified(['two_names','T        '])))then
          write(*,*)'You must specify -T or -two_names'
      endif
      ! USE VALUES
        write(*,*)'flag=',flag
        write(*,*)'ints=',ints
        write(*,*)'two_names=',two_names
      end program demo_specified
