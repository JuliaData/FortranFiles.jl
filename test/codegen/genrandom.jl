const typeinfo = [
    ("i1", "integer(kind=int8)", "i1rand"),
    ("i2", "integer(kind=int16)", "i2rand"),
    ("i4", "integer(kind=int32)", "i4rand"),
    ("i8", "integer(kind=int64)", "i8rand"),
    ("r4", "real(kind=real32)", "r4rand"),
    ("r8", "real(kind=real64)", "r8rand"),
    ("c8", "complex(kind=real32)", "c8rand"),
    ("c16", "complex(kind=real64)", "c16rand"),
    ("str", "character(len=*)", "strrand"),
]

function genrandom()
    for (name, ftype, func) in typeinfo
        cmd = `./ftl-expand name=$name type=$ftype func=$func`
        run(pipeline(cmd, stdin = "random.ftl", stdout = "random$(name).f90"))
    end
    return
end

genrandom()
