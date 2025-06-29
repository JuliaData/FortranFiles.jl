"""
    @fread f [ rec=N ] [ spec ... ]

Macro interface for reading data from the `FortranFile` `f`.
A single `@fread` call will process a single data record from the file.
Each `spec` can be:
* a `var::T` declaration, which will read data of the type `T` from the
  file, and assign it to the variable `var`. `T` can be one of the usual
  Fortran scalar datatypes.
* a `var::(T,dims...)` declaration, where `T` is a scalar datatype and
  `dims...` is a series of integers. This reads an array of the specified
  datatype and dimensions, and assigns it to the variable `var`.
* `var::Array{T}(undef,dims...)` as an explicit form for reading arrays
* a variable name, which must refer to a pre-allocated array.
Note that a `spec` can refer to variables assigned by previous specs.
The `rec` keyword must be given iff `f` refers to a direct-access file,
and specifies which record to read.


Example:

    @fread f n::Int32 x::(Float64,n)

This reads a single `Int32`, assigns it to `n`, and then reads a `Float64` array
with `n` elements and assigns it to `x`. Such a record can not be processed by
the function-based `read` interface. The equivalent call would be

    n, x = read(f, Int32, (Float64,n))

but this can't work because `n` is only assigned after the `read` statement is
processed. The macro interface is provided to cover such cases.
"""
macro fread(fortranFile, args...)
    # take first argument and start a code block
    fvar = esc(fortranFile)
    ex = quote
        f = $fvar
    end

    # process the arguments, which may be:
    # - keyword assignment (look for = in Expr)
    # - var::T specification (look for :: in Expr)
    # - var (look for Symbol)
    haverecnum = false
    local recnum
    specs = Any[]
    for arg in args
        if isa(arg, Expr)
            if arg.head == :(=)
                if arg.args[1] == :rec
                    recnum = esc(arg.args[2])
                    haverecnum = true
                else
                    throw(ArgumentError("unknown keyword argument '$(arg.args[1])'"))
                end
            elseif arg.head == :(::)
                var = esc(arg.args[1])
                typ = esc(arg.args[2])
                push!(specs, (var, typ))
            else
                throw(ArgumentError("unsupported specification for read: '$(arg)'"))
            end
        elseif isa(arg, Symbol)
            var = esc(arg)
            push!(specs, var)
        else
            throw(ArgumentError("unsupported specification for read: '$(arg)'"))
        end
    end

    # construct the code block
    if haverecnum
        push!(
            ex.args, quote
                if !isa(f, FortranFile{DirectAccess})
                    fthrow("keyword argument 'rec' only allowed for direct-access files")
                end
                rec = Record(f, $recnum)
            end
        )
    else
        push!(
            ex.args, quote
                if isa(f, FortranFile{DirectAccess})
                    fthrow("keyword argument 'rec' required for direct-access files")
                end
                rec = Record(f)
            end
        )
    end
    for spec in specs
        if isa(spec, Tuple)
            var, typ = spec
            push!(ex.args, :($var = read_spec(rec, $typ)))
        else
            push!(ex.args, :(read_spec(rec, $spec)))
        end
    end
    push!(ex.args, :(close(rec)))
    return ex
end
