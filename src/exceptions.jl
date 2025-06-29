"""
    FortranFilesError(msg)

Exception thrown if an operation on a FortranFile fails or cannot be performed.
Argument `msg` is a description of the failure mode.
"""
struct FortranFilesError <: Exception
    msg::String
end

fthrow(msg) = throw(FortranFilesError(msg))

Base.showerror(io::IO, exc::FortranFilesError) = print(io, "FortranFilesError: $(exc.msg)")
