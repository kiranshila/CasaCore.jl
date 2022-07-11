using Documenter, CasaCore

DocMeta.setdocmeta!(CasaCore, :DocTestSetup, :(using CasaCore); recursive=true)

makedocs(;
    modules=[CasaCore],
    authors="Michael Eastwood and contributors",
    repo="https://github.com/kiranshila/CasaCore.jl/blob/{commit}{path}#{line}",
    sitename="CasaCore.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://kiranshila.github.io/CasaCore.jl",
        assets=String[]
    ),
    pages=[
        "Introduction" => "index.md",
        "Modules" => [
            "CasaCore.Tables" => "tables.md",
            "CasaCore.Measures" => "measures.md"
        ]
    ]
)

deploydocs(;
    repo="github.com/kiranshila/CasaCore.jl",
    devbranch="main"
)