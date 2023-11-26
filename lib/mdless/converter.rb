require 'fileutils'
require 'yaml'

module CLIMarkdown
  class Converter
    include Colors
    include Theme

    attr_reader :helpers, :log

    def version
      "#{CLIMarkdown::EXECUTABLE_NAME} #{CLIMarkdown::VERSION}"
    end

    def default(option, default)
      if @options[option].nil?
        @options[option] = default
      end
    end

    def initialize(args)
      @log = Logger.new($stderr)
      @log.level = Logger::WARN

      @options = {}
      config = File.expand_path('~/.config/mdless/config.yml')
      @options = YAML.load(IO.read(config)) if File.exist?(config)

      optparse = OptionParser.new do |opts|
        opts.banner = "#{version} by Brett Terpstra\n\n> Usage: #{CLIMarkdown::EXECUTABLE_NAME} [options] [path]\n\n"

        default(:color, true)
        opts.on('-c', '--[no-]color', 'Colorize output (default on)') do |c|
          @options[:color] = c
        end

        opts.on('-d', '--debug LEVEL', 'Level of debug messages to output (1-4, 4 to see all messages)') do |level|
          if level.to_i.positive? && level.to_i < 5
            @log.level = 5 - level.to_i
          else
            puts 'Error: Debug level out of range (1-4)'
            Process.exit 1
          end
        end

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end

        default(:local_images, false)
        default(:remote_images, false)
        opts.on('-i', '--images=TYPE',
                'Include [local|remote (both)|none] images in output (requires chafa or imgcat, default none).') do |type|
          if exec_available('imgcat') || exec_available('chafa')
            case type
            when /^(r|b|a)/i
              @options[:local_images] = true
              @options[:remote_images] = true
            when /^l/i
              @options[:local_images] = true
            when /^n/
              @options[:local_images] = false
              @options[:remote_images] = false
            end
          else
            @log.warn('images turned on but imgcat/chafa not found')
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


        default(:list, false)
        opts.on('-l', '--list', 'List headers in document and exit') do
          @options[:list] = true
        end

        default(:pager, true)
        opts.on('-p', '--[no-]pager', 'Formatted output to pager (default on)') do |p|
          @options[:pager] = p
        end

        default(:pager, true)
        opts.on('-P', 'Disable pager (same as --no-pager)') do
          @options[:pager] = false
        end

        default(:section, nil)
        opts.on('-s', '--section=NUMBER[,NUMBER]',
                'Output only a headline-based section of the input (numeric from --list)') do |section|
          @options[:section] = section.split(/ *, */).map(&:strip).map(&:to_i)
        end

        default(:theme, 'default')
        opts.on('-t', '--theme=THEME_NAME', 'Specify an alternate color theme to load') do |theme|
          @options[:theme] = theme
        end

        default(:at_tags, false)
        opts.on('-@', '--at_tags', 'Highlight @tags and values in the document') do
          @options[:at_tags] = true
        end

        opts.on('-v', '--version', 'Display version number') do
          puts version
          exit
        end

        default(:width, TTY::Screen.cols)
        opts.on('-w', '--width=COLUMNS', 'Column width to format for (default: terminal width)') do |columns|
          @options[:width] = columns.to_i
        end
        cols = TTY::Screen.cols
        @options[:width] = cols if @options[:width] > cols

        default(:autolink, true)
        opts.on('--[no-]autolink', 'Convert bare URLs and emails to <links>') do |p|
          @options[:autolink] = p
        end

        default(:inline_footnotes, false)
        opts.on('--[no-]inline_footnotes',
                'Display footnotes immediately after the paragraph that references them') do |p|
          @options[:inline_footnotes] = p
        end

        default(:intra_emphasis, true)
        opts.on('--[no-]intra-emphasis', 'Parse emphasis inside of words (e.g. Mark_down_)') do |opt|
          @options[:intra_emphasis] = opt
        end

        default(:lax_spacing, true)
        opts.on('--[no-]lax-spacing', 'Allow lax spacing') do |opt|
          @options[:lax_spacing] = opt
        end

        default(:links, :inline)
        opts.on('--links=FORMAT',
                'Link style ([inline, reference, paragraph], default inline,
                "paragraph" will position reference links after each paragraph)') do |fmt|
          @options[:links] = case fmt
                             when /^:?r/i
                               :reference
                             when /^:?p/i
                               :paragraph
                             else
                               :inline
                             end
        end

        default(:syntax_higlight, false)
        opts.on('--[no-]syntax', 'Syntax highlight code blocks') do |p|
          @options[:syntax_higlight] = p
        end

        @options[:taskpaper] = if @options[:taskpaper]
                                 case @options[:taskpaper].to_s
                                 when /^[ty1]/
                                   true
                                 when /^a/
                                   :auto
                                 else
                                   false
                                 end
                               else
                                 false
                               end
        opts.on('--taskpaper=OPTION', 'Highlight TaskPaper format (true|false|auto)') do |tp|
          @options[:taskpaper] = case tp
                                 when /^[ty1]/
                                   true
                                 when /^a/
                                   :auto
                                 else
                                   false
                                 end
        end

        default(:update_config, false)
        opts.on('--update_config', 'Update the configuration file with new keys and current command line options') do
          @options[:update_config] = true
        end

        default(:wiki_links, false)
        opts.on('--[no-]wiki-links', 'Highlight [[wiki links]]') do |opt|
          @options[:wiki_links] = opt
        end
      end

      begin
        optparse.parse!
      rescue OptionParser::ParseError => e
        warn "error: #{e.message}"
        exit 1
      end

      if !File.exist?(config) || @options[:update_config]
        FileUtils.mkdir_p(File.dirname(config))
        File.open(config, 'w') do |f|
          opts = @options.dup
          opts.delete(:list)
          opts.delete(:section)
          opts.delete(:update_config)
          f.puts YAML.dump(opts)
          warn "Config file saved to #{config}"
        end
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
      renderer.options = @options

      markdown = Redcarpet::Markdown.new(renderer,
                                         no_intra_emphasis: !@options[:intra_emphasis],
                                         autolink: @options[:autolink],
                                         fenced_code_blocks: true,
                                         footnotes: true,
                                         hard_wrap: false,
                                         highlight: true,
                                         lax_spacing: @options[:lax_spacing],
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
          renderer.file = @file
          begin
            input = IO.read(file).force_encoding('utf-8')
          rescue StandardError
            input = IO.read(file)
          end
          raise 'Nil input' if input.nil?

          input.scrub!
          input.gsub!(/\r?\n/, "\n")

          if @options[:list]
            puts list_headers(input)
            Process.exit 0
          else
            if @options[:taskpaper] == :auto
              @options[:taskpaper] = if file =~ /\.taskpaper/
                                       @log.info('TaskPaper extension detected')
                                       true
                                     elsif CLIMarkdown::TaskPaper.is_taskpaper?(input)
                                       @log.info('TaskPaper document detected')
                                       true
                                     else
                                       false
                                     end
            end

            if @options[:taskpaper]
              input = CLIMarkdown::TaskPaper.highlight(input, @theme)
              @output = input.highlight_tags(@theme, @log)
            else
              @output = markdown.render(input)
            end
          end
        end
        printout
      elsif !$stdin.isatty
        @file = nil
        input = $stdin.read.scrub
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
        res = val.split(/ /).map(&:to_sym)
        c(res)
      else
        c([:reset])
      end
    end

    def get_headers(string)
      unless @headers && !@headers.empty?
        @headers = []
        input = string.sub(/(?i-m)^---[ \t]*\n([\s\S]*?)\n[-.]{3}[ \t]*\n/m, '')
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

    def list_headers(input)
      h_adjust = highest_header(input) - 1
      input.gsub!(/^(#+)/) do
        m = Regexp.last_match
        new_level = m[1].length - h_adjust
        new_level.positive? ? '#' * new_level : ''
      end

      @headers = get_headers(input)
      last_level = 0
      headers_out = []
      len = (@headers.count + 1).to_s.length
      @headers.each_with_index do |h, idx|
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
        headers_out.push format("%<d>#{len}d: %<s>s",
                                d: idx + 1,
                                s: "#{c(%i[x black])}#{'.' * level}#{c(%i[x yellow])}#{subdoc}#{title.strip}#{xc}")
      end

      headers_out.join("\n")
    end

    def highest_header(input)
      @headers = get_headers(input)
      top = 6
      @headers.each { |h| top = h[0].length if h[0].length < top }
      top
    end

    def clean_markers(input)
      input.gsub!(/^(\e\[[\d;]+m)?[%~] ?/, '\1')
      input.gsub!(/^(\e\[[\d;]+m)*>(\e\[[\d;]+m)?( +)/, ' \3\1\2')
      input.gsub!(/^(\e\[[\d;]+m)*>(\e\[[\d;]+m)?/, '\1\2')
      input.gsub!(/(\e\[[\d;]+m)?@@@(\e\[[\d;]+m)?$/, '')
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

    def find_color(line, nullable: false)
      return line if line.nil?

      colors = line.scan(/\e\[[\d;]+m/)
      if colors.size&.positive?
        colors[-1]
      else
        nullable ? nil : xc
      end
    end

    def pad_max(block, eol='')
      block.split(/\n/).map do |l|
        new_code_line = l.gsub(/\t/, '    ')
        orig_length = new_code_line.size + 8 + eol.size
        pad_count = [@cols - orig_length, 0].max

        [
          new_code_line,
          eol,
          ' ' * [pad_count - 1, 0].max
        ].join
      end.join("\n")
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

    def printout
      out = @output.rstrip.split(/\n/).map do |p|
        p.wrap(@cols, color('text'))
      end.join("\n")

      unless out.size&.positive?
        @log.warn 'No results'
        Process.exit
      end

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
