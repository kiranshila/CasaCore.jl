# Copyright (c) 2015-2017 Michael Eastwood
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

using CasaCore.Data
using CasaCore.Tables
using CasaCore.Measures
using CasaCore.MeasurementSets
using Unitful
using Test
using Random
using Dates
using LinearAlgebra

Random.seed!(123)

#Data.set_measures_path("/home/kiran/src/CasaCore.jl/IERS")

@testset "CasaCore Tests" begin
    include("tables.jl")
    include("measures.jl")
    include("measurement-sets.jl")
end

