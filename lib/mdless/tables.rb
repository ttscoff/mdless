module CLIMarkdown
  class MDTableCleanup
    PAD_CHAR = "\u00A0"

    def initialize(input)
      @string = input
    end

    def parse
      @format_row = []
      @table = []
      fmt = []
      cols = 0
      rows = @string.split(/\r?\n/)
      rows.each do |row|
        row.strip!
        row.sub!(/^\s*\|?/,'').sub!(/\|?\s*$/,'')
        row_array = row.split(/\|/)
        row_array.map! { |cell| cell.strip }
        if row =~ /^[\|:\- ]+$/
          fmt = row_array
        else
          @table.push row_array
        end
        cols = row_array.length if row_array.length > cols
      end

      fmt.each_with_index do |cell, i|
        cell.strip!
        f = case cell
        when /^:.*?:$/
          :center
        when /[^:]+:$/
          :right
        else
          :just
        end
        @format_row.push(f)
      end

      if @format_row.length < cols
        (cols - @format_row.length).times do
          @format_row.push(:left)
        end
      end

      @table.map! do |row|
        if row.length < cols
          (cols - row.length).times do
            row.push("")
          end
        end
        row
      end
      @table
    end

    def table
      @table ||= parse
    end

    def column_width(idx)
      @widths ||= column_widths
      @widths[idx]
    end

    def column_widths
      @widths = []
      @format_row.length.times do
        @widths.push(0)
      end

      table.each do |row|
        @format_row.each_with_index do |_, i|
          length = row[i].uncolor.remove_pre_post.strip.length
          @widths[i] = length if length > @widths[i]
        end
      end

      @widths
    end

    def pad(string, alignment, length)
      case alignment
      when :center
        string.strip.center(length, PAD_CHAR)
      when :right
        string.strip.rjust(length, PAD_CHAR)
      when :left
        string.strip.ljust(length, PAD_CHAR)
      else
        string.strip.ljust(length, PAD_CHAR)
      end
    end

    def separator(length, alignment)
      out = ''.ljust(length, '-')
      case alignment
      when :left
        ":#{out}-"
      when :right
        "-#{out}:"
      when :center
        ":#{out}:"
      else
        "-#{out}-"
      end
    end

    def header_separator_row
      output = []
      @format_row.each_with_index do |column, i|
        output.push separator(column_width(i), column)
      end
      "|#{output.join('|')}|"
    end

    def table_border
      output = []
      @format_row.each_with_index do |column, i|
        output.push separator(column_width(i), column)
      end
      "+#{output.join('+').gsub(/:/,'-')}+"
    end

    def to_md
      output = []
      t = table.clone
      t.each do |row|
        new_row = row.map.with_index { |cell, i| pad(cell, @format_row[i], column_width(i)) }.join(' | ')
        output.push("| #{new_row} |")
      end
      output.insert(1, header_separator_row)
      output.insert(0, table_border)
      output.push(table_border)
      output.join("\n")
    end
  end
end
