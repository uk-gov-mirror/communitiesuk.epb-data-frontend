require "sinatra"
require "active_support"
require "active_support/core_ext"

configure { set :server, :puma }

unless defined?(TestLoader)
  require "zeitwerk"
  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/lib/")
  loader.setup
end

ENV["DB_ADAPTER"] = "nulldb"
ENV["DATABASE_URL"] = "postgresql://fake"

Dir.glob("lib/tasks/**/*.rake").each { |r| load r }
