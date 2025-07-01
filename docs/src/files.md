# Files

## Terminology

When opening a file in Fortran, you can specify its *access mode*.
The default and most commonly used mode is *sequential access*.
This package additionally supports *direct access* mode.
(If the Fortran program uses *stream access* mode, then the file
contains plain binary data, which can be easily read with Julia's
built-in facilities.)

In Fortran, files are organized into *records*. Each `READ` or `WRITE`
statement in Fortran processes a complete record. This Julia package
emulates this behavior, i.e. each call to `read` or `write` will process
a whole record.

In sequential access mode, records can only be accessed sequentially,
but they can be of variable length. The length of a record is determined
by the amount of data passed to the `WRITE` statement. The length of
the record is also written to the file, encoded in *record markers* which
preceed and follow the record. Unfortunately, Fortran compilers have used
various ways to encode the record markers (the following is from personal
recollection and may be incorrect):
* g77 used 4 bytes, so that records could be no longer than 2 GiB.
* ifort uses 4 bytes, and uses the sign bit to signal that more data will follow.
  That is, the record is split into *subrecords*, where each subrecord has its
  own record markers. For records smaller than 2 GiB, this is compatible to g77.
* gfortran 4.0 and 4.1 offered 8-byte record markers as an alternative to
  g77-style record markers, and used them by default (at least on 64-bit systems).
* gfortran 4.2 introduced ifort-compatible record markers. These are now
  the default.
All these kinds of record markers are supported by this package.

In direct access mode, all records have the same, fixed size. This record size
must be specified when opening the file. Records can be accessed in random
order, by specifying the number of the record to be read/written in each
`READ` or `WRITE` statement.  Currently it is assumed that records are stored
in the file without any header or record marker.  This is compatible with the
standard behaviour of gfortran and ifort.


## Opening files

To open a file which contains Fortran unformatted data,
use one of the following methods:

```@docs
FortranFile
```

See [Reading Data](@ref) and [Writing Data](@ref) for how to
read or write data to `FortranFile`s.


## Other functions on `FortranFile`s

To close the file, use the standard Julia `close` function.

To test for EOF, use the standard Julia `eof` function.

The following functions are provided to emulate certain Fortran I/O statements:
```@docs
seekstart
```


## Examples

The following examples show how to write Julia code that corresponds to
certain Fortran `OPEN` statements.

#### Opening a file read-only

```julia
f = FortranFile("data.bin")
```
corresponds to
```fortran
integer::lun
open(newunit=lun, file="data.bin", form="unformatted", action="read", status="old")
```

#### Opening a file for writing

```julia
f = FortranFile("data.bin", "w")
```
corresponds to
```fortran
integer::lun
open(newunit=lun, file="data.bin", form="unformatted", action="write", status="replace")
```

#### Opening a file for reading and writing in append mode

```julia
f = FortranFile("data.bin", "a+")
```
probably corresponds to
```fortran
integer::lun
open(newunit=lun, file="data.bin", form="unformatted", action="readwrite", position="append", status="unknown")
```

#### Opening a file read-only in direct access mode

```julia
f = FortranFile("data.bin", "r", access="direct", recl=640)
```
for reading a file containing 640-byte records, and corresponds to
```fortran
integer::lun
open(newunit=lun, file="data.bin", form="unformatted", action="read", status="old", access="direct", recl=640)
```
if compiled with gfortran; ifort measures `recl` not in bytes, but in 4-byte longwords, unless the
compiler switch `-assume byterecl` is used.

