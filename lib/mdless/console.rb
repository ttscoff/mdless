module Redcarpet
  module Render
    class Console < Base
      include CLIMarkdown::Colors
      include CLIMarkdown::Theme

      attr_accessor :headers
      attr_writer :file

      @@listitemid = 0
      @@listid = 0
      @@elementid = 0
      @@footnotes = []
      @@links = []
      @@footer_links = []

      def pre_element
        @@elementid += 1
        "<<pre#{@@elementid}>>"
      end

      def post_element
        "<<post#{@@elementid}>>"
      end

      def xc
        x + color('text')
      end

      def x
        c([:reset])
      end

      def color_table(input)
        first = true
        input.split(/\n/).map do |line|
          if first
            if line =~ /^\+-+/
              line.gsub!(/^/, color('table border'))
            else
              first = false
              line.gsub!(/\|/, "#{color('table border')}|#{color('table header')}")
            end
          elsif line.strip =~ /^[|:\- +]+$/
            line.gsub!(/^(.*)$/, "#{color('table border')}\\1#{color('table color')}")
            line.gsub!(/([:\-+]+)/, "#{color('table divider')}\\1#{color('table border')}")
          else
            line.gsub!(/\|/, "#{color('table border')}|#{color('table color')}")
          end
        end.join("\n")
      end

      def exec_available(cli)
        if File.exist?(File.expand_path(cli))
          File.executable?(File.expand_path(cli))
        else
          TTY::Which.exist?(cli)
        end
      end

      def code_bg(input, width)
        input.split(/\n/).map do |line|
          tail = line.uncolor.length < width ? "\u00A0" * (width - line.uncolor.length) : ''
          "#{x}#{line}#{tail}#{x}"
        end.join("\n")
      end

      def hilite_code(code_block, language)
        if MDLess.options[:syntax_higlight] && !exec_available('pygmentize')
          MDLess.log.error('Syntax highlighting requested by pygmentize is not available')
          MDLess.options[:syntax_higlight] = false
        end

        longest_line = code_block.uncolor.split(/\n/).longest_element.length + 4
        longest_line = longest_line > MDLess.cols ? MDLess.cols : longest_line

        if MDLess.options[:syntax_higlight]
          pyg = TTY::Which.which('pygmentize')
          lexer = language&.valid_lexer? ? "-l #{language}" : '-g'
          begin
            pygments_theme = MDLess.options[:pygments_theme] || MDLess.theme['code_block']['pygments_theme']

            unless pygments_theme.valid_pygments_theme?
              MDLess.log.error("Invalid Pygments theme #{pygments_theme}, defaulting to 'default' for highlighting")
              pygments_theme = 'default'
            end

            cmd = [
              "#{pyg} -f terminal256",
              "-O style=#{pygments_theme}",
              lexer,
              '2> /dev/null'
            ].join(' ')
            hilite, s = Open3.capture2(cmd,
                                       stdin_data: code_block)
            if s.success?
              hilite = xc + hilite.split(/\n/).map do |l|
                [
                  color('code_block marker'),
                  '> ',
                  "#{color('code_block bg')}#{l.strip}#{xc}"
                ].join
              end.join("\n").blackout(MDLess.theme['code_block']['bg']) + "#{xc}\n"
            end
          rescue StandardError => e
            MDLess.log.error(e)
            hilite = code_block
          end
        else
          hilite = code_block.split(/\n/).map do |line|
            [
              color('code_block marker'),
              '> ',
              color('code_block color'),
              line,
              xc
            ].join
          end.join("\n").blackout(MDLess.theme['code_block']['bg']) + "#{xc}\n"
        end

        top_border = if language.nil? || language.empty?
                       '-' * longest_line
                     else
                       "--[ #{language} ]#{'-' * (longest_line - 6 - language.length)}"
                     end

        [
          xc,
          color('code_block border'),
          top_border,
          xc,
          "\n",
          color('code_block color'),
          code_bg(hilite.chomp, longest_line),
          "\n",
          color('code_block border'),
          '-' * longest_line,
          xc
        ].join
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

      def block_code(code, language)
        "\n\n#{hilite_code(code, language)}#{xc}\n\n"
      end

      def block_quote(quote)
        ret = "\n\n"
        quote.wrap(MDLess.cols, color('blockquote color')).split(/\n/).each do |line|
          ret += [
            color('blockquote marker color'),
            MDLess.theme['blockquote']['marker']['character'],
            color('blockquote color'),
            ' ',
            line,
            "\n"
          ].join('')
        end
        "#{ret}\n\n"
      end

      def block_html(raw_html)
        "#{color('html color')}#{color_tags(raw_html)}#{xc}"
      end

      def header(text, header_level)
        pad = ''
        ansi = ''
        text.clean_header_ids!
        case header_level
        when 1
          ansi = color('h1 color')
          pad = color('h1 pad')
          char = MDLess.theme['h1']['pad_char'] || '='
          pad += text.length + 2 > MDLess.cols ? char * text.length : char * (MDLess.cols - (text.length + 1))
        when 2
          ansi = color('h2 color')
          pad = color('h2 pad')
          char = MDLess.theme['h2']['pad_char'] || '-'
          pad += text.length + 2 > MDLess.cols ? char * text.length : char * (MDLess.cols - (text.length + 1))
        when 3
          ansi = color('h3 color')
        when 4
          ansi = color('h4 color')
        when 5
          ansi = color('h5 color')
        else
          ansi = color('h6 color')
        end

        # If we're in iTerm and not paginating, add
        # iTerm Marks for navigation on h1-3
        if header_level < 4 &&
           ENV['TERM_PROGRAM'] =~ /^iterm/i &&
           MDLess.options[:pager] == false
          ansi = "\e]1337;SetMark\a#{ansi}"
        end

        "\n\n#{xc}#{ansi}#{text} #{pad}#{xc}\n\n"
      end

      def hrule()
        "\n\n#{color('hr color')}#{'_' * MDLess.cols}#{xc}\n\n"
      end

      def paragraph(text)
        if MDLess.options[:preserve_linebreaks]
          "#{xc}#{text.gsub(/ +/, ' ').strip}#{xc}#{x}\n\n"
        else
          "#{xc}#{text.gsub(/ +/, ' ').gsub(/\n+/, ' ').strip}#{xc}#{x}\n\n"
        end
      end

      @table_cols = nil

      def table_header_row
        @header_row.map do |alignment|
          case alignment
          when :left
            '|:---'
          when :right
            '|---:'
          when :center
            '|:--:'
          else
            '|----'
          end
        end.join('') + '|'
      end

      def table(header, body)
        @header_row = []
        formatted = CLIMarkdown::MDTableCleanup.new([
          "#{header}",
          table_header_row,
          "|\n",
          "#{body}\n\n"
        ].join(''))
        res = formatted.to_md
        "#{color_table(res)}\n\n"
        # res
      end

      def table_row(content)
        @table_cols = content.scan(/\|/).count
        %(#{content}\n)
      end

      def table_cell(content, alignment)
        @header_row ||= []
        if @table_cols && @header_row.count < @table_cols
          @header_row << alignment
        end
        %(#{content} |)
      end

      def autolink(link, _)
        [
          pre_element,
          color('link brackets'),
          '<',
          color('link url'),
          link,
          color('link brackets'),
          '>',
          xc,
          post_element
        ].join('')
      end

      def codespan(code)
        [
          pre_element,
          color('code_span marker'),
          MDLess.theme['code_span']['character'],
          color('code_span color'),
          code,
          color('code_span marker'),
          MDLess.theme['code_span']['character'],
          xc,
          post_element
        ].join('')
      end

      def double_emphasis(text)
        [
          pre_element,
          color('emphasis bold'),
          MDLess.theme['emphasis']['bold_character'],
          text,
          MDLess.theme['emphasis']['bold_character'],
          xc,
          post_element
        ].join
      end

      def emphasis(text)
        [
          pre_element,
          color('emphasis italic'),
          MDLess.theme['emphasis']['italic_character'],
          text,
          MDLess.theme['emphasis']['italic_character'],
          xc,
          post_element
        ].join
      end

      def triple_emphasis(text)
        [
          pre_element,
          color('emphasis bold-italic'),
          MDLess.theme['emphasis']['italic_character'],
          MDLess.theme['emphasis']['bold_character'],
          text,
          MDLess.theme['emphasis']['bold_character'],
          MDLess.theme['emphasis']['italic_character'],
          xc,
          post_element
        ].join
      end

      def highlight(text)
        "#{pre_element}#{color('highlight')}#{text}#{xc}#{post_element}"
      end

      def color_image_tag(link, title, alt_text)
        [
          color('image bang'),
          '!',
          color('image brackets'),
          '[',
          color('image title'),
          alt_text,
          color('image brackets'),
          '](',
          color('image url'),
          link,
          title.nil? ? '' : %( "#{title}"),
          color('image brackets'),
          ')',
          xc,
        ].join
      end

      def image(link, title, alt_text)
        "<<img>>#{link}||#{title}||#{alt_text}<</img>>"
      end

      def linebreak
        "  \n"
      end

      def color_link(link, title, content)
        [
          pre_element,
          color('link brackets'),
          '[',
          color('link text'),
          content,
          color('link brackets'),
          '](',
          color('link url'),
          link,
          title.nil? ? '' : %( "#{title}"),
          color('link brackets'),
          ')',
          xc,
          post_element
        ].join
      end

      def color_link_reference(link, idx, content)
        [
          pre_element,
          color('link brackets'),
          '[',
          color('link text'),
          content,
          color('link brackets'),
          '][',
          color('link url'),
          idx,
          color('link brackets'),
          ']',
          xc,
          post_element
        ].join
      end

      def color_reference_link(link, title, content)
        [
          color('link brackets'),
          '[',
          color('link text'),
          content,
          color('link brackets'),
          ']:',
          color('text'),
          ' ',
          color('link url'),
          link,
          title.nil? ? '' : %( "#{title}"),
          xc
        ].join
      end

      def link(link, title, content)
        res = color_link(link, title&.strip, content&.strip)
        @@links << {
          link: res,
          url: link,
          title: title,
          content: content
        }
        res
      end

      def color_tags(html)
        html.gsub(%r{(<\S+( [^>]+)?>)}, "#{color('html brackets')}\\1#{xc}")
      end

      def raw_html(raw_html)
        "#{pre_element}#{color('html color')}#{color_tags(raw_html)}#{xc}#{post_element}"
      end

      def strikethrough(text)
        "#{pre_element}#{color('strikethrough')}#{text}#{xc}#{post_element}"
      end

      def superscript(text)
        "#{pre_element}#{color('super')}^#{text}#{xc}#{post_element}"
      end

      def footnotes(text)
        # [
        #   color('footnote note'),
        #   text,
        #   "\n",
        #   xc,
        # ].join('')
        nil
      end

      def color_footnote_def(idx)
        text = @@footnotes[idx]
        [
          color('footnote brackets'),
          "[",
          color('footnote caret'),
          "^",
          color('footnote title'),
          idx,
          color('footnote brackets'),
          "]:",
          color('footnote note'),
          ' ',
          text.uncolor.strip,
          xc,
          "\n"
        ].join('')
      end

      def footnote_def(text, idx)
        @@footnotes[idx] = text
      end

      def footnote_ref(text)
        [
          pre_element,
          color('footnote title'),
          "[^#{text}]",
          xc,
          post_element
        ].join('')
      end

      def insert_footnotes(input)
        input.split(/\n/).map do |line|
          notes = line.to_enum(:scan, /\[\^(?<ref>\d+)\]/).map { Regexp.last_match }
          if notes.count.positive?
            footnotes = notes.map { |n| color_footnote_def(n['ref'].to_i) }.join("\n")
            "#{line}\n\n#{footnotes}\n\n"
          else
            line
          end
        end.join("\n")
      end

      def list(contents, list_type)
        @@listid += 1
        "<<list#{@@listid}-#{list_type}>>#{contents}<</list#{@@listid}>>"
      end

      def list_item(text, list_type)
        @@listitemid += 1
        case list_type
        when :unordered
          "<<listitem#{@@listitemid}-#{list_type}>>#{text.strip}<</listitem#{@@listitemid}>>\n"
        when :ordered
          "<<listitem#{@@listitemid}-#{list_type}>>#{text.strip}<</listitem#{@@listitemid}>>\n"
        end
      end

      def indent_lines(input, spaces)
        return nil if input.nil?

        indent = spaces.scan(/ /).count

        lines = input.split(/\n/)
        line1 = lines.shift
        pre = '  ' * (indent + 1)
        cols = MDLess.cols - pre.length
        body = lines.map { |l| "#{pre}#{l}" }.join("\n")
        "#{line1}\n#{body}"
      end

      def color_list_item(indent, content, type, counter)
        case type
        when :unordered
          [
            indent,
            color('list bullet'),
            "* ",
            color('list color'),
            indent_lines(content, indent).strip,
            xc
          ].join
        when :ordered
          [
            indent,
            color('list number'),
            "#{counter}. ",
            color('list color'),
            indent_lines(content, indent).strip,
            xc
          ].join
        end
      end

      def fix_lists(input)
        input = nest_lists(input)
        input = fix_list_spacing(input)
        fix_list_items(input)
      end

      def fix_list_spacing(input)
        input.gsub(/( *\n)+( *)<<listitem/, "\n\\2<<listitem").gsub(/\n{2,}/, "\n\n")
      end

      def nest_lists(input, indent = 0)
        input.gsub!(%r{<<list(?<id>\d+)-(?<type>.*?)>>(?<content>.*?)<</list\k<id>>>}m) do
          m = Regexp.last_match
          lines = m['content'].split(/\n/)
          list = nest_lists(lines.map do |l|
            outdent = l.scan(%r{<</list\d+>>}).count
            indent += l.scan(/<<list\d+-.*?>>/).count
            indent -= outdent
            "#{' ' * indent}#{l}"
          end.join("\n"), indent)
          next if list.nil?

          "<<main#{m['id']}>>#{list}<</main#{m['id']}>>\n\n"
        end

        input.gsub(/^(?<indent> +)<<main(?<id>\d+)>>(?<content>.*?)<<\/main\k<id>>>/m) do
          m = Regexp.last_match
          "#{m['indent']}#{m['content']}"
        end
      end

      def normalize_indentation(line)
        line.gsub(/^([ \t]+)/) do |pre|
          pre.gsub(/\t/, ' ')
        end
      end

      def fix_items(content, last_indent = 0, levels = [0])
        content.gsub(%r{^(?<indent> *)<<listitem(?<id>\d+)-(?<type>(?:un)?ordered)>>(?<content>.*?)<</listitem\k<id>>>}m) do
          m = Regexp.last_match
          indent = m['indent'].length
          if indent == last_indent
            levels[indent] ||= 0
            levels[indent] += 1
          elsif indent < last_indent
            levels[last_indent] = 0
            levels[indent] += 1
            last_indent = indent
          else
            levels[indent] = 1
            last_indent = indent
          end

          content = m['content'] =~/<<listitem/ ? fix_items(m['content'], indent, levels) : m['content']
          color_list_item(' ' * indent, content, m['type'].to_sym, levels[indent])
        end
      end

      def fix_list_items(input)
        input.gsub(%r{<<main(?<id>\d+)>>(?<content>.*?)<</main\k<id>>>}m) do
          m = Regexp.last_match
          fix_items(m['content'])
        end
      end

      def get_headers(input)
        unless @headers && !@headers.empty?
          @headers = []
          headers = input.scan(/^((?!#!)(\#{1,6})\s*([^#]+?)(?: #+)?\s*|(\S.+)\n([=-]+))$/i)

          headers.each do |h|
            hlevel = 6
            title = nil
            if h[4] =~ /=+/
              hlevel = 1
              title = h[3]
            elsif h[4] =~ /-+/
              hlevel = 2
              title = h[3]
            else
              hlevel = h[1].length
              title = h[2]
            end
            @headers << [
              '#' * hlevel,
              title,
              h[0]
            ]
          end
        end

        @headers
      end

      def color_meta(text)
        input = text.dup
        input.clean_empty_lines!

        first_line = input.split("\n").first
        if first_line =~ /(?i-m)^---[ \t]*?$/
          MDLess.log.info('Found YAML')
          # YAML
          in_yaml = true
          input.sub!(/(?i-m)^---[ \t]*\n([\s\S]*?)\n[-.]{3}[ \t]*\n/m) do
            m = Regexp.last_match
            MDLess.log.info('Processing YAML Header')
            lines = m[0].split(/\n/)
            longest = lines.longest_element.length
            longest = longest < MDLess.cols ? longest + 1 : MDLess.cols
            lines.map do |line|
              if line =~ /^[-.]{3}\s*$/
                line = "#{color('metadata marker')}#{'%' * longest}"
              else
                line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
                line = "#{color('metadata color')}#{line}"
              end

              line += "\u00A0" * (longest - line.uncolor.strip.length) + xc
              line
            end.join("\n") + "#{xc}\n"
          end
        end

        if !in_yaml && first_line =~ /(?i-m)^[\w ]+:\s+\S+/
          MDLess.log.info('Found MMD Headers')
          input.sub!(/(?i-m)^([\S ]+:[\s\S]*?)+(?=\n\n)/) do |mmd|
            lines = mmd.split(/\n/)
            return mmd if lines.count > 20

            longest = lines.inject { |memo, word| memo.length > word.length ? memo : word }.length
            longest = longest < MDLess.cols ? longest + 1 : MDLess.cols
            lines.map do |line|
              line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
              line = "#{color('metadata color')}#{line}"
              line += "\u00A0" * (longest - line.uncolor.strip.length)
              line + xc
            end.join("\n") + "#{"\u00A0" * longest}#{xc}\n"
          end
        end

        input
      end

      def preprocess(input)
        input = color_meta(input)

        ## Replace setex headers with ATX
        input.gsub!(/^([^\n]+)\n={2,}\s*$/m, "# \\1\n")
        input.gsub!(/^([^\n]+?)\n-{2,}\s*$/m, "## \\1\n")

        @headers = get_headers(input)

        if MDLess.options[:section]
          new_content = []
          MDLess.log.info("Matching section(s) #{MDLess.options[:section].join(', ')}")
          MDLess.options[:section].each do |sect|
            comparison = MDLess.options[:section][0].is_a?(String) ? :regex : :numeric

            in_section = false
            top_level = 1
            input.split(/\n/).each_with_index do |graf, idx|
              if graf =~ /^(#+) *(.*?)( *#+)?$/
                m = Regexp.last_match
                level = m[1].length
                title = m[2]
                if in_section
                  if level >= top_level
                    new_content.push(graf)
                  else
                    in_section = false
                    break
                  end
                elsif (comparison == :regex && title.downcase =~ sect.downcase.to_rx) ||
                      (comparison == :numeric && title.downcase == @headers[sect - 1][1].downcase)
                  in_section = true
                  top_level = level + 1
                  new_content.push(graf)
                else
                  next
                end
              elsif in_section
                new_content.push(graf)
              end
            end
          end
          input = new_content.join("\n")
        end

        # definition lists
        input.gsub!(/(?mi)(?<=\n|\A)(?<term>(?!<:)[^\n]+)(?<def>(\n+: [^\n]+)+)/) do
          m = Regexp.last_match
          "#{color('dd term')}#{m['term']}#{xc}#{color('dd color')}#{color_dd_def(m['def'])}"
        end

        input
      end

      def color_dd_def(input)
        input.gsub(/(?<=\n|\A)(?::)\s+(.*)/) do
          m = Regexp.last_match
          [
            color('dd marker'),
            ": ",
            color('dd color'),
            m[1],
            xc
          ].join
        end
      end

      def color_links(input)
        input.gsub(/(?mi)(?<!\\e)\[(?<text>[^\[]+)\]\((?<url>\S+)(?: +"(?<title>.*?)")?\)/) do
          m = Regexp.last_match
          color_link(m['url'].uncolor, m['title']&.uncolor, m['text'].uncolor)
        end
      end

      def reference_links(input)
        grafs = input.split(/\n{2,}/)
        counter = 1

        grafs.map! do |graf|
          return "\n" if graf =~ /^ *\n$/

          links_added = false

          @@links.each do |link|
            if graf =~ /#{Regexp.escape(link[:link].gsub(/\n/, ' '))}/
              url = link[:url].uncolor
              content = link[:content]
              title = link[:title]&.uncolor
              graf.gsub!(/#{Regexp.escape(link[:link].gsub(/\n/, ' '))}/, color_link_reference(url, counter, content))
              if MDLess.options[:links] == :paragraph
                if links_added
                  graf += "\n#{color_reference_link(url, title, counter)}"
                else
                  graf = "#{graf}\n\n#{color_reference_link(url, title, counter)}"
                  links_added = true
                end
              else
                @@footer_links << color_reference_link(url, title, counter)
              end
              counter += 1
            end
          end
          "\n#{graf}\n"
        end

        if MDLess.options[:links] == :paragraph
          grafs.join("\n")
        else
          grafs.join("\n") + "\n#{@@footer_links.join("\n")}\n"
        end
      end

      def fix_colors(input)
        input.gsub(/<<pre(?<id>\d+)>>(?<content>.*?)<<post\k<id>>>/m) do
          m = Regexp.last_match
          pre = m.pre_match
          last_color = pre.last_color_code
          "#{fix_colors(m['content'])}#{last_color}"
        end.gsub(/<<(pre|post)\d+>>/, '')
      end

      def render_images(input)
        input.gsub(%r{<<img>>(.*?)<</img>>}) do
          link, title, alt_text = Regexp.last_match(1).split(/\|\|/)

          if (exec_available('imgcat') || exec_available('chafa')) && MDLess.options[:local_images]
            if exec_available('imgcat')
              MDLess.log.info('Using imgcat for image rendering')
            elsif exec_available('chafa')
              MDLess.log.info('Using chafa for image rendering')
            end
            img_path = link
            if img_path =~ /^http/ && MDLess.options[:remote_images]
              if exec_available('imgcat')
                MDLess.log.info('Using imgcat for image rendering')
                begin
                  res, s = Open3.capture2(%(curl -sS "#{img_path}" 2> /dev/null | imgcat))

                  if s.success?
                    pre = !alt_text.nil? ? "    #{c(%i[d blue])}[#{alt_text.strip}]\n" : ''
                    post = !title.nil? ? "\n    #{c(%i[b blue])}-- #{title} --" : ''
                    result = pre + res + post
                  end
                rescue StandardError => e
                  MDLess.log.error(e)
                end
              elsif exec_available('chafa')
                MDLess.log.info('Using chafa for image rendering')
                term = '-f sixels'
                term = ENV['TERMINAL_PROGRAM'] =~ /iterm/i ? '-f iterm' : term
                term = ENV['TERMINAL_PROGRAM'] =~ /kitty/i ? '-f kitty' : term
                FileUtils.rm_r '.mdless_tmp', force: true if File.directory?('.mdless_tmp')
                Dir.mkdir('.mdless_tmp')
                Dir.chdir('.mdless_tmp')
                `curl -SsO #{img_path} 2> /dev/null`
                tmp_img = File.basename(img_path)
                img = `chafa #{term} "#{tmp_img}"`
                pre = alt_text ? "    #{c(%i[d blue])}[#{alt_text.strip}]\n" : ''
                post = title ? "\n    #{c(%i[b blue])}-- #{tail} --" : ''
                result = pre + img + post
                Dir.chdir('..')
                FileUtils.rm_r '.mdless_tmp', force: true
              else
                MDLess.log.warn('No viewer for remote images')
              end
            else
              if img_path =~ %r{^[~/]}
                img_path = File.expand_path(img_path)
              elsif MDLess.file
                base = File.expand_path(File.dirname(MDLess.file))
                img_path = File.join(base, img_path)
              end
              if File.exist?(img_path)
                pre = !alt_text.nil? ? "    #{c(%i[d blue])}[#{alt_text.strip}]\n" : ''
                post = !title.nil? ? "\n    #{c(%i[b blue])}-- #{title} --" : ''
                if exec_available('imgcat')
                  img = `imgcat "#{img_path}"`
                elsif exec_available('chafa')
                  term = '-f sixels'
                  term = ENV['TERMINAL_PROGRAM'] =~ /iterm/i ? '-f iterm' : term
                  term = ENV['TERMINAL_PROGRAM'] =~ /kitty/i ? '-f kitty' : term
                  img = `chafa #{term} "#{img_path}"`
                end
                result = pre + img + post
              end
            end
          end
          if result.nil?
            color_image_tag(link, title, alt_text)
          else
            "#{pre_element}#{result}#{xc}#{post_element}"
          end
        end
      end

      def fix_equations(input)
        input.gsub(/((\\\\\[|\$\$)(.*?)(\\\\\]|\$\$)|(\\\\\(|\$)(.*?)(\\\\\)|\$))/) do
          m = Regexp.last_match
          if m[2]
            brackets = [m[2], m[4]]
            equat = m[3]
          else
            brackets = [m[5], m[7]]
            equat = m[6]
          end
          [
            pre_element,
            color('math brackets'),
            brackets[0],
            xc,
            color('math equation'),
            equat,
            color('math brackets'),
            brackets[1],
            xc,
            post_element
          ].join
        end
      end

      def highlight_tags(input)
        tag_color = color('at_tags tag')
        value_color = color('at_tags value')
        input.gsub(/(?<pre>\s|m)(?<tag>@[^ \].?!,("']+)(?:(?<lparen>\()(?<value>.*?)(?<rparen>\)))?/) do
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

      def highlight_wiki_links(input)
        input.gsub(/\[\[(.*?)\]\]/) do
          content = Regexp.last_match(1)
          [
            pre_element,
            color('link brackets'),
            '[[',
            color('link text'),
            content,
            color('link brackets'),
            ']]',
            xc,
            post_element
          ].join
        end
      end

      def postprocess(input)
        input.scrub!

        input = highlight_wiki_links(input) if MDLess.options[:wiki_links]

        if MDLess.options[:inline_footnotes]
          input = insert_footnotes(input)
        else
          footnotes = @@footnotes.map.with_index do |fn, i|
            next if fn.nil?

            color_footnote_def(i)
          end.join("\n")
          input = "#{input}\n\n#{footnotes}"
        end
        # escaped characters
        input.gsub!(/\\(\S)/, '\1')
        # equations
        input = fix_equations(input)
        # misc html
        input.gsub!(%r{<br */?>}, "#{pre_element}\n#{post_element}")
        # format links
        input = reference_links(input) if MDLess.options[:links] == :reference || MDLess.options[:links] == :paragraph
        # lists
        input = fix_lists(input)
        input = render_images(input) if MDLess.options[:local_images]
        input = highlight_tags(input) if MDLess.options[:at_tags] || MDLess.options[:taskpaper]
        fix_colors(input)
      end
    end
  end
end
