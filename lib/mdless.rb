dir = File.dirname(__FILE__)
$LOAD_PATH.unshift dir unless $LOAD_PATH.include?(dir)

require 'optparse'
require 'shellwords'
require 'open3'
require 'fileutils'
require 'logger'
require 'mdless/version.rb'
require 'mdless/colors'
require 'mdless/converter'

# Add requires for other files you add to your project here, so
# you just need to require this one file in your bin file
