require 'fileutils'
require 'yaml'

module Redcarpet
  module Render
    class Console < Base
      include CLIMarkdown::Colors
      include CLIMarkdown::Theme
      attr_writer :theme, :cols, :log
      attr_writer :listitemid, :list_indent

      def xc
        color('text')
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
          system "which #{cli}", out: File::NULL, err: File::NULL
        end
      end

      def valid_lexer?(language)
        lexers = %w(Clipper XBase Cucumber cucumber Gherkin gherkin RobotFramework robotframework abap ada ada95ada2005 ahk antlr-as antlr-actionscript antlr-cpp antlr-csharp antlr-c# antlr-java antlr-objc antlr-perl antlr-python antlr-ruby antlr-rb antlr apacheconf aconf apache applescript as actionscript as3 actionscript3 aspectj aspx-cs aspx-vb asy asymptote autoit Autoit awk gawk mawk nawk basemake bash sh ksh bat bbcode befunge blitzmax bmax boo brainfuck bf bro bugs winbugs openbugs c-objdump c ca65 cbmbas ceylon cfengine3 cf3 cfm cfs cheetah spitfire clojure clj cmake cobol cobolfree coffee-script coffeescript common-lisp cl console control coq cpp c++ cpp-objdump c++-objdumb cxx-objdump croc csharp c# css+django css+jinja css+erb css+ruby css+genshitext css+genshi css+lasso css+mako css+myghty css+php css+smarty css cuda cu cython pyx d-objdump d dart delphi pas pascal objectpascal dg diff udiff django jinja dpatch dtd duel Duel Engine Duel View JBST jbst JsonML+BST dylan-console dylan-repl dylan-lid lid dylan ec ecl elixir ex exs erb erl erlang evoque factor fan fancy fy felix flx fortran fsharp gas genshi kid xml+genshi xml+kid genshitext glsl gnuplot go gooddata-cl gosu groff nroff man groovy gst haml HAML haskell hs haxeml hxml html+cheetah html+spitfire html+django html+jinja html+evoque html+genshi html+kid html+lasso html+mako html+myghty html+php html+smarty html+velocity html http hx haXe hybris hy idl iex ini cfg io ioke ik irc jade JADE jags java jlcon js+cheetah javascript+cheetah js+spitfire javascript+spitfire js+django javascript+django js+jinja javascript+jinja js+erb javascript+erb js+ruby javascript+ruby js+genshitext js+genshi javascript+genshitext javascript+genshi js+lasso javascript+lasso js+mako javascript+mako js+myghty javascript+myghty js+php javascript+php js+smarty javascript+smarty js javascript json jsp julia jl kconfig menuconfig linux-config kernel-config koka kotlin lasso lassoscript lhs literate-haskell lighty lighttpd live-script livescript llvm logos logtalk lua make makefile mf bsdmake mako maql mason matlab matlabsession minid modelica modula2 m2 monkey moocode moon moonscript mscgen msc mupad mxml myghty mysql nasm nemerle newlisp newspeak nginx nimrod nim nsis nsi nsh numpy objdump objective-c++ objectivec++ obj-c++ objc++ objective-c objectivec obj-c objc objective-j objectivej obj-j objj ocaml octave ooc opa openedge abl progress perl pl php php3 php4 php5 plpgsql postgresql postgres postscript pot po pov powershell posh ps1 prolog properties protobuf psql postgresql-console postgres-console puppet py3tb pycon pypylog pypy pytb python py sage python3 py3 qml Qt Meta Language Qt modeling Language racket rkt ragel-c ragel-cpp ragel-d ragel-em ragel-java ragel-objc ragel-ruby ragel-rb ragel raw rb ruby duby rbcon irb rconsole rout rd rebol redcode registry rhtml html+erb html+ruby rst rest restructuredtext rust sass SASS scala scaml SCAML scheme scm scilab scss shell-session smali smalltalk squeak smarty sml snobol sourceslist sources.list sp spec splus s r sql sqlite3 squidconf squid.conf squid ssp stan systemverilog sv tcl tcsh csh tea tex latex text trac-wiki moin treetop ts urbiscript vala vapi vb.net vbnet velocity verilog v vgl vhdl vim xml+cheetah xml+spitfire xml+django xml+jinja xml+erb xml+ruby xml+evoque xml+lasso xml+mako xml+myghty xml+php xml+smarty xml+velocity xml xquery xqy xq xql xqm xslt xtend yaml)
        return lexers.include? language.strip
      end

      def hilite_code(code_block, language)
        if exec_available('pygmentize')
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
          end.join("\n")
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
        "\n#{hilite_code(code, language)}\n"
      end

      def block_quote(quote)
        ret = "\n"
        quote.split("\n").each do |line|
          ret += [
            color('blockquote marker color'),
            @theme['blockquote']['marker']['character'],
            color('blockquote color'),
            line,
            "\n"
          ].join('')
        end
        "#{ret}\n"
      end

      def block_html(raw_html)
        raw_html
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
        "\n#{color('hr color')}#{'_' * @cols}#{xc}\n"
      end

      def list(contents, list_type)
        @listitemid = 0
        @list_indent += 1
        contents
        @list_indent = 0
      end

      def list_item(text, list_type)
        indent = "\t" * @list_indent
        case list_type
        when :unordered
          [
            indent,
            "#{color('list bullet')}• ",
            color('list color'),
            text,
            xc
          ].join('')
        when :ordered
          @listitemid += 1
          [
            indent,
            color('list number'),
            "#{@listitemid}. ",
            color('list color'),
            text,
            xc
          ].join('')
        end
      end

      def paragraph(text)
        "#{xc}#{text}#{xc}\n"
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
          "#{body}\n"
        ].join(''))
        res = formatted.to_md
        color_table(res)
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
          color('link brackets'),
          '<',
          color('link url'),
          link,
          color('link brackets'),
          '>',
          xc
        ].join('')
      end

      def codespan(code)
        [
          color('code_span marker'),
          '`',
          color('code_span color'),
          code,
          color('code_span marker'),
          '`',
          xc
        ].join('')
      end

      def double_emphasis(text)
        "#{color('emphasis bold')}#{text}#{xc}"
      end

      def emphasis(text)
        "#{color('emphasis italic')}#{text}#{xc}"
      end

      def triple_emphasis(text)
        "#{color('emphasis bold-italic')}#{text}#{xc}"
      end

      def highlight(text)
        "#{color('highlight')}#{text}#{xc}"
      end

      def image(link, title, alt_text)
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
          xc
        ].join
      end

      def linebreak()
        "\n"
      end

      def link(link, title, content)
        [
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
          xc
        ].join
      end

      def color_tags(html)
        html.gsub(%r{(<\S+( .*?)?/?>)}, "#{color('html brackets')}\\1#{xc}")
      end

      def raw_html(raw_html)
        "#{color('html color')}#{color_tags(raw_html)}#{xc}"
      end

      def strikethrough(text)
        "#{color('strikethrough')}#{text}#{xc}"
      end

      def superscript(text)
        "#{color('super')}^#{text}#{xc}"
      end

      def footnotes(text)
        [
          color('footnote note'),
          text,
          "\n",
          xc,
        ].join('')
      end

      def footnote_def(text, idx)
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

      def footnote_ref(text)
        [
          color('footnote title'),
          text,
          xc
        ].join('')
      end
    end
  end
end

module CLIMarkdown
  class Converter
    include Colors
    include Theme

    attr_reader :helpers, :log

    def version
      "#{CLIMarkdown::EXECUTABLE_NAME} #{CLIMarkdown::VERSION}"
    end

    def initialize(args)
      @log = Logger.new(STDERR)
      @log.level = Logger::INFO

      @options = {}
      optparse = OptionParser.new do |opts|
        opts.banner = "#{version} by Brett Terpstra\n\n> Usage: #{CLIMarkdown::EXECUTABLE_NAME} [options] [path]\n\n"

        @options[:color] = true
        opts.on('-c', '--[no-]color', 'Colorize output (default on)') do |c|
          @options[:color] = c
        end

        opts.on('-d', '--debug LEVEL', 'Level of debug messages to output') do |level|
          if level.to_i > 0 && level.to_i < 5
            @log.level = 5 - level.to_i
          else
            $stderr.puts "Error: Log level out of range (1-4)"
            Process.exit 1
          end
        end

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end

        @options[:local_images] = false
        @options[:remote_images] = false
        opts.on('-i', '--images=TYPE', 'Include [local|remote (both)] images in output (requires chafa or imgcat, default NONE). imgcat does not work with pagers, use with -P' ) do |type|
          unless exec_available('imgcat') || exec_available('chafa')# && ENV['TERM_PROGRAM'] == 'iTerm.app'
            @log.warn('images turned on but imgcat/chafa not found')
          else
            if type =~ /^(r|b|a)/i
              @options[:local_images] = true
              @options[:remote_images] = true
            elsif type =~ /^l/i
              @options[:local_images] = true
            end
          end
        end
        opts.on('-I', '--all-images', 'Include local and remote images in output (requires imgcat or chafa)') do
          if exec_available('imgcat') || exec_available('chafa') # && ENV['TERM_PROGRAM'] == 'iTerm.app'
            @options[:local_images] = true
            @options[:remote_images] = true
          else
            @log.warn('images turned on but imgcat/chafa not found')
          end
        end

        @options[:links] = :inline
        opts.on('--links=FORMAT', 'Link style ([inline, reference], default inline) [NOT CURRENTLY IMPLEMENTED]') do |format|
          if format =~ /^r/i
            @options[:links] = :reference
          end
        end

        @options[:list] = false
        opts.on('-l', '--list', 'List headers in document and exit' ) do
          @options[:list] = true
        end

        @options[:pager] = true
        opts.on('-p', '--[no-]pager', 'Formatted output to pager (default on)') do |p|
          @options[:pager] = p
        end

        opts.on('-P', 'Disable pager (same as --no-pager)') do
          @options[:pager] = false
        end

        @options[:section] = nil
        opts.on('-s', '--section=NUMBER[,NUMBER]', 'Output only a headline-based section of the input (numeric from --list)') do |section|
          @options[:section] = section.split(/ *, */).map(&:strip).map(&:to_i)
        end

        @options[:theme] = 'default'
        opts.on('-t', '--theme=THEME_NAME', 'Specify an alternate color theme to load') do |theme|
          @options[:theme] = theme
        end

        opts.on('-v', '--version', 'Display version number') do
          puts version
          exit
        end

        @options[:width] = `tput cols`.strip.to_i
        opts.on('-w', '--width=COLUMNS', 'Column width to format for (default: terminal width)') do |columns|
          @options[:width] = columns.to_i
        end
      end

      begin
        optparse.parse!
      rescue OptionParser::ParseError => e
        warn "error: #{e.message}"
        exit 1
      end

      @theme = load_theme(@options[:theme])
      @cols = @options[:width] - 2
      @output = ''
      @headers = []
      @setheaders = []

      input = ''
      @ref_links = {}
      @footnotes = {}

      renderer = Redcarpet::Render::Console.new
      renderer.theme = @theme
      renderer.cols = @cols
      renderer.log = @log
      renderer.listitemid = 0
      renderer.list_indent = 0

      markdown = Redcarpet::Markdown.new(renderer,
                                         autolink: true,
                                         fenced_code_blocks: true,
                                         footnotes: true,
                                         hard_wrap: false,
                                         highlight: true,
                                         lax_spacing: true,
                                         quote: false,
                                         space_after_headers: false,
                                         strikethrough: true,
                                         superscript: true,
                                         tables: true,
                                         underline: false)

      if !args.empty?
        files = args.delete_if { |f| !File.exist?(f) }
        files.each do |file|
          @log.info(%(Processing "#{file}"))
          @file = file
          begin
            input = IO.read(file).force_encoding('utf-8')
          rescue StandardError
            input = IO.read(file)
          end
          input.gsub!(/\r?\n/, "\n")
          if @options[:list]
            puts list_headers(input)
            Process.exit 0
          else
            @output = markdown.render(input)
          end
        end
        printout
      elsif !$stdin.isatty
        @file = nil
        begin
          input = $stdin.read.force_encoding('utf-8')
        rescue StandardError
          input = $stdin.read
        end
        input.gsub!(/\r?\n/, "\n")
        if @options[:list]
          puts list_headers(input)
          Process.exit 0
        else
          @output = markdown.render(input)
        end
        printout
      else
        warn 'No input'
        Process.exit 1
      end
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
        res = val.split(/ /).map { |k| k.to_sym }
        c(res)
      else
        c([:reset])
      end
    end

    def get_headers(input)
      unless @headers && !@headers.empty?
        @headers = []
        headers = input.scan(/^((?!#!)(\#{1,6})\s*([^#]+?)(?: #+)?\s*|(\S.+)\n([=-]+))$/i)

        headers.each {|h|
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
            '#'*hlevel,
            title,
            h[0]
          ]
        }
      end

      @headers
    end

    def list_headers(input)
      h_adjust = highest_header(input) - 1
      input.gsub!(/^(#+)/) do
        m = Regexp.last_match
        new_level = m[1].length - h_adjust
        new_level > 0 ? '#' * new_level : ''
      end

      @headers = get_headers(input)
      last_level = 0
      headers_out = []
      @headers.each_with_index do |h,idx|
        level = h[0].length - 1
        title = h[1]

        level = last_level + 1 if level - 1 > last_level

        last_level = level

        subdoc = case level
                 when 0
                   ''
                 when 1
                   '- '
                 when 2
                   '+ '
                 when 3
                   '* '
                 else
                   '  '
                 end
        headers_out.push format('%<d>d: %<s>s',
                                d: idx + 1,
                                s: "#{c(%i[x black])}#{'.' * level}#{c(%i[x yellow])}#{subdoc}#{title.strip}#{xc}")
      end

      headers_out.join("\n")
    end

    def highest_header(input)
      @headers = get_headers(input)
      top = 6
      @headers.each {|h|
        top = h[0].length if h[0].length < top
      }
      top
    end



    def clean_markers(input)
      input.gsub!(/^(\e\[[\d;]+m)?[%~] ?/,'\1')
      input.gsub!(/^(\e\[[\d;]+m)*>(\e\[[\d;]+m)?( +)/,' \3\1\2')
      input.gsub!(/^(\e\[[\d;]+m)*>(\e\[[\d;]+m)?/,'\1\2')
      input.gsub!(/(\e\[[\d;]+m)?@@@(\e\[[\d;]+m)?$/,'')
      input
    end

    def update_inline_links(input)
      links = {}
      counter = 1
      input.gsub!(/(?<=\])\((.*?)\)/) do
        links[counter] = Regexp.last_match(1).uncolor
        "[#{counter}]"
      end
    end

    def find_color(line, nullable = false)
      return line if line.nil?

      colors = line.scan(/\e\[[\d;]+m/)
      if colors.size&.positive?
        colors[-1]
      else
        nullable ? nil : xc
      end
    end

    def pad_max(block, eol='')
      block.split(/\n/).map { |l|
        new_code_line = l.gsub(/\t/, '    ')
        orig_length = new_code_line.size + 8 + eol.size
        pad_count = [@cols - orig_length, 0].max

        [
          new_code_line,
          eol,
          ' ' * ([pad_count-1,0].max)
        ].join
      }.join("\n")
    end



    def convert_markdown(input)
      ## Replace setex headers with ATX
      input.gsub!(/^([^\n]+)\n={3,}\s*$/m, "# \\1\n")
      input.gsub!(/^([^\n]+?)\n-{3,}\s*$/m, "## \\1\n")

      @headers = get_headers(input)
      input += "\n\n@@@"
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
              line = color('metadata marker') + "%% " + color('metadata border') + line
            else
              line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
              line = color('metadata marker') + "%% " + color('metadata color') + line
            end
            if @cols - line.uncolor.size > 0
              line += " "*(@cols-line.uncolor.size)
            end
          }.join("\n") + "#{xc}\n"
        end
      end

      if !in_yaml && input.gsub(/\n/,' ') =~ /(?i-m)^\w.+:\s+\S+ /
        @log.info("Found MMD Headers")
        input.sub!(/(?i-m)^([\S ]+:[\s\S]*?)+(?=\n\n)/) do |mmd|
          mmd.split(/\n/).map {|line|
            line.sub!(/^(.*?:)[ \t]+(\S)/, '\1 \2')
            line = color('metadata marker') + "%% " + color('metadata color') + line
            if @cols - line.uncolor.size > 0
              line += " "*(@cols - line.uncolor.size)
            end
          }.join("\n") + " "*@cols + "#{xc}\n"
        end

      end

      # Gather reference links
      input.gsub!(/^\s{,3}(?<![\e*])\[\b(.+)\b\]: +(.+)/) do |m|
        match = Regexp.last_match
        @ref_links[match[1]] = match[2]
        ''
      end

      # Gather footnotes (non-inline)
      # TODO: Need to implement option to output links as references
      input.gsub!(/^ {,3}(?<!\*)(?:\e\[[\d;]+m)*\[(?:\e\[[\d;]+m)*\^(?:\e\[[\d;]+m)*\b(.+)\b(?:\e\[[\d;]+m)*\]: *(.*?)\n/) do |m|
        match = Regexp.last_match
        @footnotes[match[1].uncolor] = match[2].uncolor
        ''
      end

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
              elsif title.downcase == @headers[sect - 1][1].downcase
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

      # fenced code block parsing
      input.gsub!(/(?i-m)(^[ \t]*[`~]{3,})([\s\S]*?)\n([\s\S]*?)\1/m) do
        language = nil
        m = Regexp.last_match
        first_indent = m[1].gsub(/\t/, '    ').match(/^ */)[0].size

        if m[2] && !m[2].strip.empty?
          language = m[2].strip.split(/ /)[0]
          code_block = pad_max(m[3].to_s, '')
          leader = language || 'code'
        else
          first_line = m[3].to_s.split(/\n/)[0]

          if first_line =~ %r{^\s*#!.*/.+}
            shebang = first_line.match(%r{^\s*#!.*/(?:env )?([^/]+)$})
            language = shebang[1]
            code_block = m[3]
            leader = shebang[1] || 'code'
          else
            code_block = pad_max(m[3].to_s, "#{color('code_block eol')}¬")
            leader = language || 'code'
          end
        end
        leader += xc

        hiliteCode(language, code_block, leader, first_indent, m[0])
      end

      # remove empty links
      input.gsub!(/\[(.*?)\]\(\s*?\)/, '\1')
      input.gsub!(/\[(.*?)\]\[\]/, '[\1][\1]')

      lines = input.split(/\n/)

      # previous_indent = 0

      lines.map!.with_index do |aLine, i|
        line = aLine.dup
        clean_line = line.dup.uncolor


        if clean_line.uncolor =~ /(^[%~])/ # || clean_line.uncolor =~ /^( {4,}|\t+)/
          ## TODO: find indented code blocks and prevent highlighting
          ## Needs to miss block indented 1 level in lists
          ## Needs to catch lists in code
          ## Needs to avoid within fenced code blocks
          # if line =~ /^([ \t]+)([^*-+]+)/
          #   indent = $1.gsub(/\t/, "    ").size
          #   if indent >= previous_indent
          #     line = "~" + line
          #   end
          #   p [indent, previous_indent]
          #   previous_indent = indent
          # end
        else
          # list items
          # TODO: Fix ordered list numbering, pad numbers based on total number of list items
          line.gsub!(/^(\s*)([*\-+]|\d+\.) /) do |m|
            match = Regexp.last_match
            last = find_color(match.pre_match)
            mcolor = match[2] =~ /^\d+\./ ? 'list number' : 'list bullet'
            indent = match[1] || ''
            [
              indent,
              color(mcolor),
              match[2], " ",
              color('list color')
            ].join
          end

          # definition lists
          line.gsub!(/^(:\s*)(.*?)/) do |m|
            match = Regexp.last_match
            [
              color('dd marker'),
              match[1],
              " ",
              color('dd color'),
              match[2],
              xc
            ].join
          end

          # place footnotes under paragraphs that reference them
          if line =~ /\[(?:\e\[[\d;]+m)*\^(?:\e\[[\d;]+m)*(\S+)(?:\e\[[\d;]+m)*\]/
            match = Regexp.last_match
            key = match[1].uncolor
            if @footnotes.key? key
              line = "#{xc}#{line}"
              line += "\n\n#{color('footnote brackets')}[#{color('footnote caret')}^#{color('footnote title')}#{key}#{color('footnote brackets')}]: #{color('footnote note')}#{@footnotes[key]}#{xc}"
              @footnotes.delete(key)
            end
          end

          # color footnote references
          line.gsub!(/\[\^(\S+)\]/) do |m|
            match = Regexp.last_match
            last = find_color(match.pre_match, true)
            counter = i
            while last.nil? && counter > 0
              counter -= 1
              find_color(lines[counter])
            end
            "#{color('footnote brackets')}[#{color('footnote caret')}^#{color('footnote title')}#{match[1]}#{color('footnote brackets')}]" + (last ? last : xc)
          end

          # make reference links inline
          line.gsub!(/(?<![\e*])\[(\b.*?\b)?\]\[(\b.+?\b)?\]/) do |m|
            match = Regexp.last_match
            title = match[2] || ''
            text = match[1] || ''
            if match[2] && @ref_links.key?(title.downcase)
              "[#{text}](#{@ref_links[title]})"
            elsif match[1] && @ref_links.key?(text.downcase)
              "[#{text}](#{@ref_links[text]})"
            else
              if input.match(/^#+\s*#{Regexp.escape(text)}/i)
                "[#{text}](##{text})"
              else
                match[1]
              end
            end
          end

          # color inline links
          line.gsub!(/(?<![\e*!])\[(\S.*?\S)\]\((\S.+?\S)\)/) do |m|
            match = Regexp.last_match
            color_link(match.pre_match, match[1], match[2])
          end

          # horizontal rules
          line.gsub!(/^ {,3}([\-*] ?){3,}$/) do |m|
            color('hr color') + '_'*@cols + xc
          end

          # escaped characters
          line.gsub!(/\\(\S)/,'\1')

          # bold, bold/italic
          line.gsub!(/(?<pre>^|[ "'\(“])(?<open>[\*_]{2,3})(?<content>[^\*_\s][^\*_]+?[^\*_\s])[\*_]{2,3}/) do |m|
            match = Regexp.last_match
            last = find_color(match.pre_match, true)
            counter = i
            while last.nil? && counter > 0
              counter -= 1
              last = find_color(lines[counter])
            end
            emph = match['open'].length == 2 ? color('emphasis bold') : color('emphasis bold-italic')
            "#{match['pre']}#{emph}#{match['content']}" + (last ? last : xc)
          end

          # italic
          line.gsub!(/(?<pre>^|[ "'\(“])[\*_](?<content>[^\*_\s][^\*_]+?[^\*_\s])[\*_]/) do |m|
            match = Regexp.last_match
            last = find_color(match.pre_match, true)
            counter = i
            while last.nil? && counter > 0
              counter -= 1
              last = find_color(lines[counter])
            end
            "#{match['pre']}#{color('emphasis italic')}#{match[2]}" + (last ? last : xc)
          end

          # equations
          line.gsub!(/((\\\\\[|\$\$)(.*?)(\\\\\]|\$\$)|(\\\\\(|\$)(.*?)(\\\\\)|\$))/) do |m|
            match = Regexp.last_match
            last = find_color(match.pre_match)
            if match[2]
              brackets = [match[2], match[4]]
              equat = match[3]
            else
              brackets = [match[5], match[7]]
              equat = match[6]
            end
            "#{c(%i[b black])}#{brackets[0]}#{xc}#{c(%i[b blue])}#{equat}#{c(%i[b black])}#{brackets[1]}" + (last ? last : xc)
          end

          # misc html
          line.gsub!(%r{<br/?>}, "\n")
          line.gsub!(%r{(?i-m)((</?)(\w+[\s\S]*?)(>))}) do
            match = Regexp.last_match
            last = find_color(match.pre_match)
            [
              color('html brackets'),
              match[2],
              color('html color'),
              match[3],
              color('html brackets'),
              match[4],
              last || xc
            ].join
          end

          # inline code spans
          line.gsub!(/`(.*?)`/) do
            match = Regexp.last_match
            last = find_color(match.pre_match, true)
            [
              color('code_span marker'),
              '`',
              color('code_span color'),
              match[1],
              color('code_span marker'),
              '`',
              last || xc
            ].join
          end
        end

        ## Should force a foreground color but doesn't...
        # unless line =~ /^\s*\e\[[\d;]+m/
        #   line.sub!(/^(\s*)/, "\\1#{color('text')}")
        # end

        line
      end

      input = lines.join("\n")

      # images
      input.gsub!(/^(.*?)!\[(.*)?\]\((.*?\.(?:png|gif|jpg))( +.*)?\)/) do
        match = Regexp.last_match
        if match[1].uncolor =~ /^( {4,}|\t)+/
          match[0]
        else
          tail = match[4].nil? ? '' : " "+match[4].strip
          result = nil
          if (exec_available('imgcat') || exec_available('chafa')) && @options[:local_images]
            if match[3]
              img_path = match[3]
              if img_path =~ /^http/ && @options[:remote_images]

                if exec_available('chafa')
                  if File.directory?('.mdless_tmp')
                    FileUtils.rm_r '.mdless_tmp', force: true
                  end
                  Dir.mkdir('.mdless_tmp')
                  Dir.chdir('.mdless_tmp')
                  `curl -SsO #{img_path} 2> /dev/null`
                  tmp_img = File.basename(img_path)
                  img = `chafa "#{tmp_img}"`
                  pre = match[2].size > 0 ? "    #{c(%i[d blue])}[#{match[2].strip}]\n" : ''
                  post = tail.size > 0 ? "\n    #{c(%i[b blue])}-- #{tail} --" : ''
                  result = pre + img + post
                  Dir.chdir('..')
                  FileUtils.rm_r '.mdless_tmp', force: true
                else
                  if exec_available('imgcat')
                    begin
                      res, s = Open3.capture2(%Q{curl -sS "#{img_path}" 2> /dev/null | imgcat})

                      if s.success?
                        pre = match[2].size > 0 ? "    #{c(%i[d blue])}[#{match[2].strip}]\n" : ''
                        post = tail.size > 0 ? "\n    #{c(%i[b blue])}-- #{tail} --" : ''
                        result = pre + res + post
                      end
                    rescue => e
                      @log.error(e)
                    end
                  else
                    @log.warn('No viewer for remote images')
                  end
                end
              else
                if img_path =~ %r{^[~/]}
                  img_path = File.expand_path(img_path)
                elsif @file
                  base = File.expand_path(File.dirname(@file))
                  img_path = File.join(base, img_path)
                end
                if File.exist?(img_path)
                  pre = !match[2].empty? ? "    #{c(%i[d blue])}[#{match[2].strip}]\n" : ''
                  post = !tail.empty? ? "\n    #{c(%i[b blue])}-- #{tail} --" : ''
                  if exec_available('chafa')
                    img = `chafa "#{img_path}"`
                  elsif exec_available('imgcat')
                    img = `imgcat "#{img_path}"`
                  end
                  result = pre + img + post
                end
              end
            end
          end
          if result.nil?
            match[1] + color_image(match.pre_match, match[2], match[3] + tail) + xc
          else
            match[1] + result + xc
          end
        end
      end

      @footnotes.each do |t, v|
        input += [
          "\n\n",
          color('footnote brackets'),
          '[',
          color('footnote caret'),
          '^',
          color('footnote title'),
          t,
          color('footnote brackets'),
          ']: ',
          color('footnote note'),
          v,
          xc
        ].join
      end

      @output += input
    end

    def page(text, &callback)
      read_io, write_io = IO.pipe

      input = $stdin

      pid = Kernel.fork do
        write_io.close
        input.reopen(read_io)
        read_io.close

        # Wait until we have input before we start the pager
        IO.select [input]

        pager = which_pager
        @log.info("Using #{pager} as pager")
        begin
          exec(pager.join(' '))
        rescue SystemCallError => e
          @log.error(e)
          exit 1
        end
      end

      begin
        read_io.close
        write_io.write(text)
        write_io.close
      rescue SystemCallError
        exit 1
      end

      _, status = Process.waitpid2(pid)
      status.success?
    end

    def color_table(input)
      first = true
      input.split(/\n/).map{|line|
        if first
          if line =~ /^\+-+/
            line.gsub!(/^/, color('table border'))
          else
            first = false
            line.gsub!(/\|/, "#{color('table border')}|#{color('table header')}")
          end
        elsif line.strip =~ /^[|:\- +]+$/
          line.gsub!(/^(.*)$/, "#{color('table border')}\\1#{color('table color')}")
          line.gsub!(/([:\-+]+)/,"#{color('table divider')}\\1#{color('table border')}")
        else
          line.gsub!(/\|/, "#{color('table border')}|#{color('table color')}")
        end
      }.join("\n")
    end

    def cleanup_tables(input)
      formatted = MDTableCleanup.new(input)
      res = formatted.to_md
      color_table(res)
    end

    def printout
      out = @output.rstrip.split(/\n/).map do |p|
        p.wrap(@cols, color('text'))
      end.join("\n")

      unless out.size&.positive?
        @log.warn 'No results'
        Process.exit
      end

      # out = cleanup_tables(out)
      out = clean_markers(out)
      out = "#{out.gsub(/\n{2,}/m, "\n\n")}#{xc}"

      out.uncolor! unless @options[:color]

      if @options[:pager]
        page(out)
      else
        $stdout.print out.rstrip
      end
    end

    def which_pager
      # pagers = [ENV['PAGER'], ENV['GIT_PAGER']]
      pagers = [ENV['PAGER']]

      # if exec_available('git')
      #   git_pager = `git config --get-all core.pager || true`.split.first
      #   git_pager && pagers.push(git_pager)
      # end

      pagers.concat(['less', 'more', 'cat', 'pager'])

      pagers.select! do |f|
        if f
          if f.strip =~ /[ |]/
            f
          elsif f == 'most'
            @log.warn('most not allowed as pager')
            false
          else
            system "which #{f}", out: File::NULL, err: File::NULL
          end
        else
          false
        end
      end

      pg = pagers.first
      args = case pg
             # when 'delta'
             #   ' --pager="less -Xr"'
             when 'less'
               ' -Xr'
             # when 'bat'
             #   ' -p --pager="less -Xr"'
             else
               ''
             end

      [pg, args]
    end

    def exec_available(cli)
      if File.exist?(File.expand_path(cli))
        File.executable?(File.expand_path(cli))
      else
        system "which #{cli}", out: File::NULL, err: File::NULL
      end
    end
  end
end
