# frozen_string_literal: true

# String helpers
class ::String
  include CLIMarkdown::Colors

  def clean_empty_lines
    gsub(/^[ \t]+$/, '')
  end

  def clean_empty_lines!
    replace clean_empty_lines
  end

  def color(key)
    val = nil
    keys = key.split(/[ ,>]/)
    if MDLess.theme.key?(keys[0])
      val = MDLess.theme[keys.shift]
    else
      MDLess.log.error("Invalid theme key: #{key}") unless keys[0] =~ /^text/
      return c([:reset])
    end
    keys.each do |k|
      if val.key?(k)
        val = val[k]
      else
        MDLess.log.error("Invalid theme key: #{k}")
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

  def to_rx(distance: 2, string_start: false)
    chars = downcase.split(//)
    pre = string_start ? '^' : '^.*?'
    /#{pre}#{chars.join(".{,#{distance}}")}.*?$/
  end

  def clean_header_ids!
    replace clean_header_ids
  end

  def clean_header_ids
    gsub(/ +\[.*?\] *$/, '').gsub(/ *\{#.*?\} *$/, '').strip
  end

  def color_meta(cols)
    @cols = cols
    input = dup
    input.clean_empty_lines!
    MDLess.meta = {}

    in_yaml = false
    first_line = input.split("\n").first
    if first_line =~ /(?i-m)^---[ \t]*?$/
      MDLess.log.info('Found YAML')
      # YAML
      in_yaml = true
      input.sub!(/(?i-m)^---[ \t]*\n(?<content>[\s\S]*?)\n[-.]{3}[ \t]*\n/m) do
        m = Regexp.last_match
        MDLess.log.info('Processing YAML Header')
        YAML.load(m['content']).map { |k, v| MDLess.meta[k.downcase] = v }
        lines = m['content'].split(/\n/)
        longest = lines.inject { |memo, word| memo.length > word.length ? memo : word }.length
        longest = longest < @cols ? longest + 1 : @cols
        lines.map do |line|
          if line =~ /^[-.]{3}\s*$/
            line = "#{color('metadata marker')}#{'%' * longest}"
          else
            line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
            line = "#{color('metadata marker')}%#{color('metadata color')}#{line}#{xc}"
          end

          line += "\u00A0" * (longest - line.uncolor.strip.length) if (longest - line.uncolor.strip.length).positive?
          line + xc
        end.join("\n") + "#{xc}\n"
      end
    end

    if !in_yaml && first_line =~ /(?i-m)^[\w ]+:\s+\S+/
      MDLess.log.info('Found MMD Headers')
      input.sub!(/(?i-m)^([\S ]+:[\s\S]*?)+(?=\n *\n)/) do |mmd|
        lines = mmd.split(/\n/)
        return mmd if lines.count > 20

        longest = lines.inject { |memo, word| memo.length > word.length ? memo : word }.length
        longest = longest < @cols ? longest + 1 : @cols
        lines.map do |line|
          line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
          parts = line.match(/[ \t]*(.*?): +(.*?)$/)
          key = parts[1].gsub(/[^a-z0-9\-_]/i, '')
          value = parts[2].strip
          MDLess.meta[key] = value
          line = "#{color('metadata color')}#{line}#{xc}"
          line += "\u00A0" * (longest - line.uncolor.strip.length) if (longest - line.uncolor.strip.length).positive?
          line + xc
        end.join("\n") + "#{"\u00A0" * longest}#{xc}\n"
      end
    end

    input
  end

  def highlight_tags
    log = MDLess.log
    tag_color = color('at_tags tag')
    value_color = color('at_tags value')
    gsub(/(?<pre>\s|m)(?<tag>@[^ \]:;.?!,("'\n]+)(?:(?<lparen>\()(?<value>.*?)(?<rparen>\)))?(?=[ ;!,.?]|$)/) do
      m = Regexp.last_match
      last_color = m.pre_match.last_color_code
      [
        m['pre'],
        tag_color,
        m['tag'],
        m['lparen'],
        value_color,
        m['value'],
        tag_color,
        m['rparen'],
        xc,
        last_color
      ].join
    end
  end

  def scrub
    encode('utf-16', invalid: :replace).encode('utf-8')
  end

  def scrub!
    replace scrub
  end

  def valid_pygments_theme?
    return false unless TTY::Which.exist?('pygmentize')

    MDLess.pygments_styles.include?(self)
  end

  def remove_meta
    first_line = split("\n").first
    if first_line =~ /(?i-m)^---[ \t]*?$/
      sub(/(?im)^---[ \t]*\n([\s\S\n]*?)\n[-.]{3}[ \t]*\n/, '')
    elsif first_line =~ /(?i-m)^[\w ]+:\s+\S+/
      sub(/(?im)^([\S ]+:[\s\S]*?)+(?=\n *\n)/, '')
    else
      self
    end
  end

  def valid_lexer?
    return false unless TTY::Which.exist?('pygmentize')

    MDLess.pygments_lexers.include?(self.downcase)
  end
end
