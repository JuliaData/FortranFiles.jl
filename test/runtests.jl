using FortranFiles
using Test: @test, @testset, @test_throws
using Base.Iterators: product

include("test_macro_throws.jl")

using FortranFiles: RecordMarkerType, AccessMode, SequentialAccess, DirectAccess

# To test long records being split into subrecords, without needing
# test data files of several GB, define a custom RecordMarkerType with
# a short maximum subrecord length
const maxsubreclen = 2^15 - 9
const RECMRK4Bwssr = FortranFiles.WithSubrecords(maxsubreclen)
const RECMRK4Bwosr = FortranFiles.WithoutSubrecords{Int32}()
const nelem        = 73
const dareclen     = nelem*sizeof(ComplexF64)

# --- Definition of different types of record marker ---

struct RecordTypeTest
   rectyp :: Any
   desc   :: String
   target :: String
   tag    :: String
   fflags :: String
end

const rectyp_tests = [
   RecordTypeTest( DirectAccess, "fixed length (direct access)",
                   "gendatadirect", "DA", "" ),
   RecordTypeTest( RECMRK4Bwssr, "markers of 4-byte with short subrecords",
                   "gendataseq", "4Bshort", "-fmax-subrecord-length=$(maxsubreclen)" ),
   RecordTypeTest( RECMRK4B, "markers of 4-byte with default subrecords",
                   "gendataseq", "4Bdef", "" ),
   RecordTypeTest( RECMRK8B, "markers of 8-byte without subrecords",
                   "gendataseq", "8B", "-frecord-marker=8" ),
   RecordTypeTest( RECMRK4Bwosr, "markers of 4-byte without subrecords",
                   "gendataseq", "4Bdumb", "" )
   ]

# --- Definition of different byte order conversions ---

struct ByteOrderTest
   name   :: String
   tag    :: String
   fflags :: String
end

const byteorder_tests = [
   ByteOrderTest( "native",        "no",   "" ),
   ByteOrderTest( "little-endian", "LE", "-fconvert=little-endian" ),
   ByteOrderTest( "big-endian",    "BE", "-fconvert=big-endian" ),
   ]

# --- Generation of test data and Julia reading/writing code ---

function gendata(target, tag, fflags)
   `make -C codegen $target SUFFIX=_$tag XFLAGS=$fflags` |> run
   `codegen/$(target)_$(tag).x data_$(tag).bin` |> run
end

function genalldata(tests...)
   for test in product(tests...)
      tag = join( (t.tag for t in test), "_" )
      fflags = join( (t.fflags for t in test), " " )
      gendata(test[1].target, tag, fflags)
   end
   return nothing
end

if Sys.islinux()
   genalldata(rectyp_tests, byteorder_tests)

   include("codegen/jread.jl")
   include("codegen/jfread.jl")
   include("codegen/jskip.jl")
   include("codegen/jwrite.jl")
end

# --- Auxiliary functions ---

function cmpfiles(a::String, b::String)
   cmd = `cmp $a $b`
   try
      run(cmd)
      return true
   catch
      return false
   end
end

readdata(f::FortranFile{DirectAccess})  = _readdata(f, nelem)
freaddata(f::FortranFile{DirectAccess}) = _freaddata(f, nelem)
skipdata(f::FortranFile{DirectAccess})  = _readdata(f, 1)

function _readdata(f, n::Integer)
   vari1  = read(f, rec=1,  Array{Int8}(undef, n))
   @test typeof(vari1)==Array{Int8,1}
   @test sizeof(vari1)==sizeof(Int8)*n
   vari2  = read(f, rec=2,  Array{Int16}(undef, n))
   @test typeof(vari2)==Array{Int16,1}
   @test sizeof(vari2)==sizeof(Int16)*n
   vari4  = read(f, rec=3,  Array{Int32}(undef, n))
   @test typeof(vari4)==Array{Int32,1}
   @test sizeof(vari4)==sizeof(Int32)*n
   vari8  = read(f, rec=4,  Array{Int64}(undef, n))
   @test typeof(vari8)==Array{Int64,1}
   @test sizeof(vari8)==sizeof(Int64)*n
   varr4  = read(f, rec=11, Array{Float32}(undef, n))
   @test typeof(varr4)==Array{Float32,1}
   @test sizeof(varr4)==sizeof(Float32)*n
   varr8  = read(f, rec=12, Array{Float64}(undef, n))
   @test typeof(varr8)==Array{Float64,1}
   @test sizeof(varr8)==sizeof(Float64)*n
   varc8  = read(f, rec=21, Array{ComplexF32}(undef, n))
   @test typeof(varc8)==Array{ComplexF32,1}
   @test sizeof(varc8)==sizeof(ComplexF32)*n
   varc16 = read(f, rec=22, Array{ComplexF64}(undef, n))
   @test typeof(varc16)==Array{ComplexF64,1}
   @test sizeof(varc16)==sizeof(ComplexF64)*n
   varstr = read(f, rec=30,  Array{FString{11}}(undef, n))
   @test typeof(varstr)==Array{FString{11},1}
   @test sizeof(varstr)==sizeof(FString{11})*n
   return ( vari1, vari2, vari4, vari8, varr4, varr8, varc8, varc16, varstr )
end

function _freaddata(f, n::Integer)
   @fread f rec=1 vari1::Array{Int8}(undef, n)
   @test typeof(vari1)==Array{Int8,1}
   @test sizeof(vari1)==sizeof(Int8)*n
   @fread f rec=2 vari2::Array{Int16}(undef, n)
   @test typeof(vari2)==Array{Int16,1}
   @test sizeof(vari2)==sizeof(Int16)*n
   @fread f rec=3 vari4::Array{Int32}(undef, n)
   @test typeof(vari4)==Array{Int32,1}
   @test sizeof(vari4)==sizeof(Int32)*n
   @fread f rec=4 vari8::Array{Int64}(undef, n)
   @test typeof(vari8)==Array{Int64,1}
   @test sizeof(vari8)==sizeof(Int64)*n
   @fread f rec=11 varr4::Array{Float32}(undef, n)
   @test typeof(varr4)==Array{Float32,1}
   @test sizeof(varr4)==sizeof(Float32)*n
   @fread f rec=12 varr8::Array{Float64}(undef, n)
   @test typeof(varr8)==Array{Float64,1}
   @test sizeof(varr8)==sizeof(Float64)*n
   @fread f rec=21 varc8::Array{ComplexF32}(undef, n)
   @test typeof(varc8)==Array{ComplexF32,1}
   @test sizeof(varc8)==sizeof(ComplexF32)*n
   @fread f rec=22 varc16::Array{ComplexF64}(undef, n)
   @test typeof(varc16)==Array{ComplexF64,1}
   @test sizeof(varc16)==sizeof(ComplexF64)*n
   @fread f rec=30 varstr::Array{FString{11}}(undef, n)
   @test typeof(varstr)==Array{FString{11},1}
   @test sizeof(varstr)==sizeof(FString{11})*n
   return ( vari1, vari2, vari4, vari8, varr4, varr8, varc8, varc16, varstr )
end

function writedata(f::FortranFile{DirectAccess}, data)
   vari1, vari2, vari4, vari8, varr4, varr8, varc8, varc16, varstr = data
   nwritten = write(f, rec=1,  vari1)
   @test nwritten==sizeof(vari1)
   nwritten = write(f, rec=2,  vari2)
   @test nwritten==sizeof(vari2)
   nwritten = write(f, rec=3,  vari4)
   @test nwritten==sizeof(vari4)
   nwritten = write(f, rec=4,  vari8)
   @test nwritten==sizeof(vari8)
   nwritten = write(f, rec=11, varr4)
   @test nwritten==sizeof(varr4)
   nwritten = write(f, rec=12, varr8)
   @test nwritten==sizeof(varr8)
   nwritten = write(f, rec=21, varc8)
   @test nwritten==sizeof(varc8)
   nwritten = write(f, rec=22, varc16)
   @test nwritten==sizeof(varc16)
   nwritten = write(f, rec=30, varstr)
   @test nwritten==sizeof(varstr)
   # going back
   nwritten = write(f, rec=16, varc16)
   @test nwritten==sizeof(varc16)
   # overwriting
   nwritten = write(f, rec=16, varstr)
   @test nwritten==sizeof(varstr)
end


# --- TESTING STARTS HERE ---

@testset "Exceptions" begin
   @testset "Constructor" begin
      open(devnull, "w") do io
         # sequential access file with fixed-length records
         @test_throws FortranFilesError FortranFile(io, recl=80)
         # direct access file without record length
         @test_throws FortranFilesError FortranFile(io, access="direct")
         # unknown access mode
         @test_throws FortranFilesError FortranFile(io, access="stream")
         # unknown byte-order conversion
         @test_throws FortranFilesError FortranFile(io, convert="host")
      end
   end

   @testset "Writing" begin
      open(devnull, "w") do io
         # direct access files
         fdir = FortranFile(io, access="direct", recl=80)
         # no record number
         @test_throws FortranFilesError write(fdir, zeros(10))
         # write too much
         @test_throws FortranFilesError write(fdir, rec=1, zeros(11))

         # sequential access files
         for recmrk in (RECMRK4B,RECMRK4Bwosr)
            fseq = FortranFile(io, marker=recmrk)
            # with record number
            @test_throws MethodError write(fseq, rec=1, zeros(10))
            # inhomogeneous array, see PR#4
            inhomA = Integer[1, big(2)]
            @test_throws FortranFilesError write(fseq, inhomA)
         end
      end
   end

   @testset "Reading" begin
      let A=ones(10), B=2A
         # direct access files
         data = UInt8[]
         io = IOBuffer(data, write=true)
         fdir = FortranFile(io, access="direct", recl=80)
         write(fdir, rec=1, A)
         write(fdir, rec=2, B)
         close(fdir)
         io = IOBuffer(data)
         fdir = FortranFile(io, access="direct", recl=80)
         # no record number
         @test_throws FortranFilesError AA = read(fdir, (Float64, 10))
         # macro version
         @test_throws FortranFilesError @fread fdir AA::(Float64, 10)
         # read too much
         @test_throws FortranFilesError AA = read(fdir, rec=1, (Float64, 11))
         close(fdir)

         # sequential access files
         for recmrk in (RECMRK4B,RECMRK4Bwosr)
            data = UInt8[]
            io = IOBuffer(data, write=true)
            fseq = FortranFile(io, marker=recmrk)
            write(fseq, A)
            write(fseq, B)
            close(fseq)
            io = IOBuffer(data)
            fseq = FortranFile(io, marker=recmrk)
            # with record number
            @test_throws MethodError AA = read(fseq, rec=1, (Float64, 10))
            # macro version
            @test_throws FortranFilesError @fread fseq rec=1 AA::(Float64, 10)
            # read too much
            @test_throws Exception AA = read(fseq, (Float64, 11))
            close(fseq)
            # garbage data: wrong trailing record marker
            data = UInt8[]
            io = IOBuffer(data, write=true)
            write(io, UInt32(80), A, UInt32(40))
            close(io)
            io = IOBuffer(data)
            fseq = FortranFile(io, marker=recmrk)
            @test_throws Exception AA = read(fseq, (Float64, 10))
            close(fseq)
         end
      end
   end

   @testset "Macro syntax" begin
      @test_macro_throws ArgumentError eval(:(@fread f foo=1))
      @test_macro_throws ArgumentError eval(:(@fread f 10))
      @test_macro_throws ArgumentError eval(:(@fread f (Int,Int)))
   end
end

@testset "Strings" begin
   jstr = "Hello World!"
   N    = length(jstr)
   fstr = FString(N, jstr)
   @test typeof(fstr) == FString{N}
   @test trimstring(fstr) == jstr
   @test trimlen(fstr) == N
   @test trim(fstr) == fstr
   @test String(fstr) == jstr
   fstr80 = FString(80, jstr)
   @test typeof(fstr80) == FString{80}
   @test trimstring(fstr80) == jstr
   @test trimlen(fstr80) == N
   @test trim(fstr80) == fstr
   @test String(fstr80) == rpad(jstr, 80)
   fstr8 = FString(8, jstr)
   @test typeof(fstr8) == FString{8}
   @test trimstring(fstr8) == jstr[1:8]
   @test trimlen(fstr8) == 8
   @test trim(fstr8) == fstr8
   @test String(fstr8) == jstr[1:8]
   jstr = "Hällo Wörld!"
   @test_throws InexactError FString(80, jstr)
end

Sys.islinux() && @testset "Testing records with $(rectest.desc), $(botest.name) byte order" for rectest in rectyp_tests, botest in byteorder_tests
   local infile, outfile, data, data2
   tag = "$(rectest.tag)_$(botest.tag)"
   infilename  = "data_$(tag).bin"
   outfilename = "chck_$(tag).bin"

   @testset "Opening files" begin
      if isa(rectest.rectyp, RecordMarkerType)
         infile  = FortranFile(infilename, "r", marker = rectest.rectyp, convert = botest.name)
         @test infile.acctyp.recmrktyp == rectest.rectyp
         outfile = FortranFile(outfilename, "w", marker = rectest.rectyp, convert = botest.name)
         @test outfile.acctyp.recmrktyp == rectest.rectyp
      else
         infile  = FortranFile(infilename, "r", access="direct", recl=dareclen, convert = botest.name)
         @test infile.acctyp.reclen == dareclen
         outfile = FortranFile(outfilename, "w", access="direct", recl=dareclen, convert = botest.name)
         @test infile.acctyp.reclen == dareclen
      end
   end

   @time @testset "Reading data" begin
      data = readdata(infile)
   end

   @time @testset "@fread'ing data " begin
      rewind(infile)
      data2 = freaddata(infile)
      @test data == data2
   end

   @time @testset "Reading data with skipping" begin
      rewind(infile)
      skipdata(infile)
      close(infile)
   end

   @time @testset "Writing data" begin
      writedata(outfile, data)
      close(outfile)
   end

   @testset "Verifying data" begin
      @test cmpfiles(infilename, outfilename)
   end

end

if Sys.islinux()
   run(`make -C codegen clean`)
   for fn in readdir()
      isfile(fn) || continue
      endswith(fn, ".bin") && rm(fn)
   end
end