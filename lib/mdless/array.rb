# frozen_string_literal: true

class ::Array
  def longest_element
    return self if nil? || empty?

    group_by(&:size).max.last[0]
  end

  def longest_elements
    return [] if nil? || empty?

    group_by(&:size).max.last
  end
end
