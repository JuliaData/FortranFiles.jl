mutable struct FixedLengthRecord{T, C} <: Record
    io::IO    # underlying I/O stream
    reclen::T     # length of this record
    nleft::T     # bytes left in this record
    writable::Bool  # whether this record is writable
    convert::C     # convert method
end

function Record(f::FortranFile{DirectAccess}, recnum::Integer)
    ## constructor for readable records
    conv = f.convert
    reclen = f.acctyp.reclen
    gotorecord(f, recnum)
    return FixedLengthRecord(f.io, reclen, reclen, false, conv)
end

function Record(f::FortranFile{DirectAccess}, recnum::Integer, towrite::Integer)
    ## constructor for writable records
    conv = f.convert
    reclen = f.acctyp.reclen
    if towrite > reclen
        fthrow("attempting to write record of $(towrite) bytes into a file of record length $(reclen) bytes")
    end
    gotorecord(f, recnum)
    return FixedLengthRecord(f.io, reclen, reclen, true, conv)
end

function gotorecord(f::FortranFile{DirectAccess}, recnum::Integer)
    reclen = f.acctyp.reclen
    pos = (recnum - 1) * reclen
    return seek(f.io, pos)
end

function Base.unsafe_read(rec::FixedLengthRecord, p::Ptr{UInt8}, n::UInt)
    if (n > rec.nleft)
        fthrow("attempting to read beyond record end")
    end
    unsafe_read(rec.io, p, n)
    rec.nleft -= n
    return nothing
end

function Base.unsafe_write(rec::FixedLengthRecord, p::Ptr{UInt8}, n::UInt)
    if (n > rec.nleft)
        fthrow("attempting to write beyond record end")
    end
    nwritten = unsafe_write(rec.io, p, n)
    rec.nleft -= n
    return nwritten
end

function Base.close(rec::FixedLengthRecord)
    if rec.nleft != 0
        if rec.writable
            # Fortran standard 9.6.4.5.2 point 7:
            # "If the file is connected for direct access and the values specified by the
            #  output list do not fill the record, the remainder of the record is undefined."
            # Following gfortran, we fill it with zeros.
            write(rec.io, zeros(UInt8, rec.nleft))
        else
            skip(rec.io, rec.nleft)
        end
    end
    return nothing
end
