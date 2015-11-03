script = File.read(File.join(
  File.dirname(__FILE__),
  'setup_server.sh.template'))

s = script.gsub(/\$CLICKLION_[A-Z0-9_]+/) do |match|
  variable = ENV[match[1..match.size]]
  if variable.nil?
    puts "Missing #{match} environment variable. Quit!"
    exit 1
  end
  variable
end

File.write(File.join(File.dirname(__FILE__), 'setup_server.sh'), s)
puts "Script is generated to #{File.dirname(__FILE__)}/setup_server.sh"

