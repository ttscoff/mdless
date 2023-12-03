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
      self.unpad.gsub(/\e\[[\d;]+m/,'')
    end

    def remove_pre_post
      gsub(/<<(pre|post)\d+>>/, '')
    end

    def unpad
      self.gsub(/\u00A0/, ' ')
    end

    # Get the calculated ANSI color at the end of the
    # string
    #
    # @return     ANSI escape sequence to match color
    #
    def last_color_code
      m = scan(ESCAPE_REGEX)

      em = []
      fg = nil
      bg = nil
      rgbf = nil
      rgbb = nil

      m.each do |c|
        case c
        when '0'
          em = ['0']
          fg, bg, rgbf, rgbb = nil
        when /;38;/
          fg = nil
          rgbf = c
        when /;48;/
          bg = nil
          rgbb = c
        else
          em = []
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

      escape = ''
      escape += "\e[#{em.join(';')}m" unless em.empty?
      escape += "\e[#{rgbb}m" if rgbb
      escape += "\e[#{rgbf}m" if rgbf
      fg_bg = [fg, bg].delete_if(&:nil?).join(';')
      escape += "\e[#{fg_bg}m" unless fg_bg.empty?
      escape
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

    def wrap(width=78, foreground=:x)
      return self if uncolor =~ /(^([%~] |\s*>)| +[=-]{5,})/

      visible_width = 0
      lines = []
      line = ''
      last_ansi = ''

      line += match(/^\s*/)[0].gsub(/\t/, '    ')
      input = dup # .gsub(/(\w-)(\w)/,'\1 \2')
      # input.gsub!(/\[.*?\]\(.*?\)/) do |link|
      #   link.gsub(/ /, "\u00A0")
      # end
      input.split(/\s/).each do |word|
        last_ansi = line.last_color_code
        if word =~ /[\s\t]/
          line << word
        elsif visible_width + word.size_clean >= width
          lines << line + xc
          visible_width = word.size_clean
          line = last_ansi + word
        elsif line.empty?
          visible_width = word.size_clean
          line = last_ansi + word
        else
          visible_width += word.size_clean + 1
          line << ' ' << last_ansi + word
        end
      end
      lines << line + match(/\s*$/)[0] + xc if line
      lines.map!.with_index do |l, i|
        (i.positive? ? l[i - 1].last_color_code : '') + l
      end
      lines.join("\n").gsub(/\[.*?\]\(.*?\)/) do |link|
        link.gsub(/\u00A0/, ' ')
      end
    end

    def c(args)
      out = []

      args.each do |arg|
        if arg.to_s =~ /^([bf]g|on_)?([a-f0-9]{3}|[a-f0-9]{6})$/i
          out.concat(rgb(arg.to_s))
        elsif COLORS.key? arg
          out << COLORS[arg]
        end
      end
      if !out.empty?
        "\e[#{out.join(';')}m"
      else
        ''
      end
    end

    private

    def rgb(hex)
      is_bg = hex.match(/^(bg|on_)/) ? true : false
      hex_string = hex.sub(/^(bg|on_)?(.{3}|.{6})/, '\2')
      hex_string.gsub!(/(.)/, '\1\1') if hex_string.length == 3

      parts = hex_string.match(/(?<r>..)(?<g>..)(?<b>..)/)
      t = []
      %w[r g b].each do |e|
        t << parts[e].hex
      end

      [is_bg ? 48 : 38, 2].concat(t)
    end

    def xc(foreground=:x)
      c([foreground])
    end
  end
end

class String
  include CLIMarkdown::Colors
end
