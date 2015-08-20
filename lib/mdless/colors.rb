module CLIMarkdown
  module Colors

    def uncolor
      self.gsub(/\e\[[\d;]+m/,'')
    end

    def uncolor!
      self.replace self.uncolor
    end

    def size_clean
      self.uncolor.size
    end

    def wrap(width=78)

      if self.uncolor =~ /(^([%~] |\s*>)| +[=\-]{5,})/
        return self
      end

      visible_width = 0
      lines = []
      line = ''
      last_ansi = ''

      line += self.match(/^\s*/)[0].gsub(/\t/,'    ')
      input = self.dup # .gsub(/(\w-)(\w)/,'\1 \2')
      input.split(/\s+/).each do |word|
        last_ansi = line.scan(/\e\[[\d;]+m/)[-1] || ''
        if visible_width + word.size_clean >= width
          lines << line + xc
          visible_width = word.size_clean
          line = last_ansi + word
        elsif line.empty?
          visible_width = word.size_clean
          line = last_ansi + word
        else
          visible_width += word.size_clean + 1
          line << " " << last_ansi + word
        end
       end
       lines << line + self.match(/\s*$/)[0] + xc if line
      return lines.join("\n") # .gsub(/\- (\S)/,'-\1')
    end

    def xc(count=0)
      c([:x,:white])
    end

    def c(args)

      colors = {
            :reset => 0,     # synonym for :clear
            :x => 0,
            :bold => 1,
            :b => 1,
            :dark => 2,
            :d => 2,
            :italic => 3,     # not widely implemented
            :i => 3,
            :underline => 4,
            :underscore => 4,     # synonym for :underline
            :u => 4,
            :blink => 5,
            :rapid_blink => 6,     # not widely implemented
            :negative => 7,     # no reverse because of String#reverse
            :r => 7,
            :concealed => 8,
            :strikethrough => 9,     # not widely implemented
            :black => 30,
            :red => 31,
            :green => 32,
            :yellow => 33,
            :blue => 34,
            :magenta => 35,
            :cyan => 36,
            :white => 37,
            :on_black => 40,
            :on_red => 41,
            :on_green => 42,
            :on_yellow => 43,
            :on_blue => 44,
            :on_magenta => 45,
            :on_cyan => 46,
            :on_white => 47,
            :intense_black => 90,    # High intensity, aixterm (works in OS X)
            :intense_red => 91,
            :intense_green => 92,
            :intense_yellow => 93,
            :intense_blue => 94,
            :intense_magenta => 95,
            :intense_cyan => 96,
            :intense_white => 97,
            :on_intense_black => 100,    # High intensity background, aixterm (works in OS X)
            :on_intense_red => 101,
            :on_intense_green => 102,
            :on_intense_yellow => 103,
            :on_intense_blue => 104,
            :on_intense_magenta => 105,
            :on_intense_cyan => 106,
            :on_intense_white => 107
          }

      out = []

      args.each {|arg|
        if colors.key? arg
          out << colors[arg]
        end
      }

      if out.size > 0
        "\e[#{out.sort.join(';')}m"
      else
        ''
      end
    end
  end
end

class String
  include CLIMarkdown::Colors
end
