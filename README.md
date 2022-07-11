# CasaCore.jl

<img src="docs/src/assets/logo.png" alt="CasaCore.jl" width="200">

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://kiranshila.github.io/CasaCore.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://kiranshila.github.io/CasaCore.jl/dev)
[![Build Status](https://github.com/kiranshila/CasaCore.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/kiranshila/CasaCore.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![codecov](https://codecov.io/gh/kiranshila/CasaCore.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/kiranshila/CasaCore.jl)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1116426.svg)](https://doi.org/10.5281/zenodo.1116426)

CasaCore.jl is a Julia wrapper of [CasaCore](http://casacore.github.io/casacore/), which is a
commonly used library in radio astronomy.

Functionality is divided into two submodules:

* `CasaCore.Tables` for interfacing with tables (for example Casa measurement sets), and
* `CasaCore.Measures` for performing coordinate system conversions (for example calculating the
  azimuth and elevation of an astronomical target).

**Author:** Michael Eastwood and contributors

**License:** GPLv3+