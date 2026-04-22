require "sinatra"

configure { set :server, :puma }

unless defined?(TestLoader)
  require "zeitwerk"
  loader = Zeitwerk::Loader.new
  loader.push_dir("#{__dir__}/lib/")
  loader.setup
end

Dir.glob("lib/tasks/**/*.rake").each { |r| load r }
