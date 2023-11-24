module CLIMarkdown
  module Colors
    ESCAPE_REGEX = /(?<=\[)(?:(?:(?:[349]|10)[0-9]|[0-9])?;?)+(?=m)/.freeze

    COLORS = {
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

    def uncolor
      self.gsub(/\e\[[\d;]+m/,'')
    end

    # Get the calculated ANSI color at the end of the
    # string
    #
    # @return     ANSI escape sequence to match color
    #
    def last_color_code
      m = scan(ESCAPE_REGEX)

      em = ['0']
      fg = nil
      bg = nil
      rgbf = nil
      rgbb = nil

      m.each do |c|
        case c
        when '0'
          em = ['0']
          fg, bg, rgbf, rgbb = nil
        when /^[34]8/
          case c
          when /^3/
            fg = nil
            rgbf = c
          when /^4/
            bg = nil
            rgbb = c
          end
        else
          c.split(/;/).each do |i|
            x = i.to_i
            if x <= 9
              em << x
            elsif x >= 30 && x <= 39
              rgbf = nil
              fg = x
            elsif x >= 40 && x <= 49
              rgbb = nil
              bg = x
            elsif x >= 90 && x <= 97
              rgbf = nil
              fg = x
            elsif x >= 100 && x <= 107
              rgbb = nil
              bg = x
            end
          end
        end
      end

      escape = "\e[#{em.join(';')}m"
      escape += "\e[#{rgbb}m" if rgbb
      escape += "\e[#{rgbf}m" if rgbf
      escape + "\e[#{[fg, bg].delete_if(&:nil?).join(';')}m"
    end

    # Get the calculated ANSI color at the end of the
    # string
    #
    # @return     ANSI escape sequence to match color
    #
    def last_color_code
      m = scan(ESCAPE_REGEX)

      em = ['0']
      fg = nil
      bg = nil
      rgbf = nil
      rgbb = nil

      m.each do |c|
        case c
        when '0'
          em = ['0']
          fg, bg, rgbf, rgbb = nil
        when /^[34]8/
          case c
          when /^3/
            fg = nil
            rgbf = c
          when /^4/
            bg = nil
            rgbb = c
          end
        else
          c.split(/;/).each do |i|
            x = i.to_i
            if x <= 9
              em << x
            elsif x >= 30 && x <= 39
              rgbf = nil
              fg = x
            elsif x >= 40 && x <= 49
              rgbb = nil
              bg = x
            elsif x >= 90 && x <= 97
              rgbf = nil
              fg = x
            elsif x >= 100 && x <= 107
              rgbb = nil
              bg = x
            end
          end
        end
      end

      escape = "\e[#{em.join(';')}m"
      escape += "\e[#{rgbb}m" if rgbb
      escape += "\e[#{rgbf}m" if rgbf
      escape + "\e[#{[fg, bg].delete_if(&:nil?).join(';')}m"
    end

    def blackout(bgcolor)
      key = bgcolor.to_sym
      bg = COLORS.key?(key) ? COLORS[key] : 40
      self.gsub(/(^|$)/,"\e[#{bg}m").gsub(/3([89])m/,"#{bg};3\\1m")
    end

    def uncolor!
      self.replace self.uncolor
    end

    def size_clean
      self.uncolor.size
    end

    def wrap(width=78,foreground=:x)

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
          lines << line + xc(foreground)
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
       lines << line + self.match(/\s*$/)[0] + xc(foreground) if line
      return lines.join("\n") # .gsub(/\- (\S)/,'-\1')
    end

    def c(args)
      out = []

      args.each {|arg|
        if COLORS.key? arg
          out << COLORS[arg]
        end
      }

      if out.size > 0
        "\e[#{out.sort.join(';')}m"
      else
        ''
      end
    end

    private

    def xc(foreground=:x)
      c([foreground])
    end
  end
end

class String
  include CLIMarkdown::Colors
end
