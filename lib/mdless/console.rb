module Redcarpet
  module Render
    class Console < Base
      include CLIMarkdown::Colors
      include CLIMarkdown::Theme
      attr_writer :theme, :cols, :log, :options, :file

      @@listitemid = 0
      @@listid = 0
      @@elementid = 0
      @@footnotes = []
      @@headers = []
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

      def valid_lexer?(language)
        lexers = %w(Clipper XBase Cucumber cucumber Gherkin gherkin RobotFramework robotframework abap ada ada95ada2005 ahk antlr-as antlr-actionscript antlr-cpp antlr-csharp antlr-c# antlr-java antlr-objc antlr-perl antlr-python antlr-ruby antlr-rb antlr apacheconf aconf apache applescript as actionscript as3 actionscript3 aspectj aspx-cs aspx-vb asy asymptote autoit Autoit awk gawk mawk nawk basemake bash sh ksh bat bbcode befunge blitzmax bmax boo brainfuck bf bro bugs winbugs openbugs c-objdump c ca65 cbmbas ceylon cfengine3 cf3 cfm cfs cheetah spitfire clojure clj cmake cobol cobolfree coffee-script coffeescript common-lisp cl console control coq cpp c++ cpp-objdump c++-objdumb cxx-objdump croc csharp c# css+django css+jinja css+erb css+ruby css+genshitext css+genshi css+lasso css+mako css+myghty css+php css+smarty css cuda cu cython pyx d-objdump d dart delphi pas pascal objectpascal dg diff udiff django jinja dpatch dtd duel Duel Engine Duel View JBST jbst JsonML+BST dylan-console dylan-repl dylan-lid lid dylan ec ecl elixir ex exs erb erl erlang evoque factor fan fancy fy felix flx fortran fsharp gas genshi kid xml+genshi xml+kid genshitext glsl gnuplot go gooddata-cl gosu groff nroff man groovy gst haml HAML haskell hs haxeml hxml html+cheetah html+spitfire html+django html+jinja html+evoque html+genshi html+kid html+lasso html+mako html+myghty html+php html+smarty html+velocity html http hx haXe hybris hy idl iex ini cfg io ioke ik irc jade JADE jags java jlcon js+cheetah javascript+cheetah js+spitfire javascript+spitfire js+django javascript+django js+jinja javascript+jinja js+erb javascript+erb js+ruby javascript+ruby js+genshitext js+genshi javascript+genshitext javascript+genshi js+lasso javascript+lasso js+mako javascript+mako js+myghty javascript+myghty js+php javascript+php js+smarty javascript+smarty js javascript json jsp julia jl kconfig menuconfig linux-config kernel-config koka kotlin lasso lassoscript lhs literate-haskell lighty lighttpd live-script livescript llvm logos logtalk lua make makefile mf bsdmake mako maql mason matlab matlabsession minid modelica modula2 m2 monkey moocode moon moonscript mscgen msc mupad mxml myghty mysql nasm nemerle newlisp newspeak nginx nimrod nim nsis nsi nsh numpy objdump objective-c++ objectivec++ obj-c++ objc++ objective-c objectivec obj-c objc objective-j objectivej obj-j objj ocaml octave ooc opa openedge abl progress perl pl php php3 php4 php5 plpgsql postgresql postgres postscript pot po pov powershell posh ps1 prolog properties protobuf psql postgresql-console postgres-console puppet py3tb pycon pypylog pypy pytb python py sage python3 py3 qml Qt Meta Language Qt modeling Language racket rkt ragel-c ragel-cpp ragel-d ragel-em ragel-java ragel-objc ragel-ruby ragel-rb ragel raw rb ruby duby rbcon irb rconsole rout rd rebol redcode registry rhtml html+erb html+ruby rst rest restructuredtext rust sass SASS scala scaml SCAML scheme scm scilab scss shell-session smali smalltalk squeak smarty sml snobol sourceslist sources.list sp spec splus s r sql sqlite3 squidconf squid.conf squid ssp stan systemverilog sv tcl tcsh csh tea tex latex text trac-wiki moin treetop ts urbiscript vala vapi vb.net vbnet velocity verilog v vgl vhdl vim xml+cheetah xml+spitfire xml+django xml+jinja xml+erb xml+ruby xml+evoque xml+lasso xml+mako xml+myghty xml+php xml+smarty xml+velocity xml xquery xqy xq xql xqm xslt xtend yaml)
        lexers.include? language.strip
      end

      def hilite_code(code_block, language)
        @log.error('Syntax highlighting requested by pygmentize is not available') if @options[:syntax_higlight] && !exec_available('pygmentize')

        if @options[:syntax_higlight] && exec_available('pygmentize')
          lexer = language && valid_lexer?(language) ? "-l #{language}" : '-g'
          begin
            cmd = [
              'pygmentize -f terminal256',
              "-O style=#{@theme['code_block']['pygments_theme']}",
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
              end.join("\n").blackout(@theme['code_block']['bg']) + "#{xc}\n"
            end
          rescue StandardError => e
            @log.error(e)
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
          end.join("\n").blackout(@theme['code_block']['bg']) + "#{xc}\n"
        end

        [
          xc,
          color('code_block border'),
          '-' * @cols,
          xc,
          "\n",
          color('code_block color'),
          hilite.chomp,
          "\n",
          color('code_block border'),
          '-' * @cols,
          xc
        ].join
      end

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

      def block_code(code, language)
        "\n\n#{hilite_code(code, language)}#{xc}\n\n"
      end

      def block_quote(quote)
        ret = "\n\n"
        quote.split("\n").each do |line|
          ret += [
            color('blockquote marker color'),
            @theme['blockquote']['marker']['character'],
            color('blockquote color'),
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
        case header_level
        when 1
          ansi = color('h1 color')
          pad = color('h1 pad')
          char = @theme['h1']['pad_char'] || '='
          pad += text.length + 2 > @cols ? char * text.length : char * (@cols - (text.length + 1))
        when 2
          ansi = color('h2 color')
          pad = color('h2 pad')
          char = @theme['h2']['pad_char'] || '-'
          pad += text.length + 2 > @cols ? char * text.length : char * (@cols - (text.length + 1))
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
           @options[:pager] == false
          ansi = "\e]1337;SetMark\a#{ansi}"
        end

        "\n#{xc}#{ansi}#{text} #{pad}#{xc}\n\n"
      end

      def hrule()
        "\n\n#{color('hr color')}#{'_' * @cols}#{xc}\n\n"
      end

      def list(contents, list_type)
        @@listitemid = 0
        @@listid += 1
        "<<list#{@@listid}>>#{contents}<</list#{@@listid}>>"
      end

      def list_item(text, list_type)
        case list_type
        when :unordered
          [
            "#{color('list bullet')}• ",
            color('list color'),
            text,
            xc
          ].join('')
        when :ordered
          @@listitemid += 1
          [
            color('list number'),
            "#{@@listitemid}. ",
            color('list color'),
            text,
            xc
          ].join('')
        end
      end

      def paragraph(text)
        "#{xc}#{text}#{xc}#{x}\n\n"
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
        formatted = CLIMarkdown::MDTableCleanup.new([
          "#{header}",
          table_header_row,
          "|\n",
          "#{body}\n\n"
        ].join(''))
        res = formatted.to_md
        "#{color_table(res)}\n"
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
          @theme['code_span']['character'],
          color('code_span color'),
          code,
          color('code_span marker'),
          @theme['code_span']['character'],
          xc,
          post_element
        ].join('')
      end

      def double_emphasis(text)
        [
          pre_element,
          color('emphasis bold'),
          @theme['emphasis']['bold_character'],
          text,
          @theme['emphasis']['bold_character'],
          xc,
          post_element
        ].join
      end

      def emphasis(text)
        [
          pre_element,
          color('emphasis italic'),
          @theme['emphasis']['italic_character'],
          text,
          @theme['emphasis']['italic_character'],
          xc,
          post_element
        ].join
      end

      def triple_emphasis(text)
        [
          pre_element,
          color('emphasis bold-italic'),
          @theme['emphasis']['italic_character'],
          @theme['emphasis']['bold_character'],
          text,
          @theme['emphasis']['bold_character'],
          @theme['emphasis']['italic_character'],
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
        if (exec_available('imgcat') || exec_available('chafa')) && @options[:local_images]
          if exec_available('imgcat')
            @log.info('Using imgcat for image rendering')
          elsif exec_available('chafa')
            @log.info('Using chafa for image rendering')
          end
          img_path = link
          if img_path =~ /^http/ && @options[:remote_images]
            if exec_available('imgcat')
              @log.info('Using imgcat for image rendering')
              begin
                res, s = Open3.capture2(%(curl -sS "#{img_path}" 2> /dev/null | imgcat))

                if s.success?
                  pre = !alt_text.nil? ? "    #{c(%i[d blue])}[#{alt_text.strip}]\n" : ''
                  post = !title.nil? ? "\n    #{c(%i[b blue])}-- #{title} --" : ''
                  result = pre + res + post
                end
              rescue StandardError => e
                @log.error(e)
              end
            elsif exec_available('chafa')
              @log.info('Using chafa for image rendering')
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
              @log.warn('No viewer for remote images')
            end
          else
            if img_path =~ %r{^[~/]}
              img_path = File.expand_path(img_path)
            elsif @file
              base = File.expand_path(File.dirname(@file))
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
        res = color_link(link, title, content)
        @@links << {
          link: res,
          url: link,
          title: title,
          content: content
        }
        res
      end

      def color_tags(html)
        html.gsub(%r{(<\S+( .*?)?/?>)}, "#{color('html brackets')}\\1#{xc}")
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

      def fix_lists(input, indent = 0)
        input.gsub(%r{(?<line><<list(?<id>\d+)>>(?<content>.*?)<</list\k<id>>>)}m) do
          m = Regexp.last_match
          fix_lists(m['content'].split(/\n/).map do |l|
            outdent = l.scan(%r{<</list\d+>>}).count
            indent += l.scan(/<<list\d+>>/).count
            indent -= outdent
            "#{' ' * indent}#{l}"
          end.join("\n"), indent)
        end + "\n"
      end

      def get_headers(input)
        unless @@headers && !@@headers.empty?
          @@headers = []
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
            @@headers << [
              '#' * hlevel,
              title,
              h[0]
            ]
          end
        end

        @@headers
      end

      def preprocess(input)
        in_yaml = false
        if input.split("\n")[0] =~ /(?i-m)^---[ \t]*?(\n|$)/
          @log.info('Found YAML')
          # YAML
          in_yaml = true
          input.sub!(/(?i-m)^---[ \t]*\n([\s\S]*?)\n[-.]{3}[ \t]*\n/m) do
            m = Regexp.last_match
            @log.info('Processing YAML Header')
            lines = m[0].split(/\n/)
            longest = lines.inject { |memo, word| memo.length > word.length ? memo : word }.length
            longest = longest < @cols ? longest + 1 : @cols
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

        first_line = input.split("\n").first
        if !in_yaml && first_line =~ /(?i-m)^[\w ]+:\s+\S+/
          @log.info('Found MMD Headers')
          input.sub!(/(?i-m)^([\S ]+:[\s\S]*?)+(?=\n\n)/) do |mmd|
            lines = mmd.split(/\n/)
            return mmd if lines.count > 20

            longest = lines.inject { |memo, word| memo.length > word.length ? memo : word }.length
            longest = longest < @cols ? longest + 1 : @cols
            lines.map do |line|
              line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
              line = "#{color('metadata color')}#{line}"
              line += "\u00A0" * (longest - line.uncolor.strip.length)
              line + xc
            end.join("\n") + "#{"\u00A0" * longest}#{xc}\n"
          end

        end

        ## Replace setex headers with ATX
        input.gsub!(/^([^\n]+)\n={3,}\s*$/m, "# \\1\n")
        input.gsub!(/^([^\n]+?)\n-{3,}\s*$/m, "## \\1\n")

        @@headers = get_headers(input)

        if @options[:section]
          new_content = []
          @options[:section].each do |sect|
            in_section = false
            top_level = 1
            input.split(/\n/).each do |graf|
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
                elsif title.downcase == @@headers[sect - 1][1].downcase
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
          next if graf =~ /^$/

          links_added = false

          @@links.each do |link|
            if graf =~ /#{Regexp.escape(link[:link])}/
              url = link[:url].uncolor
              content = link[:content]
              title = link[:title]&.uncolor
              graf.gsub!(/#{Regexp.escape(link[:link])}/, color_link_reference(url, counter, content))
              if @options[:links] == :paragraph
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

        if @options[:links] == :paragraph
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

      def postprocess(input)
        if @options[:inline_footnotes]
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
        input.gsub!(/((\\\\\[|\$\$)(.*?)(\\\\\]|\$\$)|(\\\\\(|\$)(.*?)(\\\\\)|\$))/) do
          m = Regexp.last_match
          if m[2]
            brackets = [m[2], m[4]]
            equat = m[3]
          else
            brackets = [m[5], m[7]]
            equat = m[6]
          end
          "#{pre_element}#{c(%i[b black])}#{brackets[0]}#{xc}#{c(%i[b blue])}#{equat}#{c(%i[b black])}#{brackets[1]}#{xc}#{post_element}"
        end
        # misc html
        input.gsub!(%r{<br */?>}, "\n")
        # format links
        if @options[:links] == :reference || @options[:links] == :paragraph
          input = reference_links(input)
        end
        # lists
        input = fix_lists(input, 0)

        fix_colors(input)
      end
    end
  end
end
