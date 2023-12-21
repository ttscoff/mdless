require 'fileutils'
require 'yaml'

module CLIMarkdown
  class Converter
    include Colors

    def version
      "#{CLIMarkdown::EXECUTABLE_NAME} #{CLIMarkdown::VERSION}"
    end

    def default(option, default)
      MDLess.options[option] = default if MDLess.options[option].nil?
    end

    def initialize(args)
      MDLess.log.level = Logger::WARN

      MDLess.options = {}
      config = File.expand_path('~/.config/mdless/config.yml')
      MDLess.options = YAML.load(IO.read(config)) if File.exist?(config)

      optparse = OptionParser.new do |opts|
        opts.banner = "#{version} by Brett Terpstra\n\n> Usage: #{CLIMarkdown::EXECUTABLE_NAME} [options] [path]\n\n"

        default(:color, true)
        opts.on('-c', '--[no-]color', 'Colorize output (default on)') do |c|
          MDLess.options[:color] = c
        end

        opts.on('-d', '--debug LEVEL', 'Level of debug messages to output (1-4, 4 to see all messages)') do |level|
          if level.to_i.positive? && level.to_i < 5
            MDLess.log.level = 5 - level.to_i
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
                'Include [local|remote (both)|none] images in output'\
                ' (requires chafa or imgcat, default none).') do |type|
          if exec_available('imgcat') || exec_available('chafa')
            case type
            when /^(r|b|a)/i
              MDLess.options[:local_images] = true
              MDLess.options[:remote_images] = true
            when /^l/i
              MDLess.options[:local_images] = true
            when /^n/
              MDLess.options[:local_images] = false
              MDLess.options[:remote_images] = false
            end
          else
            MDLess.log.warn('images turned on but imgcat/chafa not found')
          end
        end

        opts.on('-I', '--all-images', 'Include local and remote images in output'\
               ' (requires imgcat or chafa)') do
          if exec_available('imgcat') || exec_available('chafa') # && ENV['TERM_PROGRAM'] == 'iTerm.app'
            MDLess.options[:local_images] = true
            MDLess.options[:remote_images] = true
          else
            MDLess.log.warn('images turned on but imgcat/chafa not found')
          end
        end

        default(:list, false)
        opts.on('-l', '--list', 'List headers in document and exit') do
          MDLess.options[:list] = true
        end

        default(:pager, true)
        opts.on('-p', '--[no-]pager', 'Formatted output to pager (default on)') do |p|
          MDLess.options[:pager] = p
        end

        default(:pager, true)
        opts.on('-P', 'Disable pager (same as --no-pager)') do
          MDLess.options[:pager] = false
        end

        default(:section, nil)
        opts.on('-s', '--section=NUMBER[,NUMBER]',
                'Output only a headline-based section of the input (numeric from --list or text match)') do |section|
          sections = section.split(/ *, */).map(&:strip)
          MDLess.options[:section] = sections.map do |sect|
            if sect =~ /^\d+$/
              sect.to_i
            else
              sect
            end
          end
        end

        default(:theme, 'default')
        opts.on('-t', '--theme=THEME_NAME', 'Specify an alternate color theme to load') do |theme|
          MDLess.options[:theme] = theme
        end

        default(:at_tags, false)
        opts.on('-@', '--[no-]at-tags', 'Highlight @tags and values in the document') do |opt|
          MDLess.options[:at_tags] = opt
        end

        opts.on('-v', '--version', 'Display version number') do
          puts version
          exit
        end

        default(:width, 0)
        opts.on('-w', '--width=COLUMNS', 'Column width to format for (default: 0 -> terminal width)') do |columns|
          columns = columns.to_i
          cols = TTY::Screen.cols
          MDLess.cols = columns > 2 ? columns - 2 : cols

          MDLess.options[:width] = columns > cols ? cols - 2 : columns - 2
        end

        MDLess.cols = MDLess.options[:width]
        MDLess.cols = TTY::Screen.cols - 2 if MDLess.cols.zero?

        default(:autolink, true)
        opts.on('--[no-]autolink', 'Convert bare URLs and emails to <links>') do |p|
          MDLess.options[:autolink] = p
        end

        opts.on('--config', "Open the config file in default editor") do
          raise 'No $EDITOR defined' unless ENV['EDITOR']

          `#{ENV['EDITOR']} '#{File.expand_path('~/.config/mdless/config.yml')}'`
        end

        opts.on('--changes', 'Open the changelog to see recent updates') do
          changelog = File.join(File.dirname(__FILE__), '..', '..', 'CHANGELOG.md')
          system "mdless --linebreaks '#{changelog}'"
          Process.exit 0
        end

        opts.on('--edit-theme', 'Open the default/specified theme in default editor, '\
                                'populating a new theme if needed. Use after --theme in the command.') do
          raise 'No $EDITOR defined' unless ENV['EDITOR']

          theme = MDLess.options[:theme] =~ /default/ ? 'mdless' : MDLess.options[:theme]
          theme = File.expand_path("~/.config/mdless/#{theme}.theme")
          File.open(theme, 'w') { |f| f.puts(YAML.dump(MDLess.theme)) } unless File.exist?(theme)
          `#{ENV['EDITOR']} '#{theme}'`
          Process.exit 0
        end

        default(:inline_footnotes, false)
        opts.on('--[no-]inline-footnotes',
                'Display footnotes immediately after the paragraph that references them') do |p|
          MDLess.options[:inline_footnotes] = p
        end

        default(:intra_emphasis, true)
        opts.on('--[no-]intra-emphasis', 'Parse emphasis inside of words (e.g. Mark_down_)') do |opt|
          MDLess.options[:intra_emphasis] = opt
        end

        default(:lax_spacing, true)
        opts.on('--[no-]lax-spacing', 'Allow lax spacing') do |opt|
          MDLess.options[:lax_spacing] = opt
        end

        default(:links, :inline)
        opts.on('--links=FORMAT',
                'Link style ([*inline, reference, paragraph],'\
                ' "paragraph" will position reference links after each paragraph)') do |fmt|
          MDLess.options[:links] = case fmt
                             when /^:?r/i
                               :reference
                             when /^:?p/i
                               :paragraph
                             else
                               :inline
                             end
        end

        default(:preserve_linebreaks, true)
        opts.on('--[no-]linebreaks', 'Preserve line breaks') do |opt|
          MDLess.options[:preserve_linebreaks] = opt
        end

        default(:mmd_metadata, true)
        opts.on('--[no-]metadata', 'Replace [%key] with values from metadata') do |opt|
          MDLess.options[:mmd_metadata] = opt
        end

        default(:syntax_higlight, false)
        opts.on('--[no-]syntax', 'Syntax highlight code blocks') do |opt|
          MDLess.options[:syntax_higlight] = opt
        end

        MDLess.options[:taskpaper] = if MDLess.options[:taskpaper]
                                       case MDLess.options[:taskpaper].to_s
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
          MDLess.options[:taskpaper] = case tp
                                       when /^[ty1]/
                                         true
                                       when /^a/
                                         :auto
                                       else
                                         false
                                       end
        end

        default(:transclude, true)
        opts.on('--[no-]transclude', 'Transclude documents with {{filename}} syntax') do |opt|
          MDLess.options[:transclude] = opt
        end

        default(:update_config, false)
        opts.on('--update-config', '--update_config',
                'Update the configuration file with new keys and current command line options') do
          MDLess.options[:update_config] = true
        end

        default(:update_theme, false)
        opts.on('--update-theme', 'Update the current theme file with all available keys') do
          MDLess.options[:update_theme] = true
        end

        default(:wiki_links, false)
        opts.on('--[no-]wiki-links', 'Highlight [[wiki links]]') do |opt|
          MDLess.options[:wiki_links] = opt
        end
      end

      begin
        optparse.parse!
      rescue OptionParser::ParseError => e
        warn "error: #{e.message}"
        exit 1
      end

      if MDLess.options[:update_theme]
        FileUtils.mkdir_p(File.dirname(config))

        theme = MDLess.options[:theme] =~ /default/ ? 'mdless' : MDLess.options[:theme]
        theme = File.join(File.dirname(config), "#{theme}.theme")
        contents = YAML.dump(MDLess.theme)

        File.open(theme, 'w') { |f| f.puts contents }
        Process.exit 0
      end

      if !File.exist?(config) || MDLess.options[:update_config]
        FileUtils.mkdir_p(File.dirname(config))
        File.open(config, 'w') do |f|
          opts = MDLess.options.dup
          opts.delete(:list)
          opts.delete(:section)
          opts.delete(:update_config)
          opts.delete(:update_theme)
          opts[:width] = 0
          opts = opts.keys.map(&:to_s).sort.map { |k| [k.to_sym, opts[k.to_sym]] }.to_h
          f.puts YAML.dump(opts)
          warn "Config file saved to #{config}"
        end
      end

      @output = ''
      @setheaders = []

      input = ''
      @ref_links = {}
      @footnotes = {}

      renderer = Redcarpet::Render::Console.new

      markdown = Redcarpet::Markdown.new(renderer,
                                         no_intra_emphasis: !MDLess.options[:intra_emphasis],
                                         autolink: MDLess.options[:autolink],
                                         fenced_code_blocks: true,
                                         footnotes: true,
                                         hard_wrap: false,
                                         highlight: true,
                                         lax_spacing: MDLess.options[:lax_spacing],
                                         quote: false,
                                         space_after_headers: false,
                                         strikethrough: true,
                                         superscript: true,
                                         tables: true,
                                         underline: false)

      if !args.empty?
        files = args.delete_if { |f| !File.exist?(f) }
        @multifile = files.count > 1
        files.each do |file|
          spinner = TTY::Spinner.new("[:spinner] Processing #{File.basename(file)}...", format: :dots_3, clear: true)
          spinner.run do |spinner|
            MDLess.log.info(%(Processing "#{file}"))
            @output << "#{c(%i[b green])}[#{c(%i[b white])}#{file}#{c(%i[b green])}]#{xc}\n\n" if @multifile
            MDLess.file = file

            begin
              input = IO.read(file).force_encoding('utf-8')
            rescue StandardError
              input = IO.read(file)
            end
            raise 'Nil input' if input.nil?

            input.scrub!
            input.gsub!(/\r?\n/, "\n")
            @headers = headers(input)
            if MDLess.options[:taskpaper] == :auto
              MDLess.options[:taskpaper] = if CLIMarkdown::TaskPaper.is_taskpaper?(input)
                                             MDLess.log.info('TaskPaper detected')
                                             true
                                           else
                                             false
                                           end
            end

            if MDLess.options[:list]
              @output << if MDLess.options[:taskpaper]
                           CLIMarkdown::TaskPaper.list_projects(input)
                         else
                           list_headers(input)
                         end
            elsif MDLess.options[:taskpaper]
              input = input.color_meta(MDLess.cols)
              input = CLIMarkdown::TaskPaper.highlight(input)
              @output << input.highlight_tags
            else
              @output << markdown.render(input)
            end
            @output << "\n\n"
          end
        end

        printout
      elsif !$stdin.isatty
        MDLess.log.info(%(Processing STDIN))
        spinner = TTY::Spinner.new("[:spinner] Processing ...", format: :dots_3, clear: true)
        spinner.run do |spinner|
          MDLess.file = nil
          input = $stdin.read.scrub
          input.gsub!(/\r?\n/, "\n")

          if MDLess.options[:taskpaper] == :auto
            MDLess.options[:taskpaper] = if CLIMarkdown::TaskPaper.is_taskpaper?(input)
                                           MDLess.log.info('TaskPaper detected')
                                           true
                                         else
                                           false
                                         end
          end
          @headers = headers(input)

          if MDLess.options[:list]
            if MDLess.options[:taskpaper]
              puts CLIMarkdown::TaskPaper.list_projects(input)
            else
              puts list_headers(input)
            end
            Process.exit 0
          else
            if MDLess.options[:taskpaper]
              input = input.color_meta(MDLess.cols)
              input = CLIMarkdown::TaskPaper.highlight(input)
              @output = input.highlight_tags
            else
              @output = markdown.render(input)
            end
          end
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

    def headers(string)
      hs = []
      input = string.remove_meta
      doc_headers = input.scan(/^((?!#!)(\#{1,6})\s*([^#]+?)(?: #+)?\s*|(\S.+)\n([=-]+))$/i)

      doc_headers.each do |h|
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
        hs << [
          '#' * hlevel,
          title,
          h[0]
        ]
      end

      hs
    end

    def list_headers(input)
      h_adjust = highest_header(input) - 1
      input.gsub!(/^(#+)/) do
        m = Regexp.last_match
        new_level = m[1].length - h_adjust
        new_level.positive? ? '#' * new_level : ''
      end

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
        headers_out.push format("%<c>s%<d>#{len}d: %<s>s",
                                c: c(%i[magenta]),
                                d: idx + 1,
                                s: "#{c(%i[x black])}#{'.' * level}#{c(%i[x yellow])}#{subdoc}#{title.strip}#{xc}")
      end

      headers_out.join("\n#{xc}")
    end

    def highest_header(input)
      top = 6
      @headers.each { |h| top = h[0].length if h[0].length < top }
      top
    end

    def clean_markers(input)
      input.gsub!(/^(\e\[[\d;]+m)?[%~] ?/, '\1')
      # input.gsub!(/^(\e\[[\d;]+m)*>(\e\[[\d;]+m)?( +)/, ' \3\1\2')
      # input.gsub!(/^(\e\[[\d;]+m)*>(\e\[[\d;]+m)?/, '\1\2')
      input.gsub!(/(\e\[[\d;]+m)?@@@(\e\[[\d;]+m)?$/, '')
      input
    end

    def clean_escapes(input)
      out = input.gsub(/\e\[m/, '')
      last_escape = ''
      out.gsub!(/\e\[(?:(?:(?:[349]|10)[0-9]|[0-9])?;?)+m/) do |m|
        if m == last_escape
          ''
        else
          last_escape = m
          m
        end
      end
      out.gsub(/\e\[0m/, '')
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
        pad_count = [MDLess.cols - orig_length, 0].max

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
        MDLess.log.info("Using `#{pager.join(' ')}` as pager")
        begin
          exec(pager.join(' '))
        rescue SystemCallError => e
          MDLess.log.error(e)
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
      out = @output

      # out = if MDLess.options[:taskpaper]
      #         @output
      #       else
      #         # TODO: Figure out a word wrap that accounts for indentation
      #         @output
      #         # out = @output.rstrip.split(/\n/).map do |p|
      #         #   p.wrap(MDLess.cols, color('text'))
      #         # end.join("\n")
      #       end

      unless out.size&.positive?
        MDLess.log.warn 'No results'
        Process.exit
      end

      out = clean_markers(out)
      out = clean_escapes(out)
      out = "#{out.gsub(/\n{2,}/m, "\n\n")}#{xc}"

      out.uncolor! unless MDLess.options[:color]

      if MDLess.options[:pager]
        page(out)
      else
        $stdout.print out.rstrip
      end
    end

    def which_pager
      # pagers = [ENV['PAGER'], ENV['GIT_PAGER']]
      pagers = ENV['PAGER'] ? [ENV['PAGER']] : []

      # if exec_available('git')
      #   git_pager = `git config --get-all core.pager || true`.split.first
      #   git_pager && pagers.push(git_pager)
      # end

      pagers.concat(['less', 'more', 'cat', 'pager'])

      pagers.delete_if { |pg| !TTY::Which.exist?(pg) }

      pagers.select! do |f|
        pg = f.split(/[ ]/)[0]
        return false unless pg

        if pg == 'most'
          MDLess.log.warn('most not allowed as pager')
          false
        else
          TTY::Which.which(pg)
        end
      end

      pg = pagers.first
      args = case pg
             # when 'delta'
             #   ' --pager="less -FXr"'
             when 'less'
               '-FXr'
             # when 'bat'
             #   ' -p --pager="less -FXr"'
             else
               ''
             end

      [pg, args]
    end

    def exec_available(cli)
      if TTY::Which.exist?(cli)
        TTY::Which.which(cli)
      else
        false
      end
    end
  end
end
