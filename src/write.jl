"""
    write(f::FortranFile, items...)
    write(f::FortranFile, rec=N, items...)

Write a data record to a `FortranFile`. Each `item` should be a scalar
of a Fortran-compatible datatype (e.g. `Int32`, `Float64`, `FString{10}`),
or an array of such scalars. If no `item`s are given, an empty record is
written. Returns the number of bytes written, **not** including the space
taken up by the record markers.

For direct-access files, the number of the record to be written must be
specified with the `rec` keyword (N=1 for the first record).
"""
function Base.write(f::FortranFile, items...)
    # how much data to write?
    towrite = sizeof_vars(items)
    record = Record(f, towrite)
    result = fwrite(record, items...)
    close(record)
    return result
end

function Base.write(f::FortranFile{DirectAccess}, items...; rec::Integer = 0)
    if rec == 0
        fthrow("direct-access files require specifying the record to be written (use rec keyword argument)")
    end
    towrite = sizeof_vars(items)
    record = Record(f, rec, towrite)
    result = fwrite(record, items...)
    close(record)
    return result
end

function fwrite(rec::Record)
    return 0
end

function fwrite(rec::Record, vars...)
    written = sum(write_var(rec, var) for var in vars)
    return written
end

# workarounds for "does not support byte I/O"
function write_var(rec::Record, var::Int8)
    return write_var(rec, [var])
end

function write_var(rec::Record, arr::Array{Int8, N}) where {N}
    return write(rec, arr)
end

# write scalars
function write_var(rec::Record, var::T) where {T}
    return write(rec, rec.convert.onwrite(var))
end

# write arrays
function write_var(rec::Record, arr::Array{T, N}) where {T, N}
    written = 0
    for x in arr
        written += write(rec, rec.convert.onwrite(x))
    end
    return written
end

# write strings: delegate to data field
write_var(rec::Record, var::FString) = write_var(rec, var.data)
write_var(rec::Record, arr::Array{FString{L}, N}) where {L, N} = write_fstrings(rec, arr)
write_fstrings(rec::Record, arr::Array{FString{L}, N}) where {L, N} = sum(write_var(rec, var.data) for var in arr)

# specialized versions for no byte-order conversion
write_var(rec::RecordWithSubrecords{NOCONV}, arr::Array{T, N}) where {T, N} = write(rec, arr)
write_var(rec::RecordWithSubrecords{NOCONV}, arr::Array{Int8, N}) where {N} = write(rec, arr)
write_var(rec::RecordWithoutSubrecords{R, NOCONV}, arr::Array{T, N}) where {T, N, R} = write(rec, arr)
write_var(rec::RecordWithoutSubrecords{R, NOCONV}, arr::Array{Int8, N}) where {N, R} = write(rec, arr)

# resolve ambiguities
write_var(rec::RecordWithSubrecords{NOCONV}, arr::Array{FString{L}, N}) where {L, N} = write_fstrings(rec, arr)
write_var(rec::RecordWithoutSubrecords{R, NOCONV}, arr::Array{FString{L}, N}) where {L, N, R} = write_fstrings(rec, arr)

# check for type compatibility with Fortran
check_fortran_type(x::Array) = _check_fortran_type(eltype(x))
check_fortran_type(x) = _check_fortran_type(typeof(x))
_check_fortran_type(::Type{FString{L}}) where {L} = true
_check_fortran_type(T::Type) = isbitstype(T)

function sizeof_var(var::T) where {T}
    check_fortran_type(var) ||
        fthrow("cannot serialize datatype $T for Fortran")
    return sizeof(var)
end

sizeof_vars(vars) = isempty(vars) ? 0 : sum(sizeof_var(var) for var in vars)
