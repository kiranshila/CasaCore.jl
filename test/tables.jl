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

@testset "Tables" begin
    @testset "errors" begin
        @test repr(CasaCoreTablesError("hello")) == "CasaCoreTablesError: hello"
    end

    @testset "basic table creation" begin
        path = tempname() * ".ms"

        table = Tables.create(path)
        @test table.path == path
        @test table.status === Tables.readwrite
        @test Tables.iswritable(table)
        @test repr(table) == "Table: " * path * " (read/write)"
        Tables.close(table)
        @test table.path == path
        @test table.status === Tables.closed
        @test !Tables.iswritable(table)
        @test repr(table) == "Table: " * path * " (closed)"

        table = Tables.open(path)
        @test table.path == path
        @test table.status === Tables.readonly
        @test repr(table) == "Table: " * path * " (read-only)"
        @test !Tables.iswritable(table)
        Tables.close(table)

        table = Tables.open(path; write=true)
        @test table.path == path
        @test table.status === Tables.readwrite
        @test repr(table) == "Table: " * path * " (read/write)"
        @test Tables.iswritable(table)
        Tables.close(table)

        table = Tables.open(table)
        @test table.path == path
        @test table.status === Tables.readonly
        @test repr(table) == "Table: " * path * " (read-only)"
        @test !Tables.iswritable(table)
        Tables.close(table)

        table = Tables.open(table; write=true)
        @test table.path == path
        @test table.status === Tables.readwrite
        @test repr(table) == "Table: " * path * " (read/write)"
        @test Tables.iswritable(table)
        Tables.close(table)

        @test_throws CasaCoreTablesError Tables.create(path)
        @test_throws CasaCoreTablesError Tables.open("/tmp/does-not-exist.ms")

        table = Tables.open("Table: " * path)
        @test table.path == path
        @test table.status === Tables.readonly
        @test !Tables.iswritable(table)
        @test repr(table) == "Table: " * path * " (read-only)"

        Tables.delete(table)
        @test !isdir(table.path) && !isfile(table.path)

        # Issue #58
        # This will create a temporary table in the user's home directory so only run this test if
        # we are running tests from a CI service
        if get(ENV, "CI", "false") == "true"
            println("Running test for issue #58")
            ms1 = Tables.create("~/issue58.ms")
            Tables.add_rows!(ms1, 1)
            ms1["col"] = [1.0]
            Tables.close(ms1)
            ms2 = Tables.open("~/issue58.ms")
            @test ms2["col"] == [1.0]
            Tables.close(ms2)
            rm("~/issue58.ms"; force=true, recursive=true)
        end
    end

    @testset "basic rows" begin
        path = tempname() * ".ms"
        table = Tables.create(path)

        @test Tables.num_rows(table) == 0
        Tables.add_rows!(table, 1)
        @test Tables.num_rows(table) == 1
        Tables.add_rows!(table, 1)
        @test Tables.num_rows(table) == 2
        Tables.add_rows!(table, 1)
        @test Tables.num_rows(table) == 3
        Tables.add_rows!(table, 10)
        @test Tables.num_rows(table) == 13
        Tables.remove_rows!(table, 1)
        @test Tables.num_rows(table) == 12
        Tables.remove_rows!(table, 1:2)
        @test Tables.num_rows(table) == 10
        Tables.remove_rows!(table, [5, 7, 10])
        @test Tables.num_rows(table) == 7

        @test_throws CasaCoreTablesError Tables.remove_rows!(table, 0)
        @test_throws CasaCoreTablesError Tables.remove_rows!(table, 8)
        @test_throws CasaCoreTablesError Tables.remove_rows!(table, -1)
        @test_throws CasaCoreTablesError Tables.remove_rows!(table, [0, 1])
        @test_throws CasaCoreTablesError Tables.remove_rows!(table, 0:1)
        @test_throws CasaCoreTablesError Tables.remove_rows!(table, [7, 8])
        @test_throws CasaCoreTablesError Tables.remove_rows!(table, 7:8)

        Tables.remove_rows!(table, 1:Tables.num_rows(table))
        @test Tables.num_rows(table) == 0

        Tables.delete(table)
    end

    @testset "basic columns" begin
        path = tempname() * ".ms"
        table = Tables.create(path)
        Tables.add_rows!(table, 10)

        @test_throws CasaCoreTablesError Tables.add_column!(table, "test", Float64, (11,))
        @test_throws CasaCoreTablesError Tables.add_column!(table, "test", Float64,
                                                            (10, 11))

        names = ("bools", "ints", "floats", "doubles", "complex", "strings")
        types = (Bool, Int32, Float32, Float64, ComplexF64, String)
        types_nostring = types[1:(end - 1)]
        for shape in ((10,), (11, 10), (12, 11, 10))
            for (name, T) in zip(names, types)
                Tables.add_column!(table, name, T, shape)
                @test Tables.column_exists(table, name)
                my_T, my_shape = Tables.column_info(table, name)
                @test my_T == T
                @test my_shape == shape
            end
            @test Tables.num_columns(table) == 6
            for name in names
                Tables.remove_column!(table, name)
                @test !Tables.column_exists(table, name)
            end
            @test Tables.num_columns(table) == 0
            for T in types_nostring
                x = rand(T, shape)
                y = length(shape) == 1 ? rand(T) : rand(T, shape[1:(end - 1)])
                z = length(shape) == 1 ? rand(Float16) : rand(Float16, shape[1:(end - 1)])
                table["test"] = x
                @test table["test"] == x
                @test_throws CasaCoreTablesError table["test"] = rand(T, (6, 5)) # incorrect shape
                @test_throws CasaCoreTablesError table["test"] = rand(Float16, shape) # incorrect type
                @test_throws CasaCoreTablesError table["tset"] # typo
                Tables.remove_column!(table, "test")
            end
            x = fill("Hello, world!", shape)
            y = length(shape) == 1 ? "Wassup??" : fill("Wassup??", shape[1:(end - 1)])
            z = length(shape) == 1 ? rand(Float16) : rand(Float16, shape[1:(end - 1)])
            table["test"] = x
            @test table["test"] == x
            @test_throws CasaCoreTablesError table["test"] = fill("A", (6, 5)) # incorrect shape
            @test_throws CasaCoreTablesError table["test"] = rand(Float16, shape) # incorrect type
            @test_throws CasaCoreTablesError table["tset"] # typo
            Tables.remove_column!(table, "test")
        end

        Tables.delete(table)
    end

    @testset "basic cells" begin
        path = tempname() * ".ms"
        table = Tables.create(path)
        Tables.add_rows!(table, 10)

        names = ("bools", "ints", "floats", "doubles", "complex", "strings")
        types = (Bool, Int32, Float32, Float64, ComplexF64, String)
        types_nostring = types[1:(end - 1)]
        for shape in ((10,), (11, 10), (12, 11, 10))
            for T in types_nostring
                x = rand(T, shape)
                y = length(shape) == 1 ? rand(T) : rand(T, shape[1:(end - 1)])
                z = length(shape) == 1 ? rand(Float16) : rand(Float16, shape[1:(end - 1)])
                table["test"] = x
                table["test", 3] = y
                @test table["test", 3] == y
                @test_throws CasaCoreTablesError table["tset", 3] = y # typo
                @test_throws CasaCoreTablesError table["test", 0] = y # out-of-bounds
                @test_throws CasaCoreTablesError table["test", 11] = y # out-of-bounds
                @test_throws CasaCoreTablesError table["test", 3] = rand(T, (6, 5)) # incorrect shape
                @test_throws CasaCoreTablesError table["test", 3] = z # incorrect type
                @test_throws CasaCoreTablesError table["tset", 3] # typo
                @test_throws CasaCoreTablesError table["test", 0] # out-of-bounds
                @test_throws CasaCoreTablesError table["test", 11] # out-of-bounds
                Tables.remove_column!(table, "test")
            end
            x = fill("Hello, world!", shape)
            y = length(shape) == 1 ? "Wassup??" : fill("Wassup??", shape[1:(end - 1)])
            z = length(shape) == 1 ? rand(Float16) : rand(Float16, shape[1:(end - 1)])
            table["test"] = x
            table["test", 3] = y
            @test table["test", 3] == y
            @test_throws CasaCoreTablesError table["tset", 3] = y # typo
            @test_throws CasaCoreTablesError table["test", 0] = y # out-of-bounds
            @test_throws CasaCoreTablesError table["test", 11] = y # out-of-bounds
            @test_throws CasaCoreTablesError table["test", 3] = fill("A", (6, 5)) # incorrect shape
            @test_throws CasaCoreTablesError table["test", 3] = z # incorrect type
            @test_throws CasaCoreTablesError table["tset", 3] # typo
            @test_throws CasaCoreTablesError table["test", 0] # out-of-bounds
            @test_throws CasaCoreTablesError table["test", 11] # out-of-bounds
            Tables.remove_column!(table, "test")
        end

        Tables.delete(table)
    end

    @testset "basic keywords" begin
        path = tempname() * ".ms"
        table = Tables.create(path)

        names = ("bools", "ints", "floats", "doubles", "complex", "strings")
        types = (Bool, Int32, Float32, Float64, ComplexF64, String)
        types_nostring = types[1:(end - 1)]

        # scalars
        for T in types_nostring
            x = rand(T)
            table[kw"test"] = x
            @test table[kw"test"] == x
            @test_throws CasaCoreTablesError table[kw"tset"] # typo
            @test_throws CasaCoreTablesError table[kw"test"] = Float16(0) # incorrect type
            Tables.remove_keyword!(table, kw"test")
        end
        x = "I am a banana!"
        table[kw"test"] = x
        @test table[kw"test"] == x
        @test_throws CasaCoreTablesError table[kw"tset"] # typo
        @test_throws CasaCoreTablesError table[kw"test"] = Float16(0) # incorrect type
        Tables.remove_keyword!(table, kw"test")

        # arrays
        for shape in ((10,), (11, 10), (12, 11, 10))
            for T in types_nostring
                x = rand(T, shape)
                table[kw"test"] = x
                @test table[kw"test"] == x
                @test_throws CasaCoreTablesError table[kw"test"] = rand(Float16, shape) # incorrect type
                @test_throws CasaCoreTablesError table[kw"tset"] # typo
                Tables.remove_keyword!(table, kw"test")
            end
        end

        Tables.delete(table)
    end

    @testset "column keywords" begin
        path = tempname() * ".ms"
        table = Tables.create(path)
        Tables.add_rows!(table, 10)
        Tables.add_column!(table, "column", Float64, (10,))

        names = ("bools", "ints", "floats", "doubles", "complex", "strings")
        types = (Bool, Int32, Float32, Float64, ComplexF64, String)
        types_nostring = types[1:(end - 1)]

        # scalars
        for T in types_nostring
            x = rand(T)
            table["column", kw"test"] = x
            @test table["column", kw"test"] == x
            @test_throws CasaCoreTablesError table["column", kw"tset"] # typo
            @test_throws CasaCoreTablesError table["column", kw"test"] = Float16(0) # incorrect type
            Tables.remove_keyword!(table, "column", kw"test")
        end
        x = "I am a banana!"
        table["column", kw"test"] = x
        @test table["column", kw"test"] == x
        @test_throws CasaCoreTablesError table["column", kw"tset"] # typo
        @test_throws CasaCoreTablesError table["column", kw"test"] = Float16(0) # incorrect type
        Tables.remove_keyword!(table, "column", kw"test")

        # arrays
        for shape in ((10,), (11, 10), (12, 11, 10))
            for T in types_nostring
                x = rand(T, shape)
                table["column", kw"test"] = x
                @test table["column", kw"test"] == x
                @test_throws CasaCoreTablesError table["column", kw"test"] = rand(Float16,
                                                                                  shape) # incorrect type
                @test_throws CasaCoreTablesError table["column", kw"tset"] # typo
                @test_throws CasaCoreTablesError table["colunm", kw"test"] = x # typo
                @test_throws CasaCoreTablesError table["column", kw"test"] = Float16(0) # incorrect type
                Tables.remove_keyword!(table, "column", kw"test")
            end
        end

        Tables.delete(table)
    end

    @testset "old tests" begin
        path = tempname() * ".ms"
        table = Tables.create(path)

        @test Tables.num_rows(table) == 0
        @test Tables.num_columns(table) == 0
        @test Tables.num_keywords(table) == 0

        Tables.add_rows!(table, 10)

        @test Tables.column_exists(table, "SKA_DATA") == false
        table["SKA_DATA"] = ones(10)
        @test Tables.column_exists(table, "SKA_DATA") == true
        Tables.remove_column!(table, "SKA_DATA")
        @test Tables.column_exists(table, "SKA_DATA") == false

        ant1 = Array{Int32}(10)
        ant2 = Array{Int32}(10)
        uvw = Array{Float64}(3, 10)
        time = Array{Float64}(10)
        data = Array{ComplexF64}(4, 109, 10)
        model = Array{ComplexF64}(4, 109, 10)
        corrected = Array{ComplexF64}(4, 109, 10)
        freq = Array{Float64}(109, 1)

        rand!(ant1)
        rand!(ant2)
        rand!(uvw)
        rand!(time)
        rand!(data)
        rand!(model)
        rand!(corrected)
        rand!(freq)

        table["ANTENNA1"] = ant1
        table["ANTENNA2"] = ant2
        table["UVW"] = uvw
        table["TIME"] = time
        table["DATA"] = data
        table["MODEL_DATA"] = model
        table["CORRECTED_DATA"] = corrected

        @test Tables.num_columns(table) == 7
        @test Tables.column_exists(table, "ANTENNA1") == true
        @test Tables.column_exists(table, "ANTENNA2") == true
        @test Tables.column_exists(table, "UVW") == true
        @test Tables.column_exists(table, "TIME") == true
        @test Tables.column_exists(table, "DATA") == true
        @test Tables.column_exists(table, "MODEL_DATA") == true
        @test Tables.column_exists(table, "CORRECTED_DATA") == true
        @test Tables.column_exists(table, "FABRICATED_DATA") == false

        @test table["ANTENNA1"] == ant1
        @test table["ANTENNA2"] == ant2
        @test table["UVW"] == uvw
        @test table["TIME"] == time
        @test table["DATA"] == data
        @test table["MODEL_DATA"] == model
        @test table["CORRECTED_DATA"] == corrected
        @test_throws CasaCoreTablesError table["FABRICATED_DATA"]

        @test table["ANTENNA1", 1] == ant1[1]
        @test table["ANTENNA2", 1] == ant2[1]
        @test table["UVW", 1] == uvw[:, 1]
        @test table["TIME", 1] == time[1]
        @test table["DATA", 1] == data[:, :, 1]
        @test table["MODEL_DATA", 1] == model[:, :, 1]
        @test table["CORRECTED_DATA", 1] == corrected[:, :, 1]
        @test_throws CasaCoreTablesError table["FABRICATED_DATA", 1]

        rand!(ant1)
        rand!(ant2)
        rand!(uvw)
        rand!(time)
        rand!(data)
        rand!(model)
        rand!(corrected)
        rand!(freq)

        table["ANTENNA1", 1] = ant1[1]
        table["ANTENNA2", 1] = ant2[1]
        table["UVW", 1] = uvw[:, 1]
        table["TIME", 1] = time[1]
        table["DATA", 1] = data[:, :, 1]
        table["MODEL_DATA", 1] = model[:, :, 1]
        table["CORRECTED_DATA", 1] = corrected[:, :, 1]
        @test_throws CasaCoreTablesError table["FABRICATED_DATA", 1] = 1

        @test table["ANTENNA1", 1] == ant1[1]
        @test table["ANTENNA2", 1] == ant2[1]
        @test table["UVW", 1] == uvw[:, 1]
        @test table["TIME", 1] == time[1]
        @test table["DATA", 1] == data[:, :, 1]
        @test table["MODEL_DATA", 1] == model[:, :, 1]
        @test table["CORRECTED_DATA", 1] == corrected[:, :, 1]
        @test_throws CasaCoreTablesError table["FABRICATED_DATA", 1]

        # Fully populate the columns again for the test where the
        # table is opened again
        table["ANTENNA1"] = ant1
        table["ANTENNA2"] = ant2
        table["UVW"] = uvw
        table["TIME"] = time
        table["DATA"] = data
        table["MODEL_DATA"] = model
        table["CORRECTED_DATA"] = corrected

        subtable = Tables.create("$path/SPECTRAL_WINDOW")
        Tables.add_rows!(subtable, 1)
        subtable["CHAN_FREQ"] = freq
        @test subtable["CHAN_FREQ"] == freq

        @test Tables.num_keywords(table) == 0
        table[kw"SPECTRAL_WINDOW"] = subtable
        @test Tables.num_keywords(table) == 1
        subtable′ = table[kw"SPECTRAL_WINDOW"]
        @test subtable′["CHAN_FREQ"] == freq

        table["DATA", kw"Hello,"] = "World!"
        @test table["DATA", kw"Hello,"] == "World!"
        table[kw"MICHAEL_IS_COOL"] = true
        @test table[kw"MICHAEL_IS_COOL"] == true
        table[kw"PI"] = 3.14159
        @test table[kw"PI"] == 3.14159

        @test_throws CasaCoreTablesError table[kw"BOBBY_TABLES"]
        @test_throws CasaCoreTablesError table["DATA", kw"SYSTEMATIC_ERRORS"]
        @test_throws CasaCoreTablesError table["SKA_DATA", kw"SCHEDULE"]

        Tables.close(table)
        Tables.close(subtable)
        Tables.close(subtable′)

        # Test opening the table again
        table′ = Tables.open(path)
        @test table′["ANTENNA1"] == ant1
        @test table′["ANTENNA2"] == ant2
        @test table′["UVW"] == uvw
        @test table′["TIME"] == time
        @test table′["DATA"] == data
        @test table′["MODEL_DATA"] == model
        @test table′["CORRECTED_DATA"] == corrected
        @test_throws CasaCoreTablesError table′["FABRICATED_DATA"]
        Tables.close(table′)

        Tables.delete(table)
    end
end
