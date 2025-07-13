#@(#) Makefile started by makeout(1) 2020-01-14 01:11:41
NULL=
#$(NULL)
PROGFILES = \
 ../example/demo1.f90 \
 ../example/demo2.f90 \
 ../example/demo3.f90 \
 ../example/demo4.f90 \
 ../example/demo5.f90 \
 ../example/demo6.f90 \
 ../example/demo7.f90 \
 ../example/demo8.f90 \
 ../example/demo9.f90 \
 ../example/demo11.f90 \
  \
 ../example/demo12.f90 \
 ../example/demo13.f90 \
 ../example/demo14.f90 \
 ../example/demo15.f90 \
 ../example/demo16.f90 \
 ../example/manually_test_bundling.f90 \
$(NULL)
# ../example/demo17.f90
#
TESTFILES = \
 ../test/test_suite_M_CLI2.f90 \
 ../test/test_ignorecase.f90 \
 ../test/test_lastonly.f90 \
 ../test/test_strict.f90 \
$(NULL)
TPROG = ${TESTFILES:.f90=}
PROG = ${PROGFILES:.f90=}
SRCS = M_CLI2.f90 
OBJS = M_CLI2.o 
LIBRARY := libM_CLI2.a
COMPILER=AAAAAAAAA
LIB := M_CLI2
# platform-specific values you will probably change
#
gfortran: F90=gfortran
gfortran: FCFLAGS := -Wall -Wextra -Wimplicit-interface -fPIC -fmax-errors=1 \
          -g -O -fcheck=bounds -fcheck=array-temps -fbacktrace -fcoarray=single
gfortran: FCFLAGS := -g -O -std=f2018 -fPIC -Wno-maybe-uninitialized -Wno-uninitialized
gfortran_install: COMPILER=gfortran
gfortran: all
	@echo built with $(F90)

nvfortran: F90=nvfortran
nvfortran: FCFLAGS := -Minform=inform -Mbackslash -traceback
nvfortran_install: COMPILER=nvfortran
nvfortran: all
	@echo built with $(F90)

ifort: F90=ifort
ifort: FCFLAGS := -warn all -traceback -fpic
ifort_install: COMPILER=ifort
ifort: all
	@echo built with $(F90)

ifx: F90=ifx
ifx: FCFLAGS := -warn all -traceback -fpic
ifx: COMPILER=ifx
ifx: all
	@echo built with $(F90)

nagfor: F90=nagfor
nagfor: FCFLAGS := -C all
nagfor_install: COMPILER=nagfor
nagfor: all
	@echo built with $(F90)

LIBS := 
LDFLAGS := 
all: $(PROG) $(TPROG)
	@echo "That's All Folks! Enter \"make help\" for more options"
$(PROG): $(LIBRARY)
	-$(F90) $(LDFLAGS) $@.f90 -L. -l$(LIB) -o $@ 
$(TPROG): $(LIBRARY)
	-$(F90) $(LDFLAGS) $@.f90 -L. -l$(LIB) -o $@ 
$(LIBRARY): $(OBJS)
	$(AR) $(ARFLAGS) $@ $^
gfortran_install ifort_install ifx_install: $(OBJS)
	# very Linux/Unix/BSD/.. specific and just for $(COMPILER)
	mkdir -p lib$(COMPILER)/
	# static library and modules
	$(AR) $(ARFLAGS) lib$(COMPILER)/libM_CLI2.a $^
	cp *.mod lib$(COMPILER)/
	# shared library
	#
	[ "$(COMPILER)" = 'gfortran' ] && $(COMPILER) -shared -Wl,-soname,lib$(LIB).so.1 -o lib$(COMPILER)/lib$(LIB).so.1 $(OBJS)|| echo G
	[ "$(COMPILER)" = 'ifort' ]    && $(COMPILER) -shared                            -o lib$(COMPILER)/lib$(LIB).so.1 $(OBJS)|| echo I
	[ "$(COMPILER)" = 'ifx' ]    && $(COMPILER) -shared                            -o lib$(COMPILER)/lib$(LIB).so.1 $(OBJS)|| echo I

	cd lib$(COMPILER) && ln -sf lib$(LIB).so.1 lib$(LIB).so 
	@echo example static build

	[ "$(COMPILER)" = 'gfortran' ] && $(COMPILER) -static sample/hello.f90 -Llib$(COMPILER) -lM_CLI2 -o hello_static || echo G
	[ "$(COMPILER)" = 'ifort' ]    && $(COMPILER) -static sample/hello.f90 -Llib$(COMPILER) -lM_CLI2 -o hello_static || echo I
	[ "$(COMPILER)" = 'ifx' ]    && $(COMPILER) -static sample/hello.f90 -Llib$(COMPILER) -lM_CLI2 -o hello_static || echo I

	./hello_static

	@echo example shared build
	$(COMPILER) sample/hello.f90 -Llib$(COMPILER) -lM_CLI2 -o hello_shared
	# put directory in load path and run using shared version
	env LD_LIBRARY_PATH=lib$(COMPILER)/:${LD_LIBRARY_PATH} ./hello_shared
	# show one is static and other needs shared library
	-env LD_LIBRARY_PATH=lib$(COMPILER)/:${LD_LIBRARY_PATH} ldd hello_shared hello_static

.SUFFIXES: $(SUFFIXES) .f90 .F90 
.f90.o:
	$(F90) $(FCFLAGS) -c $<
.F90.o:
	$(F90) $(FCFLAGS) -c $<
.PHONY: help
help:
	: ##############################################################################
	: # make COMPILER [OPTION]  -- build M_CLI2 module. Default is gfortran        #
	: # COMPILER may be gfortran | nvfortran | ifort |ifx | nagfor                 #
	: # OPTIONS:                                                                   #
	: # run               -- run manpage demo programs                             #
	: # test              -- run test programs                                     #
	: # gfortran_install  -- place static and shared library in ./libgfortran      #
	: # ifort_install     -- place static and shared library in ./libifort         #
	: # ifx_install       -- place static and shared library in ./libifx           #
	: ##############################################################################
	: # man               -- show all manpages as text if infrastructure present   #
	: # ship              -- rebuild archive files of manpages                     #
	: # clean             -- clean directory of built files                        #
	: # help              -- display this text                                     #
	: # doxygen           -- run doxygen(1) if you have it                         #
	: # ford              -- run ford(1) if you have it                            #
	: ##############################################################################
	: # Examples (do a "make clean" if change compilers):                          #
	: #    make clean    # make sure previous artifacts are removed                #
	: #    make gfortran # build using gfortran(1) compiler                        #
	: #    make clean    # make sure previous artifacts are removed                #
	: #    make ifx run  # build using ifx(1) compiler                             #
	: # clean up and make shared libraries and install them in local subdirectories#
	: #    make clean gfortran gfortran_install # create libgfortran/              #
	: #    make clean ifx ifx_install # create libifx/                             #
	: ##############################################################################

.PHONY: clean
clean:
	rm -f $(PROG) $(CPROG) $(TPROG) $(OBJS) *.a *.mod *.o hello_shared hello_static
.PHONY: run
run: $(PROG)
	# run everything
	#echo $? |xargs -n 1|xargs -iXX time XX 2>&1
	set +x;echo $? |xargs -n 1|xargs -iXX env XX 2>&1
.PHONY: doxygen
doxygen: 
	doxygen dox.in
.PHONY: ford
ford: 
	cd ..;ford ford.md

.PHONY: test
test: $(TPROG)
	# run tests
	echo $? | xargs -n 1  
	echo $? | xargs -n 1  |(set +x;xargs -iXX env XX 2>&1)

.PHONY: man
man:
	@mandb ../man 1>&2
	: INDEX OF MANPAGES TOPICS
	@env MANPATH=../man MANWIDTH=256 man -k .|col -b
	: MANPAGES
	@env MANPATH=../man MANWIDTH=80  man -Tutf8 --regex '.*'|col -b
	: SPELLING
	@env MANPATH=../man MANWIDTH=80  man -Tutf8 --regex '.*'|col -b|spell|xargs -n 5|column -t

.PHONY: ship
ship:
	: make easily distributed archive files of manpages
	mkdir -p ../docs
	cd ../man/man3;\
	   gzip *.3m_cli2;\
	   zip -r ../../docs/manpages.zip *gz;\
	   tar cvfz ../../docs/manpages.tgz *gz;\
	   gunzip *.3m_cli2.gz
