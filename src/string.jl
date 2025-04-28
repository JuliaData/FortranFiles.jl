const Fchar = Int8

"""
    FString{L}

Datatype for reading and writing character strings from `FortranFile`s.
The type parameter `L` signifies the length of the string.
This is the equivalent to the Fortran datatype `CHARACTER(len=L)`.
"""
struct FString{L}
   data :: Array{Fchar,1}
end

Base.sizeof(::Type{FString{L}}) where {L} = L
Base.sizeof(::FString{L}) where {L} = L
Base.sizeof(a::Array{FString{L}}) where {L} = L*length(a)

Base.show(io::IO, s::FString{L}) where {L} = begin print(io, "FString($L,"); show(io, trimstring(s)); print(io, ")") end

Base.:(==)(a::FString, b::FString) = trimstring(a)==trimstring(b)

Base.bswap(s::FString{L}) where {L} = s # no conversion needed for byte-based strings

function Base.convert(::Type{FString{L}}, s::String) where {L}
   spc  = Fchar(' ')
   data = fill(spc, L)
   for (i,c) in enumerate(s)
      if i>L; break; end
      data[i] = Fchar(c)
   end
   FString{L}(data)
end

"""
    FString(L, s::String)

Convert the Julia `String` `s` to an `FString{L}`.
`s` must contain only ASCII characters.
As in Fortran, the string will be padded with spaces or truncated in order to reach the desired length.
"""
FString(L, s::String) = convert( FString{L}, s )

Base.String(s::FString{L}) where {L} = String(map(Char,s.data))
Base.convert(::Type{String}, s::FString{L}) where {L} = String(s)


function Base.read( io::IO, t::Type{FString{L}} ) where {L}
   s = read!(io, Array{Fchar}(undef, L))
   FString{L}(s)
end


function Base.write( io::IO, s::FString{L} ) where {L}
   write(io, s.data)
end

"""
    trimlen(s::FString)

Returns the length of the `FString` `s` with trailing spaces ignored.
"""
function trimlen( s::FString{L} ) where {L}
   l = L
   while l>0
      if s.data[l] != Fchar(' '); break; end
      l -= 1
   end
   return l
end

"""
    trim(s::FString)

Returns a truncated copy of the `FString` `s` where all trailing
spaces are removed.
"""
function trim( s::FString{L} ) where {L}
   l = trimlen(s)
   FString{l}(s.data[1:l])
end

"""
    trimstring(s::FString)

Convert the `FString` `s` into a Julia `String`, where
trailing spaces are removed. Use `String(s)` to keep the spaces.
"""
trimstring( s::FString{L} ) where {L} =
   String( map(Char, s.data[1:trimlen(s)]) )

