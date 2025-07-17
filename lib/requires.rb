require "set"
require "benchmark"

STDOUT.sync = true # DO NOT REMOVE

def debug(message)
  STDERR.puts message
end

# Monkeypatching String to behave like a Point, have x, y etc
class String
  def x
    split.first.to_i
  end

  def y
    split[1].to_i
  end
end
