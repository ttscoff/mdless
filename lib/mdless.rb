# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'open3'
require 'optparse'
require 'shellwords'

require 'redcarpet'
require 'rouge'
require 'tty-screen'
require 'tty-spinner'
require 'tty-which'

require_relative 'mdless/theme'
require_relative 'mdless/array'
require_relative 'mdless/colors'
require_relative 'mdless/converter'
require_relative 'mdless/hash'
require_relative 'mdless/string'
require_relative 'mdless/tables'
require_relative 'mdless/taskpaper'
require_relative 'mdless/version'
require_relative 'mdless/console'

module CLIMarkdown
  EXECUTABLE_NAME = 'mdless'
end

module MDLess
  class << self
    include CLIMarkdown::Theme
    attr_accessor :options, :cols, :file, :meta

    def log
      @log ||= Logger.new($stderr)
    end

    def log_level(level)
      @log.level = level
    end

    def theme
      @theme ||= load_theme(@options[:theme])
    end

    def pygments_styles
      @pygments_styles ||= read_pygments_styles
    end

    def pygments_lexers
      @pygments_lexers ||= read_pygments_lexers
    end

    def read_pygments_styles
      MDLess.log.info 'Reading Pygments styles'
      pyg = TTY::Which.which('pygmentize')
      res = `#{pyg} -L styles`
      res.scan(/\* ([\w-]+):/).map { |l| l[0] }
    end

    def read_pygments_lexers
      MDLess.log.info 'Reading Pygments lexers'
      pyg = TTY::Which.which('pygmentize')
      res = `#{pyg} -L lexers`
      lexers = res.scan(/\* ([\w-]+(?:, [\w-]+)*):/).map { |l| l[0] }
      lexers_a = []
      lexers.each { |l| lexers_a.concat(l.split(/, /)) }
      lexers_a
    end
  end
end
