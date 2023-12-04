# frozen_string_literal: true

require 'optparse'
require 'shellwords'
require 'open3'
require 'fileutils'
require 'logger'
require 'tty-which'
require 'tty-screen'
require 'tty-spinner'
require 'rouge'
require 'mdless/version'
require 'mdless/colors'
require 'mdless/tables'
require 'mdless/hash'
require 'mdless/string'
require 'mdless/array'
require 'mdless/taskpaper'
require 'mdless/theme'
require 'redcarpet'
require 'mdless/console'
require 'mdless/converter'

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
