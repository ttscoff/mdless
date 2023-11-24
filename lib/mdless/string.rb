# frozen_string_literal: true

# String helpers
class ::String
  def scrub
    encode('utf-16', invalid: :replace).encode('utf-8')
  end

  def scrub!
    replace scrub
  end
end
