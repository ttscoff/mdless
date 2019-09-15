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
          'italic' => 'u i',
          'bold-italic' => 'b u i'
        },
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
          'color' => 'b black on_intense_blue'
        },
        'code_block' => {
          'marker' => 'intense_black',
          'bg' => 'on_black',
          'color' => 'white on_black',
          'border' => 'blue',
          'title' => 'magenta',
          'eol' => 'intense_black on_black',
          'pygments_theme' => 'monokai'
        },
        'dd' => {
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
          'color' => 'white'
        },
        'html' => {
          'brackets' => 'd yellow on_black',
          'color' => 'yellow on_black'
        }
      }
    def load_theme
      config_dir = File.expand_path('~/.config/mdless')
      theme_file = File.join(config_dir,'mdless.theme')

      unless File.directory?(config_dir)
        @log.info("Creating config directory at #{config_dir}")
        FileUtils.mkdir_p(config_dir)
      end

      unless File.exists?(theme_file)
        @log.info("Writing fresh theme file to #{theme_file}")
        File.open(theme_file,'w') {|f|
          f.puts theme.to_yaml
        }
        theme = THEME_DEFAULTS
      else
        new_theme = YAML.load(IO.read(theme_file))
        begin
          theme = THEME_DEFAULTS.deep_merge(new_theme)
          # write merged theme back in case there are new keys since
          # last updated
          File.open(theme_file,'w') {|f|
            f.puts theme.to_yaml
          }
        rescue
          @log.warn('Error merging user theme')
          theme = THEME_DEFAULTS
        end
      end

      theme
    end
  end
end
