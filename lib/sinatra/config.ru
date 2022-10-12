#
# Checking environment
#
root = ENV["BEGOOD_PATH"]
if root == nil then
     puts "Critical error with Sinatra, missing BEGOOD_PATH"
     exit 1
end
#
# Set common variables and init global structures
#
bindir = "#{root}/bin"
logdir = "#{root}/log"
libdir = "#{root}/lib"
require "#{libdir}/sinatra/app.rb"
run Sinatra::Application
