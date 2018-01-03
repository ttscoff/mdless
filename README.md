
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
- Syntax highlighting when `pygmentize` is available
- List headlines in document
- Display single section of the document based on headlines

## Installation

    gem install mdless

## Usage 

`mdless [options] path` or `cat [path] | mdless`

The pager used is determined by system configuration in this order of preference:

* `$GIT_PAGER`
* `$PAGER`
* `git config --get-all core.pager`
* `less`
* `more`
* `cat`
* `pager`

### Options

    -s, --section=TITLE              Output only a headline-based section of 
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



