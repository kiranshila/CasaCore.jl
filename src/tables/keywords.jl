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

@noinline function keyword_missing_error(keyword)
    return err("keyword \"$keyword\" is missing from the table")
end

@noinline function keyword_element_type_error(keyword)
    return err("element type mismatch for keyword \"$keyword\"")
end

struct Keyword
    name::String
end

Base.convert(::Type{String}, keyword::Keyword) = keyword.name
function Base.unsafe_convert(::Type{Ptr{Cchar}}, keyword::Keyword)
    return Base.unsafe_convert(Ptr{Cchar}, String(keyword))
end
Base.show(io::IO, keyword::Keyword) = print(io, keyword.name)

macro kw_str(string)
    quote
        Keyword($string)
    end
end

"""
    num_keywords(table)

Returns the number of keywords associated with the given table.

**Arguments:**

- `table` - the relevant table

**Usage:**

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
       Tables.num_keywords(table)
0

julia> table[kw"RICK_PERLEY_IS_A_BOSS"] = true
       Tables.num_keywords(table)
1

julia> table[kw"NOT_SO_BAD"] = "yourself"
       Tables.num_keywords(table)
2

julia> Tables.delete(table)
```

**See also:** [`Tables.num_rows`](@ref), [`Tables.num_columns`](@ref)
"""
function num_keywords(table::Table)
    isopen(table) || table_closed_error()
    return Int(ccall((:num_keywords, libcasacorewrapper), Cuint,
                     (Ptr{CasaCoreTable},), table))
end

"Query whether the keyword exists."
function keyword_exists(table::Table, keyword::Keyword)
    isopen(table) || table_closed_error()
    return ccall((:keyword_exists, libcasacorewrapper), Bool,
                 (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
end

function keyword_exists(table::Table, column::String, keyword::Keyword)
    isopen(table) || table_closed_error()
    return ccall((:column_keyword_exists, libcasacorewrapper), Bool,
                 (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
end

"""
    Tables.remove_keyword!(table, keyword)

Remove the specified keyword from the table.

**Arguments:**

- `table` - the relevant table
- `keyword` - the keyword to be removed

**Usage:**

```jldoctest
julia> table = Tables.create("/tmp/my-table.ms")
       table[kw"HELLO"] = "world"
       Tables.num_keywords(table)
1

julia> Tables.remove_keyword!(table, kw"HELLO")
       Tables.num_keywords(table)
0

julia> Tables.delete(table)
```

**See also:** [`Tables.num_keywords`](@ref)
"""
function remove_keyword!(table::Table, keyword::Keyword)
    isopen(table) || table_closed_error()
    iswritable(table) || table_readonly_error()
    ccall((:remove_keyword, libcasacorewrapper), Cvoid,
          (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
    return keyword
end

function remove_keyword!(table::Table, column::String, keyword::Keyword)
    isopen(table) || table_closed_error()
    iswritable(table) || table_readonly_error()
    return ccall((:remove_column_keyword, libcasacorewrapper), Cvoid,
                 (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{Cchar}), table, column, keyword)
end

"Get the keyword element type and shape."
function keyword_info(table::Table, keyword::Keyword)
    isopen(table) || table_closed_error()
    element_type = Ref{Cint}(0)
    dimension = Ref{Cint}(0)
    shape_ptr = ccall((:keyword_info, libcasacorewrapper), Ptr{Cint},
                      (Ptr{CasaCoreTable}, Ptr{Cchar}, Ref{Cint}, Ref{Cint}),
                      table, keyword, element_type, dimension)
    T = enum2type[TypeEnum(element_type[])]
    shape = unsafe_wrap(Vector{Cint}, shape_ptr, dimension[], true)
    return T, tuple(shape...)
end

function keyword_info(table::Table, column::String, keyword::Keyword)
    isopen(table) || table_closed_error()
    element_type = Ref{Cint}(0)
    dimension = Ref{Cint}(0)
    shape_ptr = ccall((:column_keyword_info, libcasacorewrapper), Ptr{Cint},
                      (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{Cchar}, Ref{Cint}, Ref{Cint}),
                      table, column, keyword, element_type, dimension)
    T = enum2type[TypeEnum(element_type[])]
    shape = unsafe_wrap(Vector{Cint}, shape_ptr, dimension[], true)
    return T, tuple(shape...)
end

function Base.getindex(table::Table, keyword::Keyword)
    isopen(table) || table_closed_error()
    if !keyword_exists(table, keyword)
        keyword_missing_error(keyword)
    end
    T, shape = keyword_info(table, keyword)
    return read_keyword(table, keyword, T, shape)
end

function Base.setindex!(table::Table, value, keyword::Keyword)
    isopen(table) || table_closed_error()
    if keyword_exists(table, keyword)
        T, shape = keyword_info(table, keyword)
        if T != typeof(value)
            keyword_element_type_error(keyword)
        end
    end
    return write_keyword!(table, value, keyword)
end

function Base.getindex(table::Table, column::String, keyword::Keyword)
    isopen(table) || table_closed_error()
    if !column_exists(table, column)
        column_missing_error(column)
    end
    if !keyword_exists(table, column, keyword)
        keyword_missing_error(keyword)
    end
    T, shape = keyword_info(table, column, keyword)
    return read_keyword(table, column, keyword, T, shape)
end

function Base.setindex!(table::Table, value, column::String, keyword::Keyword)
    isopen(table) || table_closed_error()
    iswritable(table) || table_readonly_error()
    if !column_exists(table, column)
        column_missing_error(column)
    end
    if keyword_exists(table, column, keyword)
        T, shape = keyword_info(table, column, keyword)
        if T != eltype(value)
            keyword_element_type_error(keyword)
        end
    end
    return write_keyword!(table, value, column, keyword)
end

for T in typelist
    Tc = type2cpp[T]
    typestr = type2str[T]
    c_get_keyword = String(Symbol(:get_keyword_, typestr))
    c_put_keyword = String(Symbol(:put_keyword_, typestr))
    c_get_keyword_array = String(Symbol(:get_keyword_array_, typestr))
    c_put_keyword_array = String(Symbol(:put_keyword_array_, typestr))
    c_get_column_keyword = String(Symbol(:get_column_keyword_, typestr))
    c_put_column_keyword = String(Symbol(:put_column_keyword_, typestr))
    c_get_column_keyword_array = String(Symbol(:get_column_keyword_array_, typestr))
    c_put_column_keyword_array = String(Symbol(:put_column_keyword_array_, typestr))

    @eval function read_keyword(table::Table, keyword::Keyword, ::Type{$T}, shape)
        value = ccall(($c_get_keyword, libcasacorewrapper), $Tc,
                      (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
        return wrap_value(value)
    end

    @eval function read_keyword(table::Table, keyword::Keyword, ::Type{Array{$T}}, shape)
        ptr = ccall(($c_get_keyword_array, libcasacorewrapper), Ptr{$Tc},
                    (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
        return wrap(ptr, shape)
    end

    @eval function read_keyword(table::Table, column::String, keyword::Keyword,
                                ::Type{$T}, shape)
        value = ccall(($c_get_column_keyword, libcasacorewrapper), $Tc,
                      (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{Cchar}),
                      table, column, keyword)
        return wrap_value(value)
    end

    @eval function read_keyword(table::Table, column::String, keyword::Keyword,
                                ::Type{Array{$T}}, shape)
        ptr = ccall(($c_get_column_keyword_array, libcasacorewrapper), Ptr{$Tc},
                    (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{Cchar}),
                    table, column, keyword)
        return wrap(ptr, shape)
    end

    @eval function write_keyword!(table::Table, value::$T, keyword::Keyword)
        ccall(($c_put_keyword, libcasacorewrapper), Cvoid,
              (Ptr{CasaCoreTable}, Ptr{Cchar}, $Tc), table, keyword, value)
        return value
    end

    @eval function write_keyword!(table::Table, value::Array{$T}, keyword::Keyword)
        shape = convert(Vector{Cint}, collect(size(value)))
        ccall(($c_put_keyword_array, libcasacorewrapper), Cvoid,
              (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{$Tc}, Ptr{Cint}, Cint),
              table, keyword, value, shape, length(shape))
        return value
    end

    @eval function write_keyword!(table::Table, value::$T,
                                  column::String, keyword::Keyword)
        ccall(($c_put_column_keyword, libcasacorewrapper), Cvoid,
              (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{Cchar}, $Tc),
              table, column, keyword, value)
        return value
    end

    @eval function write_keyword!(table::Table, value::Array{$T},
                                  column::String, keyword::Keyword)
        shape = convert(Vector{Cint}, collect(size(value)))
        ccall(($c_put_column_keyword_array, libcasacorewrapper), Cvoid,
              (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{Cchar}, Ptr{$Tc}, Ptr{Cint}, Cint),
              table, column, keyword, value, shape, length(shape))
        return value
    end
end

function read_keyword(table::Table, keyword::Keyword, ::Type{Table}, shape)
    ptr = ccall((:get_keyword_table, libcasacorewrapper), Ptr{CasaCoreTable},
                (Ptr{CasaCoreTable}, Ptr{Cchar}), table, keyword)
    path = wrap_value(ccall((:table_name, libcasacorewrapper), Ptr{Cchar},
                            (Ptr{CasaCoreTable},), ptr))
    return Table(path, table.status, ptr)
end

function write_keyword!(table::Table, value::Table, keyword::Keyword)
    ccall((:put_keyword_table, libcasacorewrapper), Cvoid,
          (Ptr{CasaCoreTable}, Ptr{Cchar}, Ptr{CasaCoreTable}),
          table, keyword, value)
    return value
end
