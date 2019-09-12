#!/usr/bin/env ruby
def convert_markdown(input)
  @headers = get_headers(input)
  # yaml/MMD headers
  in_yaml = false
  if input.split("\n")[0] =~ /(?i-m)^---[ \t]*?(\n|$)/
    @log.info("Found YAML")
    # YAML
    in_yaml = true
    input.sub!(/(?i-m)^---[ \t]*\n([\s\S]*?)\n[\-.]{3}[ \t]*\n/) do |yaml|
      m = Regexp.last_match

      @log.info("Processing YAML Header")
      m[0].split(/\n/).map {|line|
        if line =~ /^[\-.]{3}\s*$/
          line = c([:d,:black,:on_black]) + "% " + c([:d,:black,:on_black]) + line
        else
          line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
          line = c([:d,:black,:on_black]) + "% " + c([:d,:white]) + line
        end
        if @cols - line.uncolor.size > 0
          line += " "*(@cols-line.uncolor.size)
        end
      }.join("\n") + "#{xc}\n"
    end
  end
end
