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

"""
    measure(frame, value, newsys)

Converts the value measured in the given frame of reference into a new coordinate system.

**Arguments:**

* `frame` - an instance of the `ReferenceFrame` type
* `value` - an `Epoch`, `Direction`, or `Position` that will be converted from its current
            coordinate system into the new one
* `newsys` - the new coordinate system

Note that the reference frame must have all the required information to convert between the
coordinate systems. Not all conversions require the same information!

**Examples:**

``` julia
# Compute the azimuth and elevation of the Sun
measure(frame, Direction(dir"SUN"), dir"AZEL")

# Compute the ITRF position of the VLA
measure(frame, observatory("VLA"), pos"ITRF")

# Compute the atomic time from a UTC time
measure(frame, Epoch(epoch"UTC", 50237.29*u"d"), epoch"TAI")
```
"""
measure

mutable struct ReferenceFrame
    epoch::Union{Missing,Epoch}
    direction::Union{Missing,Direction}
    position::Union{Missing,Position}
end

"""
    ReferenceFrame

The `ReferenceFrame` type contains information about the frame of reference to use when converting
between coordinate systems. For example converting from J2000 coordinates to AZEL coordinates
requires knowledge of the observer's location, and the current time. However converting between
B1950 coordinates and J2000 coordinates requires no additional information about the observer's
frame of reference.

Use the `set!` function to add information to the given frame of reference.

**Example:**

``` julia
frame = ReferenceFrame()
set!(frame, observatory("VLA")) # set the observer's position to the location of the VLA
set!(frame, Epoch(epoch"UTC", 50237.29*u"d")) # set the current UTC time
```
"""
function ReferenceFrame()
    return ReferenceFrame(nothing, nothing, nothing)
end

set!(frame::ReferenceFrame, epoch::Epoch) = frame.epoch = epoch
set!(frame::ReferenceFrame, direction::Direction) = frame.direction = direction
set!(frame::ReferenceFrame, position::Position) = frame.position = position

# TODO we don't actually use the reference frame in the epoch conversions, can we come up with a
# new API that doesn't require it?

function measure(frame::ReferenceFrame, epoch::Epoch, newsys::Epochs.System)
    return ccall(("convertEpoch", libcasacorewrapper), Epoch, (Ref{Epoch}, Cint), epoch,
                 newsys)
end

function measure(frame::ReferenceFrame, direction::Direction, newsys::Directions.System)
    return ccall(("convertDirection", libcasacorewrapper), Direction,
                 (Ref{Direction}, Cint, Ref{ReferenceFrame}),
                 direction, newsys, frame)
end

function measure(frame::ReferenceFrame, direction::UnnormalizedDirection, newsys)
    return measure(frame, Direction(direction), newsys)
end

function measure(frame::ReferenceFrame, position::Position, newsys::Positions.System)
    return ccall(("convertPosition", libcasacorewrapper), Position,
                 (Ref{Position}, Cint, Ref{ReferenceFrame}),
                 position, newsys, frame)
end

function measure(frame::ReferenceFrame, baseline::Baseline, newsys::Baselines.System)
    return ccall(("convertBaseline", libcasacorewrapper), Baseline,
                 (Ref{Baseline}, Cint, Ref{ReferenceFrame}),
                 baseline, newsys, frame)
end

# Define conversions and routines for comparing the different kinds of measures.

@noinline inconsistent_coordinate_system_error() = err("inconsistent coordinate system")

function check_coordinate_system(measure1, measure2)
    if measure1.sys != measure2.sys
        inconsistent_coordinate_system_error()
    end
end

function Base.:(==)(lhs::Directions.System, rhs::Positions.System)
    if lhs == Directions.ITRF && rhs == Positions.ITRF
        return true
    else
        return false
    end
end

function Base.:(==)(lhs::Directions.System, rhs::Baselines.System)
    return Int32(lhs) == Int32(rhs)
end

function Base.:(==)(lhs::Positions.System, rhs::Baselines.System)
    if lhs == Positions.ITRF && rhs == Baselines.ITRF
        return true
    else
        return false
    end
end

Base.:(==)(lhs::Positions.System, rhs::Directions.System) = rhs == lhs
Base.:(==)(lhs::Baselines.System, rhs::Directions.System) = rhs == lhs
Base.:(==)(lhs::Baselines.System, rhs::Positions.System) = rhs == lhs

function Direction(position::Position)
    if position.sys == pos"ITRF"
        Direction(dir"ITRF", position.x, position.y, position.z)
    else
        err("cannot convert given coordinate system to a `Direction`")
    end
end
