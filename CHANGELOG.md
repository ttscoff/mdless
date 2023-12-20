2.1.35
: Ruby 2.7 error (again)

2.1.30
: Error when $EDITOR is not defined

2.1.29
: More code cleanup, help output improvements
: Line breaks in help output
: This release should fix an error on Ruby 2.7 in string.rb

2.1.28
: Default to 0 width, which makes the width the column width of the terminal
: Don't save a --width setting to config, require that to be manually updated if desired

2.1.27
: Error handling when YAML can't be processed

2.1.25
: YAML loading issues caused by safe_load

2.1.24
: Save MultiMarkdown metadata into a hash
: Allow [%metakey] replacements
: Allow {{filename}} transcusions (MultiMarkdown), respects "transclude base:" metadata
: Transclude documents with `{{filename}}`, nesting allowed, "transclude base:" metadata respected (even in YAML)
: Metadata can be used in `[%key]` format to have it replaced in the output based on metadata values

2.1.23
: Fix release pipeline to get version number correct in git release
: Changelog mismatch

2.1.22
: TaskPaper file with metadata causing negative argument error
: Remove `<br>` from metadata
: YAML metadata and negative line lengths
>>>>>>> release/2.1.30

2.1.14
: Spaces on a line separating metadata won't break display
: Preserve line breaks in metadata
: Failure to display metadata fixed

2.1.13
: Remove debugging statement

2.1.12
: Fix list indentation when nesting

2.1.11
: Better regex for highlighting raw HTML
: Indentation in highlighted code blocks
: HTML Tag highlighting breaking pre/post color conversion

2.1.10
: Spinner while processing to indicate working
: Image links can now be converted to reference format, with correct coloring
: Render image links before reference link conversion

2.1.9
: Code block prefix configurable, can be left empty to make more copyable code blocks
: Remove empty lines from block quotes
: Infinite loop when calculating ANSI emphasis
: Don't accept colors or semicolons inside of @tag names

2.1.8
: --update-theme option to add any missing keys to your theme file
: Strip ul_char of any spaces before inserting

2.1.7
: Dedup and remove empty escape codes before output
: Tables losing column alignment
: Unneccessarily long table cells

2.1.6
: In addition to color names, you can now use 3 or 6-digit hex codes, prefix with "bg" or "on_" to affect background color
: Better highlighting of h1/h2 when header contains a link
: List items with multiple paragraphs incorrectly highlighted

2.1.3
: Respect :width setting in config

2.0.24
: Update readme with config descriptions
: Code blocks containing YAML with `---` as the first line were being interpreted as Setext headers
: Line breaks being consumed when matching tags for highlighting

2.0.21
: When converting to reference links, catch links that have been wrapped

2.0.20
: Subsequent tables inheriting first table's column count

2.0.19
: `--section` can take string arguments to be fuzzy matched against headlines
: Code refactoring
: TaskPaper formatting now responds to --section with string matches
: TaskPaper formatting now responds to --list to list projects
: TaskPaper auto detection double checks content by removing all projects and tasks and seeing if there's anything left before deciding it's not TaskPaper content
: Extra line break before headers
: Wrap block quotes to max width
: Missing first headline in output
: Long links that were wrapped were not being replaced when converting to reference links

2.0.18
: Better handling of default options set in config
: More expansive detection of screen width, no longer just dependent on `tput` being available
: Only extend borders and backgrounds on code blocks to the length of the longest line
: Include the language in the top border of code blocks, if available
: Validate themes and lexers using `pygmentize` output, with fallbacks
: If width specified in config is greater than display columns, fall back to display columns as max width
: Metadata (MMD/YAML) handling on TaskPaper files

2.0.17
: Re-order command line options for more readable help output (`mdless -h`)

2.0.15
: Highlight [[wiki links]]
: TaskPaper rendering refinements
: Handle TaskPaper tasks without project if --taskpaper is enabled
: Wiki link highlighting is optional with `--[no-]wiki-links` and can be set in config
: Nil error on short files
: Project regex matching `- PROJECT NAME:`
: If taskpaper is true, avoid all parsing other than tasks, projects, notes, and tags

2.0.8
: Image rendering with chafa improved, still have to figure out a way to make sure content breaks around the embedded image
: Only detect mmd headers on first line

2.0.7
: Render links as reference links at the end of the file (`--links ref`) or per-paragraph (`--links para`). Defaults to inline (`--links inline`)
: Pad numbers on headline listing to preserve indentation

2.0.6
: Render links as reference links at the end of the file (`--links ref`) or per-paragraph (`--links para`). Defaults to inline (`--links inline`)
: Pad numbers on headline listing to preserve indentation

2.0.5
: Better highlighting of metadata (both YAML and MMD)

2.0.4
: False MMD metadata detection

2.0.0
: Rely on Redcarpet for Markdown parsing, far more accurate with a few losses I'll handle over time
: Config file at ~/.config/mdless/config.yml
: Allow inlining of footnotes
: Nested list indentation

1.0.37
: Comments inside of fenced code rendering as ATX headlines

1.0.35
: Improved code block parsing and handling

1.0.33
: Allow multiple sections with `-s 3,4,5`

1.0.32
: Errors in Ruby 3.2

1.0.30
: Errant pager output

1.0.29
: Allow $ markers for equations
: Don't force white foreground when resetting color (allow default terminal color to be foreground
: Reset color properly when span elements are used in list items
: Code block border wrapping
: Use template settings for all footnote highlights
: Errant pager output1.0.13
: Fix for tables being eaten at the end of a document

1.0.10
: Fix for regex characters in headlines breaking rendering

1.0.9
: Catch error when breaking pipe

1.0.8
: Improved table formatting

1.0.7
: Force rewrite of damaged themes
: Add iTerm marks to h1-3 when using iTerm and no pager, so you can navigate with <kbd>⌘⇧↑/↓</kbd>

1.0.6
: Fresh theme write was outputting `--- default` instead of a theme
: Better code span color
: If `bat` is the pager, force into `--plain` mode

1.0.5
: Stop adjusting for highest header

1.0.3
: Sort options order in `--help` output
: Allow multiple theme files, `--theme=NAME` option

1.0.2
: Handle emphasis inside of quotes and parenthesis
: Make emphasis themeable in mdless.theme
: Fix for `-I` throwing error if imgcat isn't installed
: remove backslash from escaped characters

1.0.1
: Fix for header listing justification
: Exclude horizontal rules `---` in header list

1.0.0
: Just a version bump because I think it deserves it at this point.

0.0.15
: User themeable
: Handle Setex headers
: General fixes and improvements

0.0.14
: Don't run pygments on code blocks without language specified in either the fence or a hashbang on the first line
: Fix to maintain indentation for fenced code in lists
: Remove leading ~ for code blocks
: Add background color
: Add line ending marker to make more sense of code wrapping
: lowercase code block fences
: remove "end code" marker
: Highlight with monokai theme
: Black background for all (fenced) code blocks

0.0.13
: Better language detection for code blocks
: when available, use italic font for italics and bold-italics emphasis
: new colorization for html tags
