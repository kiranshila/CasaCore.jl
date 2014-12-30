# CasaCore

[![Build Status](https://travis-ci.org/mweastwood/CasaCore.jl.svg?branch=master)](https://travis-ci.org/mweastwood/CasaCore.jl)
[![Coverage Status](https://img.shields.io/coveralls/mweastwood/CasaCore.jl.svg?style=flat)](https://coveralls.io/r/mweastwood/CasaCore.jl?branch=master)

## Getting Started

CasaCore is currently an unregistered package. Therefore, to get started using CasaCore, run:
```julia
Pkg.clone("https://github.com/mweastwood/CasaCore.jl.git")
Pkg.build("CasaCore")
Pkg.test("CasaCore")
```
The build process will attempt to download, build, and install [CasaCore](https://code.google.com/p/casacore/) if it does not already exist on your system.

## Measures

```julia
using CasaCore.Measures
```
To use the the measures module of CasaCore, you first need to define a reference frame:
```julia
frame = ReferenceFrame()
position = observatory(frame,"OVRO_MMA")
time = Epoch("UTC",q"4.905577293531662e9s")
set!(frame,position)
set!(frame,time)
```
After the reference frame is defined, you can convert between various coordinate systems:
```julia
dir   = Direction("AZEL",q"0.0rad",q"1.0rad")
j2000 = measure(frame,dir,"J2000")
```

## Tables

```julia
using CasaCore.Tables
```
Interacting with CasaCore tables requires you to first open the table:
```julia
table = Table("/path/to/table")
```
Then you can read and write columns of the table as follows:
```julia
data = table["DATA"] # type-unstable!
modeldata = function_to_gen_model_visibilities()
table["MODEL_DATA"] = modeldata
```
Note that reading a column is necessarily type-unstable. That is, the element type and shape of the column cannot be inferred from the types of the arguments. If you have prior knowledge of what is stored in the column, you can mitigate this issue by adding a type annotation. For example:
```julia
data = table["DATA"]::Array{Complex64,3}
```
Alternatively, you can separate the computational kernel into a separate function. For example:
```julia
function slow_func()
    data = table["DATA"]
    for i = 1:length(data)
        data[i] = 2data[i]
    end
end

function fast_func()
    data = table["DATA"]
    kernel!(data)
end

function kernel!(data)
    for i = 1:length(data)
        data[i] = 2data[i]
    end
end
```
For more information on why this works, see the [Performance Tips](http://julia.readthedocs.org/en/latest/manual/performance-tips/#separate-kernel-functions) section of the manual.

## Development

At the moment, the functionality of this package is largely focused on my own requirements. If you need additional features, open an issue or a pull request. In the short term, you can use the excellent [PyCall](https://github.com/stevengj/PyCall.jl) package to access the Python wrapper of CasaCore ([pyrap](https://code.google.com/p/pyrap/)).
