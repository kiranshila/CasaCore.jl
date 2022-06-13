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

@enum(TypeEnum,
      TpBool, TpChar, TpUChar, TpShort, TpUShort, TpInt, TpUInt,
      TpFloat, TpDouble, TpComplex, TpDComplex, TpString, TpTable,
      TpArrayBool, TpArrayChar, TpArrayUChar, TpArrayShort, TpArrayUShort,
      TpArrayInt, TpArrayUInt, TpArrayFloat, TpArrayDouble, TpArrayComplex,
      TpArrayDComplex, TpArrayString, TpRecord, TpOther, TpQuantity,
      TpArrayQuantity, TpInt64, TpArrayInt64, TpNumberOfTypes)

const type2cpp = IdDict(Bool => Bool, Int32 => Int32,
                        Float32 => Float32, Float64 => Float64,
                        ComplexF64 => ComplexF64, String => Ptr{Cchar})

const type2str = IdDict(Bool => :boolean, Int32 => :int,
                        Float32 => :float, Float64 => :double,
                        ComplexF64 => :complex, String => :string)

const enum2type = Dict(TpBool => Bool, TpArrayBool => Array{Bool},
                       TpInt => Int32, TpArrayInt => Array{Int32},
                       TpFloat => Float32, TpArrayFloat => Array{Float32},
                       TpDouble => Float64, TpArrayDouble => Array{Float64},
                       TpComplex => ComplexF64, TpArrayComplex => Array{ComplexF64},
                       TpString => String, TpArrayString => Array{String})

const typelist = (Bool, Int32, Float32, Float64, ComplexF64, String)

function wrap(ptr::Ptr{T}, shape) where {T<:Number}
    N = length(shape)
    return unsafe_wrap(Array{T,N}, ptr, shape, true)
end

function wrap(ptr::Ptr{Ptr{Cchar}}, shape)
    N = length(shape)
    return wrap_value.(unsafe_wrap(Array{Ptr{Cchar},N}, ptr, shape, true))
end

function wrap_value(ptr::Ptr{Cchar})
    string = unsafe_string(ptr)
    # `unsafe_string` copies the data, so we need to free the previously allocated data. Apparently
    # I can't do this with `Libc.free` because julia might be using a different version of libc than
    # what was used to allocate the memory.
    ccall((:free_string, libcasacorewrapper), Cvoid, (Ptr{Cchar},), ptr)
    return string
end

wrap_value(x) = x
