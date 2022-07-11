# CasaCore.jl

CasaCore.jl is a Julia wrapper of [CasaCore](http://casacore.github.io/casacore/), which is a
commonly used library in radio astronomy.

Functionality is divided into two submodules:

* `CasaCore.Tables` for interfacing with tables (for example Casa measurement sets), and
* `CasaCore.Measures` for performing coordinate system conversions (for example calculating the
  azimuth and elevation of an astronomical target).

## Getting Started

You can obtain CasaCore.jl by running (from within the Julia REPL):
```julia
Pkg.add("CasaCore")  # download CasaCore.jl
Pkg.test("CasaCore") # test that CasaCore.jl is working properly
```

If CasaCore.jl was built successfully but any (or all) of the tests fail after running
`Pkg.test("CasaCore")`, please open a Github issue.

## Bugs and Feature Requests

Development of this package is ongoing and largely focused on my own requirements.  If you need
additional features, open an issue or a pull request.  In the short term, you can use the excellent
[PyCall](https://github.com/JuliaPy/PyCall.jl) package to access the Python wrapper of CasaCore
([python-casacore](https://github.com/casacore/python-casacore)).

