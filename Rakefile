require "sinatra"
require "active_record"

configure { set :server, :puma }
Dir.glob("lib/tasks/*.rake").each { |r| load r }

require "rspec/core/rake_task"

# Build pack bundles ActiveRecord which is not used in this code base
# rescue the ActiveRecord error when running rake
begin
  RSpec::Core::RakeTask.new(:spec)
rescue ActiveRecord::ConnectionNotDefined
  puts ""
end
