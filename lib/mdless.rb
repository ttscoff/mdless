require 'optparse'
require 'shellwords'
require 'open3'
require 'fileutils'
require 'logger'
require 'mdless/version.rb'
require 'mdless/colors'
require 'mdless/converter'

module CLIMarkdown
  EXECUTABLE_NAME = 'mdless'
end
