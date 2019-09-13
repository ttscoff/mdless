
# mdless

`mdless` is a utility that provides a formatted and highlighted view of Markdown files in Terminal.

I often use iTerm2 in visor mode, so `qlmanage -p` is annoying. I still wanted a way to view Markdown files quickly and without cruft.

![mdless screenshot](screenshots/mdless.png)

## Features

- Built in pager functionality with pipe capability, `less` replacement for Markdown files
- Format tables
- Colorize Markdown syntax for most elements
- Normalize spacing and link formatting
- Display footnotes after each paragraph
- Inline image display (local, optionally remote) if using iTerm2 2.9+
- Syntax highlighting when [Pygments](http://pygments.org/) is installed
    - Only fenced code with a language defined (e.g. `\`\`\`python`) will be highlighted
    - Languages can also be determined by hashbang in the code block
- List headlines in document
    - Display single section of the document based on headlines
- Customizable colors

## Installation

    gem install mdless

## Usage 

`mdless [options] path` or `cat [path] | mdless`

The pager used is determined by system configuration in this order of preference:

* `$GIT_PAGER`
* `$PAGER`
* `git config --get-all core.pager`
* `bat`
* `less`
* `more`
* `cat`
* `pager`

### Options

    -s, --section=NUMBER              Output only a headline-based section of 
                                     the input (numeric based on --list output)
    -w, --width=COLUMNS              Column width to format for (default terminal width)
    -p, --[no-]pager                 Formatted output to pager (default on)
    -P                               Disable pager (same as --no-pager)
    -c, --[no-]color                 Colorize output (default on)
    -l, --list                       List headers in document and exit
    -i, --images=TYPE                Include [local|remote (both)] images in 
                                     output (requires imgcat and iTerm2, 
                                     default NONE)
    -I, --all-images                 Include local and remote images in output 
    -h, --help                       Display this screen
    -v, --version                    Display version number

## Customization

On first run a default theme file will be placed in `~/.config/mdless/mdless.theme`. You can edit this file to modify the colors mdless uses when highlighting your files.

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

