require 'optparse'
require 'shellwords'
require 'open3'
require 'fileutils'
require 'logger'
require 'mdless/version.rb'
require 'mdless/colors'
require 'mdless/tables'
require 'mdless/hash'
require 'mdless/theme'
require 'redcarpet'
require 'mdless/converter'

module CLIMarkdown
  EXECUTABLE_NAME = 'mdless'
end
