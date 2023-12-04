# frozen_string_literal: true

module CLIMarkdown
  module TaskPaper
    TASK_RX = /^(?<indent>(?:    |\t)*?)(?<marker>-)(?<task>\s+\S.*?)$/
    PROJECT_RX = /^(?<indent>(?:    |\t)*?)(?<project>[^- \t].*?:)(?<tags> +@\S+)*$/
    NOTE_RX = /^(?<indent>(?:    |\t)+)(?<note>(?<!- ).*?(?!:))$/

    class << self
      include CLIMarkdown::Colors
      attr_writer :theme

      def color(key)
        val = nil
        keys = key.split(/[ ,>]/)
        if MDLess.theme.key?(keys[0])
          val = MDLess.theme[keys.shift]
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
        return true if MDLess.file =~ /\.taskpaper$/

        projects = sections(input)

        tasks = 0
        if projects.count > 1
          projects.each do |proj, content|
            tasks += content['content'].scan(TASK_RX).count
          end
        end

        if tasks >= 6
          return true
        else
          tst = input.dup.remove_meta
          tst = tst.gsub(PROJECT_RX, '')
          tst = tst.gsub(TASK_RX, '')
          tst = tst.gsub(NOTE_RX, '')
          tst = tst.gsub(/^ *\n$/, '')
          return tst.strip.length == 0
        end
      end

      def section(input, string)
        sects = sections(input)
        sects_to_s(sects.filter { |k, _| k.downcase =~ string.downcase.to_rx })
      end

      def sects_to_s(sects)
        sects.map do |k, v|
          "#{k}#{v['content']}"
        end.join("\n")
      end

      def indent(input, idnt)
        input.split(/\n/).map do |line|
          line.sub(/^#{idnt}/, '')
        end.join("\n")
      end

      def sections(input)
        heirarchy = {}
        sects = input.to_enum(:scan, /(?mix)
                                      (?<=\n|\A)(?<indent>(?:    |\t)*?)
                                      (?<project>[^- \t\n].*?:)\s*(?=\n)
                                      (?<content>.*?)
                                      (?=\n\k<indent>\S.*?:|\Z)$/).map { Regexp.last_match }
        sects.each do |sect|
          heirarchy[sect['project']] = {}
          heirarchy[sect['project']]['content'] = indent(sect['content'], sect['indent'])
          heirarchy = heirarchy.merge(sections(sect['content']))
        end

        heirarchy
      end

      def list_projects(input)
        projects = input.to_enum(:scan, PROJECT_RX).map { Regexp.last_match }
        projects.delete_if { |proj| proj['project'] =~ /^[ \n]*$/ }
        projects.map! { |proj| "#{color('taskpaper marker')}#{proj['indent']}- #{color('taskpaper project')}#{proj['project'].sub(/:$/, '')}" }
        projects.join("\n")
      end

      def highlight(input)
        mc = color('taskpaper marker')
        tc = color('taskpaper task')
        pc = color('taskpaper project')
        nc = color('taskpaper note')

        if MDLess.options[:section]
          matches = []
          MDLess.options[:section].each do |sect|
            matches << section(input, sect)
          end
          input = matches.join("\n")
        end

        input.gsub!(/\t/, '    ')

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
