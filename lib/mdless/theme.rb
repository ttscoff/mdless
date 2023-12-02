module CLIMarkdown
  module Theme
    THEME_DEFAULTS = {
      'metadata' => {
        'border' => 'd blue on_black',
        'marker' => 'd black on_black',
        'color' => 'd white on_black'
      },
      'emphasis' => {
        'bold' => 'b',
        'bold_character' => '**',
        'italic' => 'u i',
        'italic_character' => '_',
        'bold-italic' => 'b u i'
      },
      'highlight' => 'b black on_yellow',
      'h1' => {
        'color' => 'b intense_black on_white',
        'pad' => 'd black on_white',
        'pad_char' => '='
      },
      'h2' => {
        'color' => 'b white on_intense_black',
        'pad' => 'd white on_intense_black',
        'pad_char' => '-'
      },
      'h3' => {
        'color' => 'u b yellow'
      },
      'h4' => {
        'color' => 'u yellow'
      },
      'h5' => {
        'color' => 'b white'
      },
      'h6' => {
        'color' => 'b white'
      },
      'link' => {
        'brackets' => 'b black',
        'text' => 'u b blue',
        'url' => 'cyan'
      },
      'image' => {
        'bang' => 'red',
        'brackets' => 'b black',
        'title' => 'cyan',
        'url' => 'u yellow'
      },
      'list' => {
        'ul_char' => '*',
        'bullet' => 'b intense_red',
        'number' => 'b intense_blue',
        'color' => 'intense_white'
      },
      'footnote' => {
        'brackets' => 'b black on_black',
        'caret' => 'b yellow on_black',
        'title' => 'x yellow on_black',
        'note' => 'u white on_black'
      },
      'code_span' => {
        'marker' => 'b white',
        'color' => 'b white on_intense_black',
        'character' => '`'
      },
      'code_block' => {
        'marker' => 'intense_black',
        'character' => '>',
        'bg' => 'on_black',
        'color' => 'white on_black',
        'border' => 'blue',
        'title' => 'magenta',
        'eol' => 'intense_black on_black',
        'pygments_theme' => 'monokai'
      },
      'blockquote' => {
        'marker' => {
          'character' => '>',
          'color' => 'yellow'
        },
        'color' => 'b white'
      },
      'dd' => {
        'term' => 'black on_white',
        'marker' => 'd red',
        'color' => 'b white'
      },
      'hr' => {
        'color' => 'd white'
      },
      'table' => {
        'border' => 'd black',
        'header' => 'yellow',
        'divider' => 'b black',
        'color' => 'white',
        'bg' => 'on_black'
      },
      'html' => {
        'brackets' => 'd yellow on_black',
        'color' => 'yellow on_black'
      },
      'math' => {
        'brackets' => 'b black',
        'equation' => 'b blue'
      },
      'super' => 'b green',
      'text' => 'white',
      'at_tags' => {
        'tag' => 'magenta',
        'value' => 'b white'
      },
      'taskpaper' => {
        'marker' => 'b white',
        'project' => 'b green',
        'task' => 'white',
        'note' => 'd white'
      }
    }

    def load_theme_file(theme_file)
      raise "Theme #{theme_file} doesn't exist" unless File.exist?(theme_file)

      begin
        theme_contents = IO.read(theme_file)
        new_theme = YAML.load(theme_contents)
        theme = THEME_DEFAULTS.deep_merge(new_theme)
        # # write merged theme back in case there are new keys since
        # # last updated
        # File.open(theme_file,'w') {|f|
        #   f.puts theme.to_yaml
        # }
      rescue StandardError => e
        @log.warn('Error merging user theme')
        warn e
        warn e.backtrace
        theme = THEME_DEFAULTS
        if File.basename(theme_file) =~ /mdless\.theme/
          FileUtils.rm(theme_file)
          @log.info("Rewriting default theme file to #{theme_file}")
          File.open(theme_file, 'w') { |f| f.puts theme.to_yaml }
        end
      end
      theme
    end

    def load_theme(theme)
      config_dir = File.expand_path('~/.config/mdless')
      default_theme_file = File.join(config_dir, 'mdless.theme')
      if theme =~ /default/i || !theme
        theme_file = default_theme_file
      else
        theme = theme.strip.sub(/(\.theme)?$/, '.theme')
        theme_file = File.join(config_dir, theme)
      end

      unless File.directory?(config_dir)
        @log.info("Creating config directory at #{config_dir}")
        FileUtils.mkdir_p(config_dir)
      end

      unless File.exist?(theme_file)
        if File.exist?(default_theme_file)
          @log.info('Specified theme not found, using default')
          theme_file = default_theme_file
        else
          theme = THEME_DEFAULTS
          @log.info("Writing fresh theme file to #{theme_file}")
          File.open(theme_file, 'w') { |f| f.puts theme.to_yaml }
        end
      end

      load_theme_file(theme_file)
    end
  end
end
