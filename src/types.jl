abstract type AccessMode end
abstract type RecordMarkerType end
abstract type Record <: IO end


struct SequentialAccess{RT <: RecordMarkerType} <: AccessMode
    recmrktyp::RT
end

Base.show(io::IO, a::SequentialAccess) =
    print(io, "sequential-access, ", a.recmrktyp)


struct DirectAccess <: AccessMode
    reclen::Int64
end

Base.show(io::IO, a::DirectAccess) =
    print(io, "direct-access, $(a.reclen)-byte records")


struct WithoutSubrecords{T} <: RecordMarkerType
end

const RECMRK8B = WithoutSubrecords{Int64}()

Base.show(io::IO, ::WithoutSubrecords{T}) where {T} =
    print(io, "$(sizeof(T))-byte record markers, no subrecords")


struct WithSubrecords <: RecordMarkerType
    max_subrecord_length::Int32
end

const max_subrecord_length = 2^31 - 9
const RECMRK4B = WithSubrecords(max_subrecord_length)

const RECMRKDEF = RECMRK4B

Base.show(io::IO, rt::WithSubrecords) =
    print(io, "4-byte record markers, subrecords of max $(rt.max_subrecord_length) bytes")


struct Conversion{R, W}
    onread::R
    onwrite::W
    name::String
end

const converts = [
    Conversion(identity, identity, "native"),
    Conversion(ntoh, hton, "big-endian"),
    Conversion(ltoh, htol, "little-endian"),
]

const NOCONV = typeof(converts[1])

function get_convert(name::String)
    for conv in converts
        if conv.name == name
            return conv
        end
    end
    fthrow("unknown convert method \"$name\"")
end
