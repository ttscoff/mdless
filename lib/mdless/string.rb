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

  def color(key, theme, log)
    val = nil
    keys = key.split(/[ ,>]/)
    if theme.key?(keys[0])
      val = theme[keys.shift]
    else
      log.error("Invalid theme key: #{key}") unless keys[0] =~ /^text/
      return c([:reset])
    end
    keys.each do |k|
      if val.key?(k)
        val = val[k]
      else
        log.error("Invalid theme key: #{k}")
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

  def highlight_tags(theme, log)
    tag_color = color('at_tags tag', theme, log)
    value_color = color('at_tags value', theme, log)
    gsub(/(?<pre>\s|m)(?<tag>@[^ \].?!,("']+)(?:(?<lparen>\()(?<value>.*?)(?<rparen>\)))?/) do
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
end
