mutable struct RecordWithSubrecords{C} <: Record
    io::IO      # underlying I/O stream
    maxsrlen::Int32   # maximum subrecord length
    subreclen::Int32   # length of current subrecord
    subleft::Int32   # bytes left in current subrecord
    more::Bool    # whether more subrecords will follow
    writable::Bool    # whether this record is writable
    isfirst::Bool    # if writable: whether this is the first subrecord
    totleft::Int64   # if writable: bytes left in this record
    convert::C       # convert method
end

function rdmarker(io, fn)
    reclen = read(io, Int32) |> fn
    more = (reclen < 0)
    return (abs(reclen), more)
end
rdmarker(rec::Record) = rdmarker(rec.io, rec.convert.onread)

function mkmarker(towrite, msl)
    subreclen = min(towrite, msl)
    more = (subreclen < towrite)
    return (Int32(subreclen), more)
end

function wrmarker(io, fn, subreclen, sign)
    marker = subreclen * (sign ? -1 : 1)
    return write(io, convert(Int32, marker) |> fn)
end
wrmarker(rec::Record, subreclen, sign) = wrmarker(rec.io, rec.convert.onwrite, subreclen, sign)

function Record(f::FortranFile{SequentialAccess{WithSubrecords}})
    ## constructor for readable records
    conv = f.convert
    msl = f.acctyp.recmrktyp.max_subrecord_length
    subreclen, more = rdmarker(f.io, conv.onread) # read leading record marker
    return RecordWithSubrecords(f.io, msl, subreclen, subreclen, more, false, false, Int64(0), conv)
end

function Record(f::FortranFile{SequentialAccess{WithSubrecords}}, towrite::Integer)
    ## constructor for writable records
    conv = f.convert
    msl = f.acctyp.recmrktyp.max_subrecord_length
    subreclen, more = mkmarker(towrite, msl)
    wrmarker(f.io, conv.onwrite, subreclen, more) # write leading record marker
    return RecordWithSubrecords(f.io, msl, subreclen, subreclen, more, true, true, Int64(towrite), conv)
end

function advance!(rec::RecordWithSubrecords)
    subreclen, sign = rdmarker(rec) # read trailing record marker
    if subreclen != rec.subreclen
        fthrow("trailing subrecord marker doesn't match")
    end
    if rec.more
        subreclen, more = rdmarker(rec) # read next leading subrecord marker
        rec.subleft = rec.subreclen = subreclen
        rec.more = more
    end
    return nothing
end

function Base.unsafe_read(rec::RecordWithSubrecords, p::Ptr{UInt8}, n::UInt)
    while (n > 0)
        if rec.subleft == 0
            fthrow("attempting to read beyond record end")
        end
        toread = min(n, rec.subleft)
        unsafe_read(rec.io, p, toread)
        p += toread
        n -= toread
        rec.subleft -= toread
        if rec.subleft == 0
            advance!(rec)
        end
    end
    return nothing
end

function Base.unsafe_write(rec::RecordWithSubrecords, p::Ptr{UInt8}, n::UInt)
    nwritten = 0
    while (n > 0)
        if rec.totleft == 0
            fthrow("attempting to write beyond record end")
        end
        towrite = min(n, rec.subleft)
        nwritten += unsafe_write(rec.io, p, towrite)
        p += towrite
        n -= towrite
        rec.subleft -= towrite
        rec.totleft -= towrite
        if rec.subleft == 0
            # the current subrecord is full
            # if there are more subrecords, write the record markers
            if rec.more
                # write trailing subrecord marker
                wrmarker(rec, rec.subreclen, !rec.isfirst)
                # write next leading subrecord marker
                subreclen, more = mkmarker(rec.totleft, rec.maxsrlen)
                wrmarker(rec, subreclen, more)
                # update our Record
                rec.subleft = rec.subreclen = subreclen
                rec.more = more
                rec.isfirst = false
            end
        end
    end
    return nwritten
end

function Base.close(rec::RecordWithSubrecords)
    if rec.writable
        @assert rec.totleft == 0
        @assert rec.subleft == 0
        @assert !rec.more
        wrmarker(rec, rec.subreclen, !rec.isfirst)
    else
        while rec.subleft > 0
            skip(rec.io, rec.subleft)
            rec.subleft = 0
            advance!(rec)
        end
        @assert !rec.more
    end
    return nothing
end
