# astro.rb
# Implementation of astronomical calculations from
# Jean Meuss, <i>Astronomical Algorithms</i>, 2nd English Edition,
# Willmann-Bell, Inc., Richmond, Virginia, 1999, with corrections as of June 15, 2005.


require 'date'

# Augment several classes with new methods.

class Numeric

    # Convert from degrees to radians.
    def to_rad
        self * Math::PI / 180.0
    end

    # Convert from radians to degrees.
    def to_deg
        self * 180.0 / Math::PI
    end

end


class Float

    # Convert Float to Rational.
    # Algorithm from Dave Burt: http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/142199
    def to_r
        return Rational(0, 1) if self == 0.0
        x = self
        negative = false
        if x < 0.0
            x = -x
            negative = true
        end
        f, e = Math.frexp(x)
        # raise unless 0.5 <= f and f < 1.0
        # x = f * 2**e exactly
    
        # Suck up _chunk_ bits at a time; 28 is enough so that we suck
        # up all bits in 2 iterations for all known binary double-
        # precision formats, and small enough to fit in an int.
        chunk = 28
        top = 0
        # invariant: x = (top + f) * 2**e exactly
        while f > 0.0
            f = Math.ldexp(f, chunk)
            digit = f.to_i
            raise unless digit >> chunk == 0
            top = (top << chunk) | digit
            f -= digit
            # raise unless 0.0 <= f and f < 1.0
            e -= chunk
        end
        # raise if top == 0
    
        # now x = top * 2**e exactly; fold in 2**e
        r = Rational(top, 1)
        if e > 0
            r *= 2**e
        else
            r /= 2**-e
        end
        negative ? -r : r
    end
end


class Array
    
    # Evaluate polynomial using Horner's method.
    # Array consists of coefficients of a polynomial, the
    # coefficient of the highest order term first, the
    # constant coefficient last.
    # Returns evaluation of polynomial at +x+.
    #
    # Example: evaluate the polynomial x**2 - 0.5*x + 3.0 where x = 2.0
    #    [1.0, -0.5, 3.0].poly_eval(2.0)   # => 6.0
    def poly_eval(x)
        self.inject(0.0) {|p, a| p*x + a}
    end

end


class DateTime

    # Adjust dynamical time to UTC.
    # Returns rational number of seconds.
    def to_utc
        self - Astro.delta_T(self).to_r / 86400     # convert from seconds to days
    end

    # Truncate date/time to date.
    # Returns a Date object for the given DateTime.
    def to_date
        Date.new(year, month, day)
    end

end


module Astro
    
    VERSION = '0.0.1'

    # Compute difference between dynamical time and UTC in seconds.
    # See http://sunearth.gsfc.nasa.gov/eclipse/SEcat5/deltatpoly.html.
    # Good from -1999 to +3000.
    #
    # Example: compute the difference between dynamical time and UTC for January 1, 2007.
    #   Astro.delta_T(DateTime.new(2007, 1, 1))         # => 65.465744703125
    def Astro.delta_T(date)

        year = date.year.to_f
        y = year + (date.month.to_f - 0.5) / 12.0

        case
        when year < -500.0
            u = (year - 1820.0) / 100.0
            -20.0 + 32.0*u*u
        when year < 500.0
            u = y / 100.0
            [0.0090316521, 0.022174192, -0.1798452, -5.952053, 33.78311, -1014.41, 10583.6].poly_eval(u)
        when year < 1600.0
            u = (y - 1000.0) / 100.0
            [0.0083572073, -0.005050998, -0.8503463, 0.319781, 71.23472, -556.01, 1574.2].poly_eval(u)
        when year < 1700.0
            t = y - 1600.0
            [1.0/7129.0, -0.01532, -0.9808, 120.0].poly_eval(t)
        when year < 1800.0
            t = y - 1700.0
            [-1.0/1174000.0, 0.00013336, -0.0059285, 0.1603, 8.83].poly_eval(t)
        when year < 1860.0
            t = y - 1800.0
            [0.000000000875, -0.0000001699, 0.0000121272, -0.00037436, 0.0041116, 0.0068612, -0.332447, 13.72].poly_eval(t)
        when year < 1900.0
            t = y - 1860.0
            [1.0/233174.0, -0.0004473624, 0.01680668, -0.251754, 0.5737, 7.62].poly_eval(t)
        when year < 1920.0
            t = y - 1900.0
            [-0.000197, 0.0061966, -0.0598939, 1.494119, -2.79].poly_eval(t)
        when year < 1941.0
            t = y - 1920.0
            [0.0020936, -0.076100, 0.84493, 21.20].poly_eval(t)
        when year < 1961.0
            t = y - 1950.0
            [1.0/2547.0, -1.0/233.0, 0.407, 29.07].poly_eval(t)
        when year < 1986.0
            t = y - 1975.0
            [-1.0/718.0, -1.0/260.0, 1.067, 45.45].poly_eval(t)
        when year < 2005.0
            t = y - 2000.0
            [0.00002373599, 0.000651814, 0.0017275, -0.060374, 0.3345, 63.86].poly_eval(t)
        when year < 2050.0
            t = y - 2000.0
            [0.005589, 0.32217, 62.92].poly_eval(t)
        when year < 2150.0
            -20.0 + 32.0*((y - 1820.0)/100.0)**2 - 0.5628*(2150.0 - y)
        else
            u = (year - 1820.0) / 100.0
            -20.0 + 32*u*u
        end
    end

    # =Phases of the Moon

    # :stopdoc:
    # New and Old Moon
    Table_49B = [   # page 351
       # new moon  full moon E    F     M     M'    O
        [ 0.00002,  0.00002, 0,  0.0,  0.0,  4.0,  0.0],
        [-0.00002, -0.00002, 0,  0.0,  1.0,  3.0,  0.0],
        [-0.00002, -0.00002, 0, -2.0, -1.0,  1.0,  0.0],
        [ 0.00003,  0.00003, 0,  2.0, -1.0,  1.0,  0.0],
        [-0.00003, -0.00003, 0,  2.0,  1.0,  1.0,  0.0],
        [ 0.00003,  0.00003, 0,  2.0,  0.0,  2.0,  0.0],
        [ 0.00003,  0.00003, 0, -2.0,  1.0,  1.0,  0.0],
        [ 0.00004,  0.00004, 0,  0.0,  3.0,  0.0,  0.0],
        [ 0.00004,  0.00004, 0, -2.0,  0.0,  2.0,  0.0],
        [-0.00007, -0.00007, 0,  0.0,  2.0,  1.0,  0.0],
        [-0.00017, -0.00017, 0,  0.0,  0.0,  0.0,  1.0],
        [-0.00024, -0.00024, 1,  0.0, -1.0,  2.0,  0.0],
        [ 0.00038,  0.00038, 1, -2.0,  1.0,  0.0,  0.0],
        [ 0.00042,  0.00042, 1,  2.0,  1.0,  0.0,  0.0],
        [-0.00042, -0.00042, 0,  0.0,  0.0,  3.0,  0.0],
        [ 0.00056,  0.00056, 1,  0.0,  1.0,  2.0,  0.0],
        [-0.00057, -0.00057, 0,  2.0,  0.0,  1.0,  0.0],
        [-0.00111, -0.00111, 0, -2.0,  0.0,  1.0,  0.0],
        [ 0.00208,  0.00209, 2,  0.0,  2.0,  0.0,  0.0],
        [-0.00514, -0.00515, 1,  0.0,  1.0,  1.0,  0.0],
        [ 0.00739,  0.00734, 1,  0.0, -1.0,  1.0,  0.0],
        [ 0.01039,  0.01043, 0,  2.0,  0.0,  0.0,  0.0],
        [ 0.01608,  0.01614, 0,  0.0,  0.0,  2.0,  0.0],
        [ 0.17241,  0.17302, 1,  0.0,  1.0,  0.0,  0.0],
        [-0.40720, -0.40614, 0,  0.0,  0.0,  1.0,  0.0]
    ]

    # Planetary arguments
    Table_49A = [      # page 351
        #                    k         T^2
        [299.77,  0.107408, 0.000325, -0.009173],
        [251.88,  0.016321, 0.000165,  0.0     ],
        [251.83, 26.651886, 0.000164,  0.0     ],
        [349.42, 36.412478, 0.000126,  0.0     ],
        [ 84.66, 18.206239, 0.000110,  0.0     ],
        [141.74, 53.303771, 0.000062,  0.0     ],
        [207.14,  2.453732, 0.000060,  0.0     ],
        [154.84,  7.306860, 0.000056,  0.0     ],
        [ 34.52, 27.261239, 0.000047,  0.0     ],
        [207.19,  0.121824, 0.000042,  0.0     ],
        [291.34,  1.844379, 0.000040,  0.0     ],
        [161.72, 24.198154, 0.000037,  0.0     ],
        [239.56, 25.513099, 0.000035,  0.0     ],
        [331.55,  3.592518, 0.000023,  0.0     ]
    ]

    # First and last quarter
    Table_49C = [       # page 352
        #          E    F     M     M'    O
        [-0.00002, 0,  0.0,  1.0,  3.0,  0.0],
        [ 0.00002, 0,  2.0, -1.0,  1.0,  0.0],
        [ 0.00002, 0, -2.0,  0.0,  2.0,  0.0],
        [ 0.00003, 0,  0.0,  3.0,  0.0,  0.0],
        [ 0.00003, 0, -2.0,  1.0,  1.0,  0.0],
        [ 0.00004, 0,  0.0, -2.0,  1.0,  0.0],
        [-0.00004, 0,  2.0,  1.0,  1.0,  0.0],
        [ 0.00004, 0,  2.0,  0.0,  2.0,  0.0],
        [-0.00005, 0, -2.0, -1.0,  1.0,  0.0],
        [-0.00017, 0,  0.0,  0.0,  0.0,  1.0],
        [ 0.00027, 1,  0.0,  1.0,  2.0,  0.0],
        [-0.00028, 2,  0.0,  2.0,  1.0,  0.0],
        [ 0.00032, 1, -2.0,  1.0,  0.0,  0.0],
        [ 0.00032, 1,  2.0,  1.0,  0.0,  0.0],
        [-0.00034, 1,  0.0, -1.0,  2.0,  0.0],
        [-0.00040, 0,  0.0,  0.0,  3.0,  0.0],
        [-0.00070, 0,  2.0,  0.0,  1.0,  0.0],
        [-0.00180, 0, -2.0,  0.0,  1.0,  0.0],
        [ 0.00204, 2,  0.0,  2.0,  0.0,  0.0],
        [ 0.00454, 1,  0.0, -1.0,  1.0,  0.0],
        [ 0.00804, 0,  2.0,  0.0,  0.0,  0.0],
        [ 0.00862, 0,  0.0,  0.0,  2.0,  0.0],
        [-0.01183, 1,  0.0,  1.0,  1.0,  0.0],
        [ 0.17172, 1,  0.0,  1.0,  0.0,  0.0],
        [-0.62801, 0,  0.0,  0.0,  1.0,  0.0]
    ]
    # :startdoc:

    PhaseNew = 0
    PhaseFirstQuarter = 1
    PhaseFull = 2
    PhaseLastQuarter = 3

    # Returns DateTime for phase of Moon.
    # Implementation of algorithm in chapter 49.
    # k:: number of Moon. k = 0 is first New Moon in the year 2000.
    # phase:: Astro::PhaseNew, Astro::PhaseFirstQuarter, Astro::PhaseFull, Astro::PhaseLastQuarter
    #
    # Example: compute the date and time of New Moon #87 (first lunation in 2007).
    #   Astro.date_of_moon(87, Astro::PhaseNew).asctime         # => "Fri Jan 19 04:01:45 2007"
    def Astro.date_of_moon(k, phase)

        k += phase / 4.0

        # t = Julian centuries
        t = k / 1236.85

        # Julian Ephemeris Days
        jde = 2_451_550.097_66      +
              29.530_588_861    * k +
              [0.000_000_000_73, -0.000_000_150, 0.000_154_37, 0.0, 0.0].poly_eval(t)

        # Eccentricity of Earth's orbit
        e   = [-0.000_0074, -0.002_516, 1.0].poly_eval(t)

        # Sun's mean anomaly
        m   = 2.5534                +
              29.105_356_70     * k +
              [-0.000_000_11, -0.000_0014, 0.0, 0.0].poly_eval(t)

        # Moon's mean anomaly
        m_lun = 201.5643            +
              385.816_935_28    * k +
              [-0.000_000_058, 0.000_012_38, 0.010_7582, 0.0, 0.0].poly_eval(t)

        # Moon's argument of latitude
        f   = 160.7108              +
              390.670_502_84    * k +
              [0.000_000_011, -0.000_002_27, -0.001_6118, 0.0, 0.0].poly_eval(t)

        # omega = longitude of the ascending node of the lunar orbit
        o   = 124.7746              -
              1.563_755_88      * k +
              [0.000_002_15, 0.002_0672, 0.0, 0.0].poly_eval(t)

        if phase == PhaseNew || phase == PhaseFull     # new moon or full moon

            col = phase == PhaseNew ? 0 : 1   # choose column of coefficient
            corr1 = 0.0
            for term in Table_49B do
                t1 = term[col]
                term[2].times {t1 *= e}
                t2  = term[3] * f
                t2 += term[4] * m
                t2 += term[5] * m_lun
                t2 += term[6] * o
                t2  = Math.sin((t2 % 360.0).to_rad)
                corr1 += t1 * t2
            end

            jde += corr1

        else                                            # first or last quarter
            corr1 = 0.0
            for term in Table_49C do
                t1 = term[0]
                term[1].times {t1 *= e}
                t2  = term[2] * f
                t2 += term[3] * m
                t2 += term[4] * m_lun
                t2 += term[5] * o
                t2 = Math.sin((t2 % 360.0).to_rad)
                corr1 += t1 * t2
            end
            jde += corr1

            w = 0.00002     * Math.cos((2.0*f).to_rad) +
                0.00002     * Math.cos((m_lun + m).to_rad) -
                0.00002     * Math.cos((m_lun - m).to_rad) +
                0.00026     * Math.cos(m_lun.to_rad) -
                0.00038 * e * Math.cos(m.to_rad) +
                0.00306

            if phase == PhaseFirstQuarter
                jde += w            # first quarter
            else
                jde -= w            # last quarter
            end
        end

        # correction for all phases
        corr2 = 0.0
        t2 = t*t
        for term in Table_49A do
            a  = term[0]
            a += term[1] * k
            a += term[3] * t2
            corr2 += Math.sin((a % 360.0).to_rad) * term[2]
        end

        DateTime.jd((jde + corr2).to_r) + 0.5
    end

    # Find number of first lunation (New Moon) for a given year.
    # Lunation 0 is the first New Moon in the year 2000.
    # Returns an integer lunation number.
    #
    # Example: find first lunation of 1776.
    #   Astro.first_lunation_of_year(1776)      # => -2770
    def Astro.first_lunation_of_year(year)
        k = ((year - 2000)*12.3685).floor
        k += 1 while date_of_moon(k, PhaseNew).year < year
        k
    end


    # :stopdoc:
    # Vernal Equinox
    Table_27C = [     # page 179
        # sum(A cos (B + C*t))
        #  A       B           C
        [  8.0,  15.45,  16_859.074],
        [  9.0, 227.73,   1_222.114],
        [ 12.0, 320.81,  34_777.259],
        [ 12.0, 287.11,  31_931.756],
        [ 12.0,  95.39,  14_577.848],
        [ 14.0, 199.76,  31_436.921],
        [ 16.0, 198.04,  62_894.029],
        [ 17.0, 288.79,   4_562.452],
        [ 18.0, 155.12,  67_555.328],
        [ 29.0,  60.93,   4_443.417],
        [ 44.0, 325.15,  31_555.956],
        [ 45.0, 247.54,  29_929.562],
        [ 50.0,  21.02,   2_281.226],
        [ 52.0, 297.17,     150.678],
        [ 58.0, 119.81,  33_718.147],
        [ 70.0, 243.58,   9_037.513],
        [ 74.0, 296.72,   3_034.906],
        [ 77.0, 222.54,  65_928.934],
        [136.0, 171.52,  22_518.443],
        [156.0,  73.14,  45_036.886],
        [182.0,  27.85, 445_267.112],
        [199.0, 342.08,      20.186],
        [203.0, 337.23,  32_964.467],
        [485.0, 324.96,   1_934.136]
    ]
    # :startdoc:

    # Compute date and time of Vernal Equinox for given year.
    # Implementation of low accuracy algorithm in chapter 27.
    # Good from about -1000 to +3000.
    # Returns DateTime of Vernal Equinox.
    #
    # Example: date of Vernal Equinox of 1999.
    #   Astro.date_of_vernal_equinox_low_accuracy(1999).asctime     # => "Sun Mar 21 01:46:59 1999"
    def Astro.date_of_vernal_equinox_low_accuracy(year)
        if year >= 1000         # +1000 to +3000
            y = (year - 2000.0) / 1000.0

            # Julian day of March mean equinox
            jdme = [-0.000_57, -0.004_11, 0.051_69, 365_242.374_04, 2_451_623.809_84].poly_eval(y)

        else                    # -1000 to +1000
            y = year/1000.0

            # Julian day of March mean equinox
            jdme = [-0.000_71,  0.001_11, 0.061_34, 365_242.137_40, 1_721_139.291_89].poly_eval(y)

        end

        # Julian centuries from 2000
        t = (jdme - 2_451_545.0) / 36525.0

        w = (35_999.373 * t - 2.47).to_rad
        lambda = 1.0 + 0.0334*Math.cos(w) + 0.0007 * Math.cos(2.0 * w)
        s = Table_27C.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos((b + c*t).to_rad)}

        ve = jdme + 0.000_01 * s / lambda

        DateTime.jd(ve.to_r) + 0.5
    end

    # Compute date and time of Vernal Equinox for given year.
    # Implementation of higher accuracy algorithm in chapter 27.
    # Returns DateTime of Vernal Equinox.
    #
    # Example: date of Vernal Equinox of 1999.
    #   Astro.date_of_vernal_equinox(1999).asctime      # => "Sun Mar 21 01:46:56 1999"
    def Astro.date_of_vernal_equinox(year)
        est_date = date_of_vernal_equinox_low_accuracy(year)

        5.times do |i|
            sol_long = solar_longitude(est_date)
            sol_long -= 360.0 if sol_long > 180.0
            break if sol_long.abs < 0.000001
            est_date += (58 * Math.sin(-sol_long.to_rad)).to_r
        end

        est_date
    end


    # :stopdoc:
    # Solar Coordinates
    Table_22A = [
           #  D   M   M'  F omega    coef of sin
        [ 2, -1,  0,  2,  2,       -3,      0],
        [ 0,  0,  3,  2,  2,       -3,      0],
        [ 2, -1, -1,  2,  2,       -3,      0],
        [ 0, -1,  1,  2,  2,       -3,      0],
        [ 0,  1,  1,  0,  0,       -3,      0],
        [-1, -1,  1,  0,  0,       -3,      0],
        [ 0,  0, -2,  2,  2,       -3,      0],
        [ 0,  0,  1,  2,  0,        3,      0],
        [ 1,  0,  0,  0,  0,       -4,      0],
        [-2,  1,  0,  0,  0,       -4,      0],
        [-1,  0,  1,  0,  0,       -4,      0],
        [ 0,  0,  1, -2,  0,        4,      0],
        [-2,  1,  0,  2,  1,        4,      0],
        [-2,  0,  2,  0,  1,        4,      0],
        [ 0,  0,  2,  2,  1,       -5,      0],
        [-2,  0,  0,  0,  1,       -5,      0],
        [-2, -1,  0,  2,  1,       -5,      0],
        [ 0, -1,  1,  0,  0,        5,      0],
        [ 2,  0,  0,  0,  1,       -6,      0],
        [ 2,  0, -2,  0,  1,       -6,      0],
        [-2,  0,  1,  2,  1,        6,      0],
        [-2,  0,  2,  2,  2,        6,      0],
        [ 2,  0,  1,  0,  0,        6,      0],
        [ 2,  0,  0,  2,  1,       -7,      0],
        [ 0, -1,  0,  2,  2,       -7,      0],
        [-2,  1,  1,  0,  0,       -7,      0],
        [ 0,  1,  0,  2,  2,        7,      0],
        [ 2,  0,  1,  2,  2,       -8,      0],
        [ 2,  0, -1,  2,  1,      -10,      0],
        [ 0,  0,  2, -2,  0,       11,      0],
        [ 0, -1,  0,  0,  1,      -12,      0],
        [-2,  0,  1,  0,  1,      -13,      0],
        [ 0,  1,  0,  0,  1,      -15,      0],
        [-2,  2,  0,  2,  2,      -16,    0.1],
        [ 2,  0, -1,  0,  1,       16,      0],
        [ 0,  2,  0,  0,  0,       17,   -0.1],
        [ 0,  0, -1,  2,  1,       21,      0],
        [-2,  0,  0,  2,  0,      -22,      0],
        [ 0,  0,  0,  2,  0,       26,      0],
        [-2,  0,  1,  2,  2,       29,      0],
        [ 0,  0,  2,  0,  0,       29,      0],
        [ 0,  0,  2,  2,  2,      -31,      0],
        [ 2,  0,  0,  2,  2,      -38,      0],
        [ 0,  0, -2,  2,  1,       46,      0],
        [-2,  0,  2,  0,  0,       48,      0],
        [ 0,  0,  1,  2,  1,      -51,      0],
        [ 0,  0, -1,  0,  1,      -58,   -0.1],
        [ 2,  0, -1,  2,  2,      -59,      0],
        [ 0,  0,  1,  0,  1,       63,    0.1],
        [ 2,  0,  0,  0,  0,       63,      0],
        [ 0,  0, -1,  2,  2,      123,      0],
        [-2,  0,  0,  2,  1,      129,    0.1],
        [-2,  0,  1,  0,  0,     -158,      0],
        [-2, -1,  0,  2,  2,      217,   -0.5],
        [ 0,  0,  1,  2,  2,     -301,      0],
        [ 0,  0,  0,  2,  1,     -386,   -0.4],
        [-2,  1,  0,  2,  2,     -517,    1.2],
        [ 0,  0,  1,  0,  0,      712,    0.1],
        [ 0,  1,  0,  0,  0,     1426,   -3.4],
        [ 0,  0,  0,  0,  2,     2062,    0.2],
        [ 0,  0,  0,  2,  2,    -2274,   -0.2],
        [-2,  0,  0,  2,  2,   -13187,   -1.6],
        [ 0,  0,  0,  0,  1,  -171996, -174.2]
    ]
    # :startdoc:

    # Compute nutation in longitude of Earth's pole for the given DateTime.
    # Implementation of algorithm in chapter 22.
    # Returns nutation in degrees.
    def Astro.nutation_in_longitude(date)

        # Julian centuries from the epoch J2000.0
        t = (date.ajd.to_f - 2451545.0)/36525.0

        # Mean elongation of the Moon from the Sun
        d = [1.0/189_474.0, -0.001_9142, 445_267.111_480, 297.85036].poly_eval(t) % 360.0

        # Mean anomaly of the Sun (Earth)
        m = [-1.0/300_000.0, -0.000_1603, 35_999.050_340, 357.52772].poly_eval(t) % 360.0

        # Mean anomaly of the Moon
        m_lun = [1.0/56_250.0, 0.008_6972, 477_198.867_398, 134.96298].poly_eval(t) %360.0

        # Moon's argument of latitude
        f = [1.0/327_270.0, -0.003_6825, 483_202.017_538, 93.27191].poly_eval(t) % 360.0

        # Longitude of the ascending node of the Moon's mean orbit on the ecliptic
        omega = [1.0/450_000.0, 0.002_0708, -1934.136_261, 125.04452].poly_eval(t) % 360.0

        nutation = 0.0
        for term in Table_22A do
            nutation += (term[5] + term[6]*t) *
                Math.sin((term[0]*d + term[1]*m + term[2]*m_lun + term[3]*f + term[4]*omega).to_rad) / 36_000_000.0
        end

        nutation

    end

    # Compute longitude of the Sun for the given DateTime.
    # Implementation of low accuracy algorithm in chapter 25.
    # Returns longitude in degrees.
    def Astro.solar_longitude_low_accuracy(date)

        # t = Julian centuries from the epoch J2000.0 (2000 January 1.5 TD)
        t = (date.ajd.to_f - 2451545.0)/36525.0

        # Mean longitude of the Sun
        mean_long = [0.000_3032, 36_000.769_83, 280.46646].poly_eval(t) % 360.0

        # Mean anomaly of the Sun
        mean_anomaly = [-0.000_1537, 35_999.050_29, 357.52911].poly_eval(t) % 360.0

        # Center of the sun
        m_rad = mean_anomaly.to_rad
        c = [-0.000_014, -0.004_817, 1.914_602].poly_eval(t) * Math.sin(m_rad) +
                [-0.000_101, 0.019_993].poly_eval(t) * Math.sin(2.0 * m_rad) +
                               0.000_289 * Math.sin(3.0 * m_rad)

        # True longitude
        true_long = (mean_long + c) % 360.0

        # Longitude corrected for nutation and the aberration
        omega = (125.04 - 1934.136*t) % 360.0
        apparent_long = (true_long - 0.00569 - 0.00478 * Math.sin(omega.to_rad)) % 360.0
        apparent_long
    end


    # :stopdoc:
    # Helio-centric coordinates of Earth
    EarthL0 = [
        #          A     B              C
        [         25.0, 3.16,        4_690.48        ],
        [         30.0, 2.74,        1_349.87        ],
        [         30.0, 0.44,       83_996.85        ],
        [         33.0, 0.59,       17_789.85        ],
        [         36.0, 1.78,        6_812.77        ],
        [         36.0, 1.71,        2_352.87        ],
        [         37.0, 2.57,        1_059.38        ],
        [         37.0, 6.04,       10_213.29        ],
        [         39.0, 6.17,       10_447.39        ],
        [         41.0, 2.40,       19_651.05        ],
        [         41.0, 5.37,        8_429.24        ],
        [         49.0, 0.49,        1_194.45        ],
        [         51.0, 0.28,        5_856.48        ],
        [         52.0, 1.33,        1_748.02        ],
        [         52.0, 0.19,       12_139.55        ],
        [         56.0, 3.47,        6_279.55        ],
        [         56.0, 4.39,       14_143.50        ],
        [         57.0, 2.78,        6_286.60        ],
        [         61.0, 1.82,        7_084.90        ],
        [         62.0, 3.98,        8_827.39        ],
        [         70.0, 0.83,        9_437.76        ],
        [         74.0, 4.68,          801.82        ],
        [         74.0, 3.50,        3_154.69        ],
        [         75.0, 1.76,        5_088.63        ],
        [         79.0, 3.04,       12_036.46        ],
        [         80.0, 1.81,       17_260.15        ],
        [         85.0, 3.67,       71_430.70        ],
        [         85.0, 1.30,        6_275.96        ],
        [         86.0, 5.98,      161_000.69        ],
        [         98.0, 0.68,          155.42        ],
        [         99.0, 6.21,        2_146.17        ],
        [        102.0, 4.267,           7.114       ],
        [        102.0, 0.976,      15_720.839       ],
        [        103.0, 0.636,       4_694.003       ],
        [        115.0, 0.645,           0.980       ],
        [        126.0, 1.083,          20.775       ],
        [        132.0, 3.411,       2_942.463       ],
        [        156.0, 0.833,         213.299       ],
        [        202.0, 2.458,       6_069.777       ],
        [        205.0, 1.869,       5_573.143       ],
        [        206.0, 4.806,       2_544.314       ],
        [        243.0, 0.345,       5_486.778       ],
        [        271.0, 0.315,      10_977.079       ],
        [        284.0, 1.899,         796.298       ],
        [        317.0, 5.849,      11_790.629       ],
        [        357.0, 2.920,           0.067       ],
        [        492.0, 4.205,         775.523       ],
        [        505.0, 4.583,      18_849.228       ],
        [        753.0, 2.533,       5_507.553       ],
        [        780.0, 1.179,       5_223.694       ],
        [        857.0, 3.508,         398.149       ],
        [        902.0, 2.045,          26.298       ],
        [        990.0, 5.233,       5_884.927       ],
        [      1_199.0, 1.109_6,     1_577.343_5     ],
        [      1_273.0, 2.037_1,       529.691_0     ],
        [      1_324.0, 0.742_5,    11_506.769_8     ],
        [      2_343.0, 6.135_2,     3_930.209_7     ],
        [      2_676.0, 4.418_1,     7_860.419_4     ],
        [      3_136.0, 3.627_7,    77_713.771_5     ],
        [      3_418.0, 2.828_9,         3.523_1     ],
        [      3_497.0, 2.744_1,     5_753.384_9     ],
        [     34_894.0, 4.626_10,   12_566.151_70    ],
        [  3_341_656.0, 4.669_256_8, 6_283.075_850_0 ],
        [175_347_046.0, 0.0,             0.0         ]
    ]

    EarthL1 = [
        [              6.0, 4.67,       4_690.48     ],
        [              6.0, 2.65,       9_437.76     ],
        [              8.0, 5.30,       2_352.87     ],
        [              9.0, 5.64,         951.72     ],
        [              9.0, 2.70,         242.73     ],
        [             10.0, 4.24,       1_349.87     ],
        [             10.0, 1.30,       6_286.60     ],
        [             11.0, 0.77,         553.57     ],
        [             12.0, 2.08,       4_694.00     ],
        [             12.0, 5.27,       1_194.45     ],
        [             12.0, 3.26,       5_088.63     ],
        [             12.0, 2.83,       1_748.02     ],
        [             15.0, 1.21,      10_977.08     ],
        [             16.0, 1.43,       2_146.17     ],
        [             16.0, 0.03,       2_544.31     ],
        [             17.0, 2.99,       6_275.96     ],
        [             19.0, 4.97,         213.30     ],
        [             19.0, 1.85,       5_486.78     ],
        [             21.0, 5.34,           0.98     ],
        [             29.0, 2.65,           7.11     ],
        [             36.0, 0.47,         775.52     ],
        [             45.0, 0.40,         796.30     ],
        [             56.0, 2.17,         155.42     ],
        [             59.0, 2.89,       5_223.69     ],
        [             67.0, 4.41,       5_507.55     ],
        [             68.0, 1.87,         398.15     ],
        [             72.0, 1.14,         529.69     ],
        [             93.0, 2.59,      18_849.23     ],
        [            109.0, 2.966,      1_577.344    ],
        [            119.0, 5.796,         26.298    ],
        [            425.0, 1.590,          3.523    ],
        [          4_303.0, 2.635_1,   12_566.151_7  ],
        [        206_059.0, 2.678_235,  6_283.075_850],
        [628_331_966_747.0, 0.0,            0.0      ]
    ]

    EarthL2 = [
        [     2.0, 3.75,         0.98   ],
        [     2.0, 4.38,     5_233.69   ],
        [     3.0, 2.28,       553.57   ],
        [     3.0, 0.31,       398.15   ],
        [     3.0, 6.12,       529.69   ],
        [     3.0, 1.19,       242.73   ],
        [     3.0, 6.05,     5_507.55   ],
        [     3.0, 5.14,       796.30   ],
        [     4.0, 3.44,     5_573.14   ],
        [     4.0, 1.03,         7.11   ],
        [     5.0, 4.66,     1_577.34   ],
        [     7.0, 0.83,       775.52   ],
        [     9.0, 2.06,    77_713.77   ],
        [    10.0, 0.76,    18_849.23   ],
        [    16.0, 3.68,       155.42   ],
        [    16.0, 5.19,        26.30   ],
        [    27.0, 0.05,         3.52   ],
        [   309.0, 0.867,   12_566.152  ],
        [ 8_720.0, 1.072_1,  6_283.075_8],
        [52_919.0, 0.0,          0.0    ]
    ]

    EarthL3 = [
        [  1.0, 5.97,     242.73 ],
        [  1.0, 5.30,  18_849.23 ],
        [  1.0, 4.72,       3.52 ],
        [  3.0, 5.20,     155.42 ],
        [ 17.0, 5.49,  12_566.15 ],
        [ 35.0, 0.0,        0.0  ],
        [289.0, 5.844,  6_283.076]
    ]

    EarthL4 = [
        [  1.0, 3.84,  12_566.15],
        [  8.0, 4.13,   6_283.08],
        [114.0, 3.142,      0.0 ]
    ]

    EarthL5 = [
        [  1.0, 3.14,  0.0]
    ]

    EarthR0 = [
        [         26,  4.59,       10_447.39       ],
        [         28,  1.90,        6_279.55       ],
        [         28,  1.21,        6_286.60       ],
        [         32,  1.78,          398.15       ],
        [         32,  0.18,        5_088.63       ],
        [         33,  0.24,        7_084.90       ],
        [         35,  1.84,        2_942.46       ],
        [         36,  1.67,       12_036.46       ],
        [         37,  4.90,       12_139.55       ],
        [         37,  0.83,       19_651.05       ],
        [         38,  2.39,        8_827.39       ],
        [         39,  5.36,        4_694.00       ],
        [         43,  6.01,        6_275.96       ],
        [         45,  5.54,        9_437.76       ],
        [         47,  2.58,          775.52       ],
        [         49,  3.25,        2_544.31       ],
        [         56,  5.24,       71_430.70       ],
        [         57,  2.01,       83_996.85       ],
        [         63,  0.92,          529.69       ],
        [         65,  0.27,       17_260.15       ],
        [         86,  1.27,      161_000.69       ],
        [         86,  5.69,       15_720.84       ],
        [         98,  0.89,        6_069.78       ],
        [        110,  5.055,       5_486.778      ],
        [        175,  3.012,      18_849.228      ],
        [        186,  5.022,      10_977.079      ],
        [        212,  5.847,       1_577.344      ],
        [        243,  4.273,      11_790.629      ],
        [        307,  0.299,       5_573.143      ],
        [        329,  5.900,       5_223.694      ],
        [        346,  0.964,       5_507.553      ],
        [        472,  3.661,       5_884.927      ],
        [        542,  4.564,       3_930.210      ],
        [        925,  5.453,      11_506.770      ],
        [      1_576,  2.846_9,     7_860.419_4    ],
        [      1_628,  1.173_9,     5_753.384_9    ],
        [      3_084,  5.198_5,    77_713.771_5    ],
        [     13_956,  3.055_25,   12_566.151_70   ],
        [  1_670_700,  3.098_463_5, 6_283.075_850_0],
        [100_013_989,  0,               0          ]
    ]

    EarthR1 = [
        [      9,  0.27,        5_486.78     ],
        [      9,  1.42,        6_275.96     ],
        [     10,  5.91,       10_977.08     ],
        [     18,  1.42,        1_577.34     ],
        [     25,  1.32,        5_223.69     ],
        [     31,  2.84,        5_507.55     ],
        [     32,  1.02,       18_849.23     ],
        [    702,  3.142,           0        ],
        [  1_721,  1.064_4,    12_566.151_7  ],
        [103_019,  1.107_490,   6_283.075_850]
    ]

    EarthR2 = [
        [    3,  5.47,     18_849.23   ],
        [    6,  1.87,      5_573.14   ],
        [    9,  3.63,     77_713.77   ],
        [   12,  3.14,          0      ],
        [  124,  5.579,    12_566.152  ],
        [4_359,  5.784_6,   6_283.075_8]
    ]

    EarthR3 = [
        [  7,  3.92,   12_566.15 ],
        [145,  4.273,   6_283.076]
    ]

    EarthR4 = [
        [4, 2.56, 6_283.08]
    ]
    # :startdoc:


    # Compute longitude of Sun for given DateTime.
    # Implementation of higher accuracy algorithm in chapter 25.
    # Accurate to within 1" between the years -2000 and +6000.
    # Returns longitude in degrees.
    def Astro.solar_longitude(date)

        # t = Julian millennia from the epoch J2000.0 (2000 January 1.5 TD)
        t = (date.ajd.to_f - 2451545.0)/365250.0

        l0 = EarthL0.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        l1 = EarthL1.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        l2 = EarthL2.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        l3 = EarthL3.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        l4 = EarthL4.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        l5 = EarthL5.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        long = (([l5, l4, l3, l2, l1, l0].poly_eval(t) * 1e-8).to_deg) % 360.0

        r0 = EarthR0.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        r1 = EarthR1.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        r2 = EarthR2.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        r3 = EarthR3.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        r4 = EarthR4.inject(0.0) {|accum, (a, b, c)| accum + a * Math.cos(b + c*t)}
        radius = [r4, r3, r2, r1, r0].poly_eval(t) * 1e-8
        aberration = -0.0056916111/radius

        long -= 180.0                       # switch to Earth's perspective
        long += -2.509167e-5                # convert to FK5 system
        long += nutation_in_longitude(date)
        long += aberration                  # correct for aberration
        long % 360.0
    end

end
