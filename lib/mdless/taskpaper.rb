# frozen_string_literal: true

module CLIMarkdown
  module TaskPaper
    TASK_RX = /^(?<indent>(?:    |\t)*)(?<marker>-)(?<task>\s+\S.*?)$/
    PROJECT_RX = /^(?<indent>(?:    |\t)*)(?<project>[^-]\S.*?:)(?<tags> @\S+)*$/
    NOTE_RX = /^(?<indent>(?:    |\t)+)(?<note>(?<!- ).*?(?!:))$/

    class << self
      include CLIMarkdown::Colors
      attr_writer :theme

      def color(key)
        val = nil
        keys = key.split(/[ ,>]/)
        if @theme.key?(keys[0])
          val = @theme[keys.shift]
        else
          @log.error("Invalid theme key: #{key}") unless keys[0] =~ /^text/
          return c([:reset])
        end
        keys.each do |k|
          if val.key?(k)
            val = val[k]
          else
            @log.error("Invalid theme key: #{k}")
            return c([:reset])
          end
        end
        if val.is_a? String
          val = "x #{val}"
          res = val.split(/ /).map(&:to_sym)
          c(res)
        else
          c([:reset])
        end
      end

      def is_taskpaper?(input)
        projects = input.split(PROJECT_RX)
        tasks = 0
        projects.each do |proj|
          tasks += proj.scan(TASK_RX).count
        end

        tasks >= 6
      end

      def highlight(input, theme)
        @theme = theme
        mc = color('taskpaper marker')
        tc = color('taskpaper task')
        pc = color('taskpaper project')
        nc = color('taskpaper note')

        input.gsub!(PROJECT_RX) do
          m = Regexp.last_match
          "#{m['indent']}#{pc}#{m['project']}#{m['tags']}"
        end

        input.gsub!(TASK_RX) do
          m = Regexp.last_match
          "#{m['indent']}#{mc}- #{tc}#{m['task']}"
        end

        input.gsub!(NOTE_RX) do
          m = Regexp.last_match
          "#{m['indent']}#{nc}#{m['note']}"
        end

        input
      end
    end
  end
end
