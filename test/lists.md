transclude base: test/transclude
title: Lists with transclude

{{Marked2.6.311054-releasenotes.md}}

# [%title]

1. delete line feeds (\u2028)
2. Trim content to first line (up to \r\n)
3. read into array
4. delete elements ==without== tags keys
5. modify content values
    - remove colons, pipes and _slashes_
    - truncate to 40 chars to create title
6. If content value + ".txt" exists, apply OS tags and/or insert metadata line (shouldn't need to respect any existing metadata)
    
    This contains a paragraph

    Maybe two
7. This contains
    1. ordered list
    2. items
      1. Further nested

        ```ruby
        def code_block
            puts "hello world"
        end

        def second
            puts "goodbye world"
        end
        ```
      2. And again
8. End of list

---

1. This should
2. start a new
3. list
