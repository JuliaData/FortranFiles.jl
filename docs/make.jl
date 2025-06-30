using Documenter, FortranFiles

format = Documenter.HTML(
    edit_link = "master",
    prettyurls = Base.get_bool_env("CI", false)
)

pages = [
    "Home" => "index.md",
    "files.md",
    "types.md",
    "read.md",
    "write.md",
    "exceptions.md",
    "tests.md",
    "Index" => "theindex.md",
]

makedocs(; modules = [FortranFiles], sitename = "FortranFiles.jl", format, pages)
deploydocs(; repo = "github.com/JuliaData/FortranFiles.jl.git")
