# mdless

<!--README-->

`mdless` is a utility that provides a formatted and highlighted view of Markdown files in Terminal.

I often use iTerm2 in visor mode, so `qlmanage -p` is annoying. I still wanted a way to view Markdown files quickly and without cruft.

<!--GITHUB-->![mdless screenshot](screenshots/mdless.png)<!--END GITHUB-->
<!--JEKYLL{% gif /uploads/2015/08/mdless.gif %}-->

## Features

- Built in pager functionality with pipe capability, `less` replacement for Markdown files
- Format tables
- Colorize Markdown syntax for most elements
- Normalize spacing and link formatting
- Display footnotes after each paragraph
- Inline image display (local, optionally remote) (with compatible tools like imgcat or chafa)
- Syntax highlighting when [Pygments](http://pygments.org/) is installed
- List headlines in document
    - Display single section of the document based on headlines
- Customizable colors
- Add iTerm marks for h1-3 navigation when pager is disabled

## Installation

    gem install mdless

If you run into errors, try `gem install --user-install mdless`, or `sudo gem install mdless` (in that order).

### Dependencies

Some OSs are missing `tput`, which is necessary for mdless.

    apt update
    apt install ruby ncurses-utils
    gem install mdless

To render images, you need `imgcat` or `chafa` installed (`brew install chafa`).

For syntax highlighting, the `pygmentize` command must be available, part of the [Pygments](http://pygments.org/) package (`brew install pygments`).

## Usage

`mdless [options] path` or `cat [path] | mdless`

The pager used is determined by system configuration in this order of preference:

* `$PAGER`
* `less`
* `more`
* `cat`
* `pager`

### Options

    -c, --[no-]color                 Colorize output (default on)
    -d, --debug LEVEL                Level of debug messages to output (1-4, 4 to see all messages)
    -h, --help                       Display this screen
    -i, --images=TYPE                Include [local|remote (both)|none] images in output (requires chafa or imgcat, default none).
    -I, --all-images                 Include local and remote images in output (requires imgcat or chafa)
        --syntax                     Syntax highlight code blocks
        --links=FORMAT               Link style ([inline, reference, paragraph], default inline, "paragraph" will position reference links after each paragraph)
    -l, --list                       List headers in document and exit
    -p, --[no-]pager                 Formatted output to pager (default on)
    -P                               Disable pager (same as --no-pager)
    -s, --section=NUMBER[,NUMBER]    Output only a headline-based section of the input (numeric from --list)
    -t, --theme=THEME_NAME           Specify an alternate color theme to load
    -@, --at_tags                    Highlight @tags and values in the document
    -v, --version                    Display version number
    -w, --width=COLUMNS              Column width to format for (default: terminal width)
        --[no-]inline_footnotes      Display footnotes immediately after the paragraph that references them

## Configuration

The first time mdless is run, a config file will be written to `~/.config/mdless/config.yml`, based on the command line options used on the first run. Update that file to make any options permanent (config options will always be overridden by command line flags).

## Customization

On first run a default theme file will be placed in `~/.config/mdless/mdless.theme`. You can edit this file to modify the colors mdless uses when highlighting your files. You can copy this file and create multiple theme options which can be specified with the `-t NAME` option. For example, create `~/.config/mdless/brett.theme` and then call `mdless -t brett filename.md`.

Colors are limited to basic ANSI codes, with support for bold, underline, italics (if available for the terminal/font), dark and bright, and foreground and background colors.

Customizeable settings are stored in [YAML](https://yaml.org) format. A chunk of the settings file looks like this:

```yaml
h1:
  color: b intense_black on_white
  pad: d black on_white
  pad_char: "="
```

Font and color settings are set using a string of color names and modifiers. A typical string looks like `b red on_white`, which would give you a bold red font on a white background. In the YAML settings file there's no need for quotes, just put the string following the colon for the setting.

Some extra (non-color) settings are available for certain keys, e.g. `pad_char` to define the right padding character used on level 1 and 2 headlines. Note that you can change the [Pygments](http://pygments.org/) theme used for syntax highlighting with the code_block.pygments_theme setting. For a list of available styles (assuming you have Pygments installed), use `pygmentize -L styles`.

The display of characters around emphasis and code spans can be configured. By default, the surrounding character for bold is `**`, italic is `_`, and code span is \`. You can leave these keys empty to not display characters at all. For triple-emphasized text, the text will be surrounded by italic and bold characters, in that order.

```yaml
emphasis:
  bold: b
  bold_character: "**"
  italic: u i
  italic_character: ""
  bold-italic: b u i
code_span:
  marker: b white
  color: b white on_intense_black
  character: ""
```

*Note:* the ANSI escape codes are reset every time the color changes, so, for example, if you have a key that defines underlines for the url in a link, the underline will automatically be removed when it gets to a bracket. This also means that if you define a background color, you'll need to define it again on all the keys that it should affect.

Base colors:

- black
- red
- green
- yellow
- blue
- magenta
- cyan
- white

Emphasis:

- b (bold)
- d (dark)
- i (italic)
- u (underline)
- r (reverse, negative)

To modify the emphasis, use 'b' (bold), 'i' (italic), 'u' (underline), e.g. `u yellow` for underlined yellow. These can be combined, e.g. `b u red`.

Use 'r' to reverse foreground and background colors. `r white on_black` would display as `black on_white`. 'r' alone will reverse the current color set for a line.

To set a background color, use `on_[color]` with one of the 8 colors. This can be used with foreground colors in the same setting, e.g. `white on_black`.

Use 'd' (dark) to indicate the darker version of a foreground color. On macOS (and possibly other systems) you can use the brighter version of a color by prefixing with "intense", e.g. `intense_red` or `on_intense_black`.

<!--END README-->
