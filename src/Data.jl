# Copyright (c) 2022 Kiran Shila
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

# Here we need to deal with the fact that the JLL of the wrapper (and therefore casacore)
# does not have the ephemeris data that casacore needs. Here, we'll deal with downloading
# it and populating it in a way that casacore can see it.

module Data

using casacorewrapper_jll

# using Tar, CodecZlib
# artifact_toml = joinpath(@__DIR__, "Artifacts.toml")
# measures_hash = artifact_hash("measures", artifact_toml)
# if measures_hash == nothing || !artifact_exists(measures_hash)
#     measures_hash = create_artifact() do artifact_dir
#         # Download measures
#         path = joinpath(artifact_dir, "WSRT_Measures.ztar")
#         download("ftp://ftp.astron.nl/outgoing/Measures/WSRT_Measures.ztar",path)
#         # Unpack
#         tar_gz = open(path)
#         tar = GzipDecompressorStream(tar_gz)
#         Tar.extract(tar)
#         close(tar)
#     end
#     bind_artifact!(artifact_toml, "measures", measures_hash, force=true)
# end

# artifact"measures"

function set_rc_path(path::String)
    ccall((:set_casarc_path, libcasacorewrapper), Cvoid, (Ptr{Cchar},), path)
end

function set_measures_path(path::String)
    rc = tempname()
    write(rc, "measures.directory: $path")
    set_rc_path(rc)
end

end