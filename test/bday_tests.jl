@testset "BDay Type" begin

    @testset "Construction" begin
        # From HolidayCalendar instance
        bd1 = BDay(5, BusinessDays.USNYSE())
        @test Dates.value(bd1) == 5
        @test BusinessDays.calendar(bd1) == BusinessDays.USNYSE()

        # From Symbol
        bd2 = BDay(3, :USNYSE)
        @test Dates.value(bd2) == 3
        @test BusinessDays.calendar(bd2) == BusinessDays.USNYSE()

        # From String
        bd3 = BDay(-2, "Brazil")
        @test Dates.value(bd3) == -2
        @test BusinessDays.calendar(bd3) == BusinessDays.BRSettlement()

        # Zero value
        bd4 = BDay(0, :USNYSE)
        @test Dates.value(bd4) == 0

        # Negative value
        bd5 = BDay(-10, :USNYSE)
        @test Dates.value(bd5) == -10

        # Using string values
        bd6 = BDay("100", :USNYSE)
        @test Dates.value(bd6) == 100
        bd7 = BDay("-500", :USNYSE)
        @test Dates.value(bd7) == -500

        # Invalid calendar should throw
        @test_throws Exception BDay(5, :InvalidCalendar)
    end

    @testset "Type Hierarchy" begin
        bd = BDay(5, :USNYSE)

        @test bd isa Dates.DatePeriod
        @test bd isa Dates.Period
        @test bd isa BDay{BusinessDays.USNYSE}
    end

    @testset "Equality and Hashing" begin
        bd1 = BDay(5, :USNYSE)
        bd2 = BDay(5, :USNYSE)
        bd3 = BDay(5, :Brazil)
        bd4 = BDay(3, :USNYSE)

        @test bd1 == bd2
        @test bd1 != bd3  # Different calendar
        @test bd1 != bd4  # Different value

        @test hash(bd1) == hash(bd2)
        @test hash(bd1) != hash(bd3)

        # Works in Set
        s = Set([bd1, bd2, bd3])
        @test length(s) == 2

        # Works in Dict
        d = Dict(bd1 => "nyse5")
        @test d[bd2] == "nyse5"
    end

    @testset "Comparison" begin
        bd1 = BDay(5, :USNYSE)
        bd2 = BDay(3, :USNYSE)
        bd3 = BDay(5, :Brazil)

        @test bd2 < bd1
        @test bd1 > bd2
        @test bd1 >= bd1
        @test bd2 <= bd1

        # Different calendars should throw
        @test_throws ArgumentError bd1 < bd3
        @test_throws ArgumentError bd1 > bd3
    end

    @testset "Negation" begin
        bd = BDay(5, :USNYSE)
        neg_bd = -bd

        @test Dates.value(neg_bd) == -5
        @test BusinessDays.calendar(neg_bd) == BusinessDays.USNYSE()
        @test -(-bd) == bd
    end

    @testset "BDay Arithmetic - Same Calendar" begin
        bd1 = BDay(5, :USNYSE)
        bd2 = BDay(3, :USNYSE)

        # Addition
        result = bd1 + bd2
        @test Dates.value(result) == 8
        @test BusinessDays.calendar(result) == BusinessDays.USNYSE()

        # Subtraction
        result = bd1 - bd2
        @test Dates.value(result) == 2
        @test BusinessDays.calendar(result) == BusinessDays.USNYSE()

        # With negative
        bd_neg = BDay(-2, :USNYSE)
        @test Dates.value(bd1 + bd_neg) == 3
    end

    @testset "BDay Arithmetic - Different Calendar (Error)" begin
        bd_nyse = BDay(5, :USNYSE)
        bd_brazil = BDay(3, :Brazil)

        @test_throws ArgumentError bd_nyse + bd_brazil
        @test_throws ArgumentError bd_nyse - bd_brazil
    end

    @testset "BDay Arithmetic - Parametric Calendar Same Type Different Instance" begin
        # Australia(:ACT) and Australia(:NSW) are the same type but different instances
        bd_act = BDay(5, BusinessDays.Australia(:ACT))
        bd_nsw = BDay(3, BusinessDays.Australia(:NSW))

        # Should throw because they are different calendars even though same type
        @test_throws ArgumentError bd_act + bd_nsw
        @test_throws ArgumentError bd_act - bd_nsw
        @test_throws ArgumentError bd_act < bd_nsw

        # Same instance should work
        bd_act2 = BDay(3, BusinessDays.Australia(:ACT))
        @test Dates.value(bd_act + bd_act2) == 8
    end

    @testset "Scalar Multiplication" begin
        bd = BDay(5, :USNYSE)

        # Integer multiplication
        @test Dates.value(bd * 2) == 10
        @test Dates.value(2 * bd) == 10
        @test Dates.value(bd * -1) == -5

        # Calendar preserved
        @test BusinessDays.calendar(bd * 3) == BusinessDays.USNYSE()
    end

    @testset "Division" begin
        bd = BDay(10, :USNYSE)

        # Exact division with /
        @test Dates.value(bd / 2) == 5
        @test BusinessDays.calendar(bd / 2) == BusinessDays.USNYSE()

        # Inexact division throws InexactError (consistent with Dates.Day)
        @test_throws InexactError bd / 3

        # Integer division with div
        @test Dates.value(div(bd, 2)) == 5
        @test Dates.value(div(bd, 3)) == 3
        @test BusinessDays.calendar(div(bd, 2)) == BusinessDays.USNYSE()

        # Floor division with fld
        @test Dates.value(fld(bd, 3)) == 3
        @test Dates.value(fld(BDay(-10, :USNYSE), 3)) == -4  # fld rounds toward -Inf
        @test BusinessDays.calendar(fld(bd, 3)) == BusinessDays.USNYSE()
    end

    @testset "Modulo and Remainder" begin
        bd1 = BDay(10, :USNYSE)
        bd2 = BDay(3, :USNYSE)

        # mod
        @test Dates.value(mod(bd1, bd2)) == 1
        @test BusinessDays.calendar(mod(bd1, bd2)) == BusinessDays.USNYSE()

        # rem
        @test Dates.value(rem(bd1, bd2)) == 1
        @test BusinessDays.calendar(rem(bd1, bd2)) == BusinessDays.USNYSE()

        # mod vs rem with negative values
        bd_neg = BDay(-10, :USNYSE)
        @test Dates.value(mod(bd_neg, bd2)) == 2   # mod result has sign of divisor
        @test Dates.value(rem(bd_neg, bd2)) == -1  # rem result has sign of dividend

        # Different calendars should throw
        bd_brazil = BDay(3, :Brazil)
        @test_throws ArgumentError mod(bd1, bd_brazil)
        @test_throws ArgumentError rem(bd1, bd_brazil)

        # mod and rem with Real (scalar)
        @test Dates.value(mod(bd1, 3)) == 1
        @test BusinessDays.calendar(mod(bd1, 3)) == BusinessDays.USNYSE()
        @test Dates.value(rem(bd1, 3)) == 1
        @test BusinessDays.calendar(rem(bd1, 3)) == BusinessDays.USNYSE()

        # mod vs rem with negative BDay and Real divisor
        @test Dates.value(mod(bd_neg, 3)) == 2   # mod result has sign of divisor
        @test Dates.value(rem(bd_neg, 3)) == -1  # rem result has sign of dividend
    end

    @testset "Absolute Value" begin
        bd_pos = BDay(5, :USNYSE)
        bd_neg = BDay(-5, :USNYSE)
        bd_zero = BDay(0, :USNYSE)

        @test Dates.value(abs(bd_pos)) == 5
        @test Dates.value(abs(bd_neg)) == 5
        @test Dates.value(abs(bd_zero)) == 0

        @test BusinessDays.calendar(abs(bd_neg)) == BusinessDays.USNYSE()
    end

    @testset "Date + BDay" begin
        # Tuesday Jan 3, 2023 (Jan 2 is NYSE holiday - New Year observed)
        dt = Dates.Date(2023, 1, 3)  # Tuesday - first business day of 2023
        bd = BDay(5, :USNYSE)
        result = dt + bd

        # Jan 3 + 5 business days = Jan 10 (skipping weekend Jan 7-8)
        @test result == Dates.Date(2023, 1, 10)

        # Verify same as advancebdays
        @test result == advancebdays(:USNYSE, dt, 5)

        # Commutativity
        @test bd + dt == dt + bd
    end

    @testset "Date - BDay" begin
        dt = Dates.Date(2023, 1, 10)  # Tuesday
        bd = BDay(5, :USNYSE)
        result = dt - bd

        # Should go back to Tuesday Jan 3
        @test result == Dates.Date(2023, 1, 3)

        # Verify same as advancebdays with negative
        @test result == advancebdays(:USNYSE, dt, -5)
    end

    @testset "Date Arithmetic with Holidays" begin
        # Test around MLK Day 2023 (Monday Jan 16 - NYSE closed)
        dt = Dates.Date(2023, 1, 13)  # Friday before MLK Day
        bd = BDay(1, :USNYSE)

        # 1 business day after Friday should skip weekend AND Monday holiday
        result = dt + bd
        @test result == Dates.Date(2023, 1, 17)  # Tuesday

        # Going backward
        dt2 = Dates.Date(2023, 1, 17)  # Tuesday after MLK Day
        result2 = dt2 - BDay(1, :USNYSE)
        @test result2 == Dates.Date(2023, 1, 13)  # Friday before
    end

    @testset "BDay with Zero Value" begin
        # Use Jan 3, 2023 which is definitely a business day (Jan 2 is NYSE holiday)
        dt = Dates.Date(2023, 1, 3)  # Tuesday (business day)
        bd_zero = BDay(0, :USNYSE)

        @test dt + bd_zero == dt
        @test dt - bd_zero == dt

        # On a weekend, should move to next business day (tobday behavior)
        dt_sat = Dates.Date(2023, 1, 7)  # Saturday
        result = dt_sat + bd_zero
        @test result == Dates.Date(2023, 1, 9)  # Monday
    end

    @testset "Show/Display" begin
        bd1 = BDay(1, :USNYSE)
        bd5 = BDay(5, :USNYSE)
        bd_neg = BDay(-3, :Brazil)

        # string() uses print() which uses Dates._units
        @test occursin("1 business day", string(bd1))
        @test occursin("5 business days", string(bd5))
        @test occursin("-3 business days", string(bd_neg))

        # repr uses show() which gives compact form
        @test occursin("BDay", repr(bd5))
        @test occursin("USNYSE", repr(bd1))

        # Test that the MIME text/plain show works (used in REPL) - includes calendar
        io = IOBuffer()
        show(io, MIME"text/plain"(), bd1)
        s1 = String(take!(io))
        @test occursin("1 business day", s1)
        @test occursin("USNYSE", s1)

        show(io, MIME"text/plain"(), bd5)
        s5 = String(take!(io))
        @test occursin("5 business days", s5)
    end

    @testset "Broadcasting" begin
        # Use dates that are definitely business days (Jan 3-5, 2023)
        dates = [Dates.Date(2023, 1, 3), Dates.Date(2023, 1, 4), Dates.Date(2023, 1, 5)]
        bd = BDay(1, :USNYSE)

        results = dates .+ bd

        @test results[1] == Dates.Date(2023, 1, 4)
        @test results[2] == Dates.Date(2023, 1, 5)
        @test results[3] == Dates.Date(2023, 1, 6)
    end

    @testset "DateTime + BDay" begin
        dt = Dates.DateTime(2023, 1, 3, 12, 30, 0)
        bd = BDay(5, :USNYSE)

        @test dt + bd == Dates.Date(2023, 1, 10)
        @test bd + dt == Dates.Date(2023, 1, 10)
        @test dt - bd == Dates.Date(2022, 12, 23)
    end

    @testset "Sign Operations (Inherited from Period)" begin
        bd_pos = BDay(5, :USNYSE)
        bd_neg = BDay(-5, :USNYSE)
        bd_zero = BDay(0, :USNYSE)

        # sign returns Int
        @test sign(bd_pos) == 1
        @test sign(bd_neg) == -1
        @test sign(bd_zero) == 0
    end

    @testset "one (Inherited from Period)" begin
        bd = BDay(5, :USNYSE)

        # one returns the multiplicative identity (1), not BDay(1, ...)
        @test one(bd) == 1
        @test one(typeof(bd)) == 1
    end

    @testset "zero and iszero" begin
        bd = BDay(5, :USNYSE)
        bd_zero = BDay(0, :USNYSE)

        # zero requires an instance (needs calendar)
        @test Dates.value(zero(bd)) == 0
        @test BusinessDays.calendar(zero(bd)) == BusinessDays.USNYSE()

        # iszero
        @test iszero(bd_zero) == true
        @test iszero(bd) == false
    end

    @testset "GCD and LCM" begin
        bd1 = BDay(10, :USNYSE)
        bd2 = BDay(4, :USNYSE)

        # gcd
        @test Dates.value(gcd(bd1, bd2)) == 2
        @test BusinessDays.calendar(gcd(bd1, bd2)) == BusinessDays.USNYSE()

        # lcm
        @test Dates.value(lcm(bd1, bd2)) == 20
        @test BusinessDays.calendar(lcm(bd1, bd2)) == BusinessDays.USNYSE()

        # gcdx
        (g, x, y) = gcdx(bd1, bd2)
        @test g == BDay(2, :USNYSE)
        @test (x, y) == (1, -2)

        # Different calendars should throw
        bd_brazil = BDay(4, :Brazil)
        @test_throws ArgumentError gcd(bd1, bd_brazil)
        @test_throws ArgumentError lcm(bd1, bd_brazil)
    end

    @testset "BDay / BDay and BDay ÷ BDay (Inherited from Period)" begin
        bd1 = BDay(10, :USNYSE)
        bd2 = BDay(2, :USNYSE)
        bd3 = BDay(3, :USNYSE)

        # Division between BDays returns Float64 (inherited)
        @test bd1 / bd2 == 5.0
        @test bd1 / bd3 ≈ 10/3

        # Integer division between BDays returns Int (inherited)
        @test bd1 ÷ bd2 == 5
        @test bd1 ÷ bd3 == 3
    end

end
