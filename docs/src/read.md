# Reading Data

```@docs
read
read!
@fread
```

## Examples

The following examples show how to write Julia code that corresponds to
certain Fortran `READ` statements. The Julia code assumes that `f` refers
to an opened `FortranFile` in sequential access mode, while the Fortran
code assumes that `lun` refers to a logical unit number for a connected file.

For direct access mode, each `read` call additionally needs to specify the
number of the record to read, by using the `rec` keyword argument.
E.g. to read the first record, use `read(f, rec=1, ...)`.

The `@fread` macro can be used if the size of data to be read from a record
depends on earlier data from the same record. See example below.


#### Reading a single scalar

```julia
x = read(f, Float64)
```
corresponds to
```fortran
real(kind=real64)::x
read(lun) x
```

#### Reading a 1D array

```julia
vector = read(f, (Float64,10))       # read into a new array
vector = zeros(10); read!(f, vector)  # read into pre-existing array
```
corresponds to (Modern Fortran style)
```fortran
real(kind=real64),dimension(10)::vector
read(lun) vector
```
and to (Fortran77 style)
```fortran
integer::i
real(kind=real64),dimension(10)::vector
read(lun) (vector(i), i=1,10)
```


#### Reading a 2D array

```julia
matrix = read(f, (Float64,10,10))      # read into a new array
matrix = read(f, (Float64,(10,10)))    # alternative syntax
matrix = zeros(10,10); read!(f, matrix) # read into existing array

```
corresponds to
```fortran
real(kind=real64),dimension(10,10)::matrix
read(lun) matrix
```

#### Reading a character string

```julia
fstr = read(f, FString{20})
```
corresponds to
```fortran
character(len=20)::fstr
read(lun) fstr
```

#### Reading a record with multiple data

```julia
i, strings, zmatrix = read(f, Int32, (Fstring{20},10), (ComplexF64,10,10))
```
corresponds to
```fortran
integer(kind=int32)::i
character(len=20),dimension(10)::strings
complex(kind=real64),dimension(10,10)::zmatrix
read(lun) i,strings,matrix
```

#### Reading a record where the size is not known ahead

```julia
@fread f n::Int32 vector::(Float64,n)
```
corresponds to
```fortran
integer(kind=int32)::n,i
read(kind=real64),dimension(*)::vector ! assume already allocated
read(lun) n,(vector(i),i=1,n)
```

#### Skipping over a record

```julia
read(f)
```
corresponds to
```fortran
read(lun)
```

