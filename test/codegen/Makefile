FC     := gfortran
LINK   := gfortran
FFLAGS := -std=f2008 -fcheck=all -Wall -Wno-conversion
SUFFIX ?= 

RANDOMEXT := i1 i2 i4 i8 r4 r8 c8 c16 str
RANDOMSRC := $(RANDOMEXT:%=random%.f90)
RANDOMOBJ := $(RANDOMEXT:%=random%.o)

GENDATASEQOBJ := $(RANDOMOBJ) randutil.o gendataseq$(SUFFIX).o
GENDATADIRECTOBJ := $(RANDOMOBJ) randutil.o gendatadirect$(SUFFIX).o

JGENSRC := jwrite.jl jread.jl jskip.jl jfread.jl
FGENSRC := fdecl.f90 fwrite.f90

gendataseq: gendataseq$(SUFFIX).x
gendatadirect: gendatadirect$(SUFFIX).x

gendataseq$(SUFFIX).x: $(GENDATASEQOBJ)
	$(LINK) -o $@ $+

gendatadirect$(SUFFIX).x: $(GENDATADIRECTOBJ)
	$(LINK) -o $@ $+

gendataseq$(SUFFIX).o: gendataseq.F90 $(FGENSRC)
	$(FC) $(FFLAGS) $(XFLAGS) -c -o $@ $<

gendatadirect$(SUFFIX).o: gendatadirect.F90
	$(FC) $(FFLAGS) $(XFLAGS) -c -o $@ $<

$(RANDOMSRC): .random-stamp

.random-stamp: genrandom.jl random.ftl ftl-expand
	julia --startup-file=no genrandom.jl
	touch $@

$(RANDOMOBJ): randutil.mod

$(FGENSRC) $(JGENSRC): .code-stamp

.code-stamp: gencode.jl
	julia --startup-file=no gencode.jl
	touch $@

%.o: %.f90
	$(FC) $(FFLAGS) -c -o $@ $<

%.mod: %.o
	@true

clean:
	rm -f *.x *.o *.mod .*-stamp $(JGENSRC) $(FGENSRC) $(RANDOMSRC)
