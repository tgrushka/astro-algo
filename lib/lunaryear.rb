# lunaryear.rb
# Lunar calendar library.
#
# Lunar months (or moonths) begin on the day of the New Moon in Coordinated
# Universal Time.
#
# The lunar year begins at the beginning of the moonth during which the
# Vernal Equinox occurs, usually March 20 or 21. Twelve moonths fall short
# of the Solar year by about 10 or 11 days, so an additional thirteenth
# moonth occurs every two or three years.

require File.join(File.dirname(__FILE__), 'astro-algo')

module LunarYear

    # Calculate the lunar calendar date for the given DateTime.
    # Returns [year, moonth, day].
    def LunarYear.lunar_date(date)
        year = date.year
        lun0 = LunarYear.new_moon_before_vernal_equinox(year)        # Year begins at Vernal Equinox
        if date < Astro.date_of_moon(lun0, Astro::PhaseNew).to_date
            year -= 1
            lun0 = new_moon_before_vernal_equinox(year)
        end
        prev_moon = Astro.date_of_moon(lun0, Astro::PhaseNew).to_date
        lun = lun0
        loop do
            lun += 1
            new_moon = Astro.date_of_moon(lun, Astro::PhaseNew).to_date
            break if new_moon > date
            prev_moon = new_moon
        end
        moonth = lun - lun0 - 1
        day = (date - prev_moon).to_i
        [year, moonth, day]
    end


    # Find number of lunation (New Moon) just before Vernal Equinox for a given year.
    # Lunation 0 is the first New Moon in the year 2000.
    # Returns an integer lunation number.
    #
    # Example: first lunation before Vernal Equinox of the year 1984.
    #   LunarYear.new_moon_before_vernal_equinox(1984)      # => -196
    def LunarYear.new_moon_before_vernal_equinox(year)
        equ = Astro.date_of_vernal_equinox(year)
        lunation = Astro.first_lunation_of_year(year)
        new_moon = Astro.date_of_moon(lunation, Astro::PhaseNew)
        loop do
            previous_new_moon = new_moon
            lunation += 1
            new_moon = Astro.date_of_moon(lunation, Astro::PhaseNew)
            return lunation-1 if new_moon > equ
        end
    end
    
    
    # Calculate the DateTime of the previous New and Full Moons
    # and the DateTime of the next New and Full moons.
    # Returns [previous New Moon, next New Moon, previous Full Moon, next Full Moon]
    #
    # Example: For November 18, 2007, calculate the date and time of the previous New Moon,
    # the next New Moon, the previous Full Moon, and the next Full Moon.
    #   LunarYear.date_of_moons(DateTime.civil(2007, 11, 18)).collect {|d| d.asctime}
    #   #=> ["Fri Nov  9 23:03:07 2007", "Sun Dec  9 17:40:21 2007", "Fri Oct 26 04:51:33 2007", "Sat Nov 24 14:29:47 2007"]
    def LunarYear.date_of_moons(date)
        next_new_moon = nil
        next_full_moon = nil

        k = ((date.year - 2000)*12.3685).floor - 1
        prev_new_moon = Astro.date_of_moon(k, Astro::PhaseNew).to_utc
        lun = k
        loop do
            lun += 1
            next_new_moon = Astro.date_of_moon(lun, Astro::PhaseNew).to_utc
            break if next_new_moon > date
            prev_new_moon = next_new_moon
        end
        
        lun = k
        prev_full_moon = Astro.date_of_moon(k, Astro::PhaseFull).to_utc
        loop do
            lun += 1
            next_full_moon = Astro.date_of_moon(lun, Astro::PhaseFull).to_utc
            break if next_full_moon > date
            prev_full_moon = next_full_moon
        end

        [prev_new_moon, next_new_moon, prev_full_moon, next_full_moon]
    end
end
