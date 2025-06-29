using Documenter, FortranFiles

makedocs(
    modules = [FortranFiles],
    sitename = "FortranFiles.jl",
    format = Documenter.HTML(prettyurls = false),
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
)

deploydocs(
    repo = "github.com/traktofon/FortranFiles.jl.git",
    branch = "gh-pages"
)
