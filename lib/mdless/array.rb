# frozen_string_literal: true

class ::Array
  def longest_element
    group_by(&:size).max.last[0]
  end

  def longest_elements
    group_by(&:size).max.last
  end
end
