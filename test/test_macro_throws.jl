# Like @test_throws, but for macros.
# Julia-0.7 and later always wrap the exception in a LoadError.

macro test_macro_throws(typ, expr)
    return quote
        @test_throws $typ begin
            try
                $expr
            catch e
                rethrow(e.error)
            end
        end
    end
end
