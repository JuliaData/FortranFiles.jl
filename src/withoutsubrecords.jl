mutable struct RecordWithoutSubrecords{T,C} <: Record
   io       :: IO    # underlying I/O stream
   reclen   :: T     # length of this record
   nleft    :: T     # bytes left in this record
   writable :: Bool  # whether this record is writable
   convert  :: C     # convert method
end

function Record( f::FortranFile{SequentialAccess{WithoutSubrecords{T}},C} ) where {T,C}
## constructor for readable records
   conv = f.convert
   reclen = conv.onread( read(f.io, T) ) # read leading record marker
   RecordWithoutSubrecords{T,C}(f.io, reclen, reclen, false, conv)
end

function Record( f::FortranFile{SequentialAccess{WithoutSubrecords{T}},C}, towrite::Integer ) where {T,C}
## constructor for writable records
   conv = f.convert
   write(f.io, conv.onwrite( convert(T, towrite) )) # write leading record marker
   RecordWithoutSubrecords{T,C}(f.io, towrite, towrite, true, conv)
end

function Base.unsafe_read( rec::RecordWithoutSubrecords, p::Ptr{UInt8}, n::UInt )
   n > rec.nleft && fthrow("attempting to read beyond record end")
   unsafe_read( rec.io, p, n )
   rec.nleft -= n
   nothing
end

function Base.unsafe_write( rec::RecordWithoutSubrecords, p::Ptr{UInt8}, n::UInt )
   n > rec.nleft && fthrow("attempting to write beyond record end")
   nwritten = unsafe_write( rec.io, p, n )
   rec.nleft -= n
   return nwritten
end

function Base.close( rec::RecordWithoutSubrecords{T} ) where {T}
   if rec.writable
      @assert rec.nleft == 0
      write(rec.io, rec.convert.onwrite( convert(T, rec.reclen)) ) # write trailing record marker
   else
      skip(rec.io, rec.nleft)
      reclen = rec.convert.onread( read(rec.io, T) ) # read trailing record marker
      reclen == rec.reclen|| fthrow("trailing record marker doesn't match")
   end
   nothing
end

