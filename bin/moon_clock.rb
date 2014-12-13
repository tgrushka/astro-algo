#!/usr/bin/env ruby
# moon_clock.rb
#
# A clock application which displays the current local time,
# Universal time, time since the previous new and full moons,
# and time until the next new and full moons.
#
# Copyright (c) 2007 John Powers

require 'tk'
require File.join(File.dirname(__FILE__), '../lib/lunaryear')


DateTimeFormat = '%Y-%m-%d %H:%M:%S'


# Format number of days.
# +days+ is a rational number of days.
# Return days formatted like 28d 14:59:11
def format_days(days)
    d, r = days.divmod(1)
    h, r = (24*r).divmod(1)
    m, r = (60*r).divmod(1)
    s    = (60*r).floor
    '%dd %d:%02d:%02d' % [d, h, m, s]       # 28d 14:59:11
end


# Set local and universal clocks to current time.
def set_clocks
    now = DateTime.now
    $current_time.value = now.strftime(DateTimeFormat)
    $universal_time.value = now.new_offset.strftime(DateTimeFormat)
    $lunar_date.value = '%4d\'%02d\'%02d' % LunarYear.lunar_date(now.to_date)
    now
end


# Update moon times
$tnew0 = DateTime.jd(1)
$tnew1 = DateTime.jd(1)
$tfull0 = DateTime.jd(1)
$tfull1 = DateTime.jd(1)


# Set all moon clocks relative to the current time -- the
# number of days since the last moon or until the next moon.
def set_moon_clocks
    now = set_clocks
    
    # Has new or full moon expired?
    if now > $tnew1 || now > $tfull1
        $tnew0, $tnew1, $tfull0, $tfull1 = LunarYear.date_of_moons(now)
    end
    
    $last_new_moon.value = format_days(now - $tnew0)
    $next_new_moon.value = format_days($tnew1 - now)
    $last_full_moon.value = format_days(now - $tfull0)
    $next_full_moon.value = format_days($tfull1 - now)
end


# Periodically update moon clocks. Reschedules itself to run
# again in 1000 milliseconds.
def update
    set_moon_clocks
    Tk.after(1000) {update}
end




$root = TkRoot.new { title 'Moon Clock' }
top = TkFrame.new($root)

# Local time
$current_time = TkVariable.new
TkLabel.new(top) {
    font 'Courier 48 bold'
    textvariable $current_time
    grid(:row => 0, :column => 0, :columnspan => 2, :sticky => 'ew')
}
TkLabel.new(top) {
    font 'Palatino 18 italic'
    text 'Local Time'
    grid(:row => 1, :column => 0, :columnspan => 2, :sticky => 'ew')
}


# Universal time
$universal_time = TkVariable.new
TkLabel.new(top) {
    font 'Courier 36 bold'
    textvariable $universal_time
    grid(:row => 2, :column => 0, :columnspan => 2, :sticky => 'ew')
}
TkLabel.new(top) {
    font 'Palatino 18 italic'
    text 'Universal Time'
    grid(:row => 3, :column => 0, :columnspan => 2, :sticky => 'ew')
}


# Lunar date
$lunar_date = TkVariable.new
TkLabel.new(top) {
    font 'Courier 36 bold'
    textvariable $lunar_date
    grid(:row => 4, :column => 0, :columnspan => 2, :sticky => 'ew')
}
TkLabel.new(top) {
    font 'Palatino 18 italic'
    text 'Lunar Date'
    grid(:row => 5, :column => 0, :columnspan => 2, :sticky => 'ew')
}


# Time since last new moon
$last_new_moon = TkVariable.new
TkLabel.new(top) {
    font 'Courier 36 bold'
    textvariable $last_new_moon
    grid(:row => 6, :column => 0, :sticky => 'e')
}
TkLabel.new(top) {
    font 'Palatino 18 italic'
    text 'Last New Moon'
    grid(:row => 7, :column => 0)
}

# Time until next new moon
$next_new_moon = TkVariable.new
TkLabel.new(top) {
    font 'Courier 36 bold'
    textvariable $next_new_moon
    grid(:row => 6, :column => 1, :sticky => 'e')
}
TkLabel.new(top) {
    font 'Palatino 18 italic'
    text 'Next New Moon'
    grid(:row => 7, :column => 1)
}

# Time since last full moon
$last_full_moon = TkVariable.new
TkLabel.new(top) {
    font 'Courier 36 bold'
    textvariable $last_full_moon
    grid(:row => 8, :column => 0, :sticky => 'e')
}
TkLabel.new(top) {
    font 'Palatino 18 italic'
    text 'Last Full Moon'
    grid(:row => 9, :column => 0)
}

# Time until next full moon
$next_full_moon = TkVariable.new
TkLabel.new(top) {
    font 'Courier 36 bold'
    textvariable $next_full_moon
    grid(:row => 8, :column => 1, :sticky => 'e')
}
TkLabel.new(top) {
    font 'Palatino 18 italic'
    text 'Next Full Moon'
    grid(:row => 9, :column => 1)
}


TkButton.new(top) {
    text ' Quit '
    command {exit}
    grid(:row => 10, :column => 1)
}


top.pack(:fill => 'both')


# Start clock display
update

Tk.mainloop
