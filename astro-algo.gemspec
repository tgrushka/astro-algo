Gem::Specification.new do |s|
  s.name        = 'astro-algo'
  s.version     = '0.0.1'
  s.author      = 'John P. Powers'
  s.description = 'This library implements algorithms from Jean Meeus, Astronomical Algorithms, 2nd English Edition, Willmann-Bell, Inc., Richmond, Virginia, 1999, with corrections as of June 15, 2005.'
  s.email       = 'john@jppowers.net'
  s.files       = Dir['{lib,bin}/**/*'] + %w(README)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.homepage    = 'http://astro-algo.rubyforge.org/astro-algo'
  s.licenses    = []
  s.summary     = 'Implementation of algorithms in _Astronomical Algorithms_. Useful for computing phases of the moon.'
end
