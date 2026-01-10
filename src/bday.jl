
"""
    BDay{C<:HolidayCalendar} <: Dates.DatePeriod

Represents a business day period relative to a specific holiday calendar.

Unlike `Dates.Day` which represents calendar days, `BDay` represents business
days that skip weekends and holidays according to the specified calendar.

# Constructors
- `BDay(value, calendar::HolidayCalendar)`
- `BDay(value, calendar::Symbol)` - e.g., `BDay(5, :USNYSE)`
- `BDay(value, calendar::AbstractString)` - e.g., `BDay(5, "USNYSE")`

# Examples
```jldoctest
julia> using BusinessDays, Dates

julia> bd = BDay(5, :USNYSE)
5 business days (USNYSE)

julia> Dates.value(bd)
5

julia> Date(2023, 1, 2) + BDay(5, :USNYSE)  # Advance 5 business days
2023-01-10

julia> BDay(5, :USNYSE) + BDay(3, :USNYSE)  # BDay arithmetic
8 business days (USNYSE)
```

!!! warning "Mixed Calendar Operations"
    Operations between BDay periods with different calendars will throw
    an `ArgumentError`. This is intentional since combining business days
    from different calendars produces ambiguous results.
"""
struct BDay{C<:HolidayCalendar} <: Dates.DatePeriod
    value::Int64
    calendar::C

    function BDay(x, calendar::C) where {C<:HolidayCalendar}
        new{C}(_align_value(x), _align_calendar(calendar))
    end
end

_align_value(x) = convert(Int64, x)
_align_value(x::AbstractString) = Base.parse(Int64, x)
_align_calendar(c) = c
_align_calendar(c::Symbol) = convert(HolidayCalendar, c)
_align_calendar(c::AbstractString) = convert(HolidayCalendar, c)

# Convenience constructors
BDay(value, calendar::Symbol) = BDay(value, convert(HolidayCalendar, calendar))
BDay(value, calendar::AbstractString) = BDay(value, convert(HolidayCalendar, calendar))

# Accessor functions

"""
    calendar(bd::BDay) -> HolidayCalendar

Returns the holiday calendar associated with this BDay period.
"""
calendar(bd::BDay) = bd.calendar

# Equality and hashing
Base.:(==)(bd1::BDay, bd2::BDay) = Dates.value(bd1) == Dates.value(bd2) && calendar(bd1) == calendar(bd2)
Base.hash(bd::BDay, h::UInt) = hash(calendar(bd), hash(Dates.value(bd), h))

# Comparison (same calendar only)
function Base.isless(bd1::BDay{C}, bd2::BDay{C}) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot compare BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    return Dates.value(bd1) < Dates.value(bd2)
end

function Base.isless(bd1::BDay, bd2::BDay)
    throw(ArgumentError(
        "Cannot compare BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end

# Negation
Base.:(-)(bd::BDay) = BDay(-Dates.value(bd), calendar(bd))

# BDay + BDay (same calendar type)
function Base.:(+)(bd1::BDay{C}, bd2::BDay{C}) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot add BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    return BDay(Dates.value(bd1) + Dates.value(bd2), calendar(bd1))
end

# BDay + BDay (different calendar types - always error)
function Base.:(+)(bd1::BDay, bd2::BDay)
    throw(ArgumentError(
        "Cannot add BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end

# BDay - BDay (same calendar type)
function Base.:(-)(bd1::BDay{C}, bd2::BDay{C}) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot subtract BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    return BDay(Dates.value(bd1) - Dates.value(bd2), calendar(bd1))
end

# BDay - BDay (different calendar types - always error)
function Base.:(-)(bd1::BDay, bd2::BDay)
    throw(ArgumentError(
        "Cannot subtract BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end

# Scalar multiplication
Base.:(*)(bd::BDay, x::Real) = BDay(Dates.value(bd) * x, calendar(bd))
Base.:(*)(x::Real, bd::BDay) = bd * x

# Division
Base.:(/)(bd::BDay, x::Real) = BDay(Dates.value(bd) / x, calendar(bd))
function Base.div(bd1::BDay{C}, bd2::BDay{C}, r::RoundingMode) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot compute div of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    div(Dates.value(bd1), Dates.value(bd2), r)
end
function Base.div(bd1::BDay, bd2::BDay, ::RoundingMode)
    throw(ArgumentError(
        "Cannot compute div of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end
Base.div(bd::BDay, x::Real, r::RoundingMode) = BDay(div(Dates.value(bd), Int64(x), r), calendar(bd))

# mod/rem between BDays (same calendar only)
function Base.mod(bd1::BDay{C}, bd2::BDay{C}) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot compute mod of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    return BDay(mod(Dates.value(bd1), Dates.value(bd2)), calendar(bd1))
end

function Base.mod(bd1::BDay, bd2::BDay)
    throw(ArgumentError(
        "Cannot compute mod of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end

Base.mod(bd::BDay, x::Real) = BDay(mod(Dates.value(bd), Int64(x)), calendar(bd))

function Base.rem(bd1::BDay{C}, bd2::BDay{C}) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot compute rem of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    return BDay(rem(Dates.value(bd1), Dates.value(bd2)), calendar(bd1))
end

function Base.rem(bd1::BDay, bd2::BDay)
    throw(ArgumentError(
        "Cannot compute rem of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end

Base.rem(bd::BDay, x::Real) = BDay(rem(Dates.value(bd), Int64(x)), calendar(bd))

# Absolute value
Base.abs(bd::BDay) = BDay(abs(Dates.value(bd)), calendar(bd))

# zero - need custom implementation since BDay requires a calendar
Base.zero(bd::BDay) = BDay(0, calendar(bd))

# gcd/lcm between BDays (same calendar only)
function Base.gcd(bd1::BDay{C}, bd2::BDay{C}) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot compute gcd of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    return BDay(gcd(Dates.value(bd1), Dates.value(bd2)), calendar(bd1))
end

function Base.gcd(bd1::BDay, bd2::BDay)
    throw(ArgumentError(
        "Cannot compute gcd of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end

function Base.lcm(bd1::BDay{C}, bd2::BDay{C}) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot compute lcm of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    return BDay(lcm(Dates.value(bd1), Dates.value(bd2)), calendar(bd1))
end

function Base.lcm(bd1::BDay, bd2::BDay)
    throw(ArgumentError(
        "Cannot compute lcm of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end

function Base.gcdx(bd1::BDay{C}, bd2::BDay{C}) where {C<:HolidayCalendar}
    calendar(bd1) == calendar(bd2) || throw(ArgumentError(
        "Cannot compute gcdx of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
    g, x, y = gcdx(Dates.value(bd1), Dates.value(bd2))
    return (BDay(g, calendar(bd1)), x, y)
end
function Base.gcdx(bd1::BDay, bd2::BDay)
    throw(ArgumentError(
        "Cannot compute gcdx of BDay periods with different calendars: $(calendar(bd1)) vs $(calendar(bd2))"))
end

# Display - need to define both show and print to override Dates.Period defaults
# Helper to get a clean calendar name for display
_calendar_name(hc::HolidayCalendar) = string(typeof(hc).name.name)

# The show method for compact representation (e.g., in arrays)
function Base.show(io::IO, bd::BDay)
    print(io, "BDay(", Dates.value(bd), ", ", _calendar_name(calendar(bd)), ")")
end

# For text/plain MIME (REPL display)
function Base.show(io::IO, ::MIME"text/plain", bd::BDay)
    v = Dates.value(bd)
    print(io, v, " business day")
    abs(v) != 1 && print(io, "s")
    print(io, " (", _calendar_name(calendar(bd)), ")")
end

# Override Dates._units to avoid MethodError when print(::Period) is called
Dates._units(bd::BDay) = " business day" * (abs(Dates.value(bd)) == 1 ? "" : "s")

# Broadcasting support
Base.broadcastable(bd::BDay) = Ref(bd)

# Date + BDay
Base.:(+)(dt::Dates.Date, bd::BDay) = advancebdays(calendar(bd), dt, Dates.value(bd))

# BDay + Date (commutativity)
Base.:(+)(bd::BDay, dt::Dates.Date) = dt + bd

# Date - BDay
Base.:(-)(dt::Dates.Date, bd::BDay) = advancebdays(calendar(bd), convert(Dates.Date, dt), -Dates.value(bd))

# DateTime + BDay returns a Date, keep consistent with rest of package
function Base.:(+)(dt::Dates.DateTime, bd::BDay)
    convert(Dates.Date, dt) + bd
end

Base.:(+)(bd::BDay, dt::Dates.DateTime) = dt + bd

function Base.:(-)(dt::Dates.DateTime, bd::BDay)
    convert(Dates.Date, dt) - bd
end