2.0.1
: Rely on Redcarpet for Markdown parsing, far more accurate with a
: Config file at ~/.config/mdless/config.yml
: Allow inlining of footnotes
: Nested list indentation

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
