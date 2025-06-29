struct FortranFile{A <: AccessMode, C <: Conversion}
    io::IO    # the underyling I/O stream
    acctyp::A
    convert::C
end


"""
    FortranFile(io::IO; kwargs...)

Wrap the given `IO` stream as a `FortranFile` containing Fortran "unformatted"
(i.e. binary) data. The keyword arguments can be:
* `access` for specifying the access mode; a `String` being one of
  * "sequential": sequential access as in Fortran, where records have leading
    and trailing record markers. This is the default.
  * "direct": direct access as in Fortran, where records have fixed length
    and can be accessed in random order. The "recl" keyword must be given
    to specify the record length. `read` and `write` operations on these files
    must use the `rec` keyword argument to specify which record to read/write.
* `marker`: for specifying the type of record marker; one of
  * `RECMRK4B`: 4-byte record markers (with support for subrecords) [default]
  * `RECMRK8B`: 8-byte record markers
  This is ignored for direct access files.
* `recl`: for specifying the record length if access=="direct".
  The record length is counted in bytes and must be specified as an Integer.
* `convert`: for specifying the byte-order of the file data; one of
  * "native": use the host byte order [default]
  * "big-endian": use big-endian byte-order
  * "little-endian": use little-endian byte-order

The returned `FortranFile` can be used with Julia's `read` and `write`
functions. See their documentation for more information.
"""
function FortranFile(io::IO; access = "sequential", marker = RECMRKDEF, recl::Integer = 0, convert = "native")
    conv = get_convert(convert)
    if access == "sequential"
        if recl != 0
            fthrow("sequential-access with fixed-length records not supported")
        end
        acctyp = SequentialAccess(marker)
    elseif access == "direct"
        if recl == 0
            fthrow("must specify record length for direct-access files (use recl keyword argument)")
        end
        acctyp = DirectAccess(Int64(recl))
    else
        fthrow("unsupported access mode \"$(access)\"")
    end
    return FortranFile(io, acctyp, conv)
end


"""
    FortranFile(fn::String [, mode="r" ]; kwargs...)

Open a file containing Fortran unformatted (i.e. binary) data for reading
or writing, depending on `mode` which is used as in `open`. The keyword
arguments are as in `FortranFile(io::IO; kwargs...)`.
"""
FortranFile(fn::String, mode = "r"; kwargs...) = FortranFile(open(fn, mode); kwargs...)


"Re-position a `FortranFile` at its beginning."
rewind(f::FortranFile) = seek(f.io, 0)


Base.close(f::FortranFile) = close(f.io)


Base.eof(f::FortranFile) = eof(f.io)


function Base.show(io::IO, f::FortranFile)
    print(io, "FortranFile(")
    show(io, f.io)
    print(io, "), $(f.convert.name) byte order, ")
    return show(io, f.acctyp)
end
