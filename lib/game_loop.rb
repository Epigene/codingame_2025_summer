debug "Game starts!"
# game loop
loop do
  line = gets.chomp
  debug(line)
  puts controller.call(line)
end
