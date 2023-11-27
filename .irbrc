$LOAD_PATH.unshift File.join(__dir__, 'lib')
require_relative 'lib/mdless'
include CLIMarkdown
config = File.expand_path('~/.config/mdless/config.yml')
MDLess.options = YAML.load(IO.read(config)) if File.exist?(config)
