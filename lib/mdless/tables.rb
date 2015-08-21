module CLIMarkdown
  class MDTableCleanup

    def initialize(input)
      @string = input
      @format_row = []
    end

    def parse
      @table = []
      format = []
      cols = 0
      rows = @string.split(/\r?\n/)
      rows.each do |row|
        row.strip!
        row.sub!(/^\s*\|?/,'').sub!(/\|?\s*$/,'')
        row_array = row.split(/\|/)
        row_array.map! { |cell| cell.strip }
        if row =~ /^[\|:\- ]+$/
          format = row_array
        else
          @table.push row_array
        end
        cols = row_array.length if row_array.length > cols
      end

      format.each_with_index {|cell, i|
        f = 'left'
        if cell =~ /^:.*?:$/
          f = 'center'
        elsif cell =~ /:$/
          f = 'right'
        else
          f = 'just'
        end
        @format_row.push(f)
      }

      if @format_row.length < cols
        (cols - @format_row.length).times do
          @format_row.push('left')
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

    def column_width(i)
      @widths ||= column_widths
      @widths[i]
    end

    def column_widths
      @widths = []
      @format_row.length.times do
        @widths.push(0)
      end

      table.each do |row|
        @format_row.each_with_index do |cell, i|
          length = row[i].strip.length
          @widths[i] = length if length > @widths[i]
        end
      end

      @widths
    end

    def pad(string,type,length)
      string.strip!
      if type == 'center'
        string.center(length, ' ')
      elsif type == 'right'
        string.rjust(length, ' ')
      elsif type == 'left'
        string.ljust(length, ' ')
      else
        string.ljust(length, ' ')
      end
    end

    def separator(length, alignment)
      out = "".ljust(length,'-')
      case alignment
      when 'left'
        out = ':' + out + '-'
      when 'right'
        out = '-' + out + ':'
      when 'center'
        out = ":#{out}:"
      else
        out = "-#{out}-"
      end
      out
    end

    def header_separator_row
      output = []
      @format_row.each_with_index do |column, i|
        output.push separator(column_width(i), column)
      end
      "|#{output.join('|')}|"
    end

    def to_md
      output = []
      t = table.clone

      t.each_with_index do |row, index|
        row.map!.with_index { |cell, i| cell = pad(cell, @format_row[i], column_width(i)) }
        output.push("| #{row.join(' | ').lstrip} |")
      end
      output.insert(1, header_separator_row)
      output.join("\n")
    end
  end
end
