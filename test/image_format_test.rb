require 'test_helper'
require 'mdless'

class ImageFormatTest < Test::Unit::TestCase
  KEYS = %w[KITTY_PID TERM TERM_PROGRAM TERMINAL_PROGRAM].freeze

  def setup
    @saved = KEYS.to_h { |k| [k, ENV[k]] }
    KEYS.each { |k| ENV.delete(k) }
    @renderer = Redcarpet::Render::Console.new
  end

  def teardown
    KEYS.each { |k| @saved[k].nil? ? ENV.delete(k) : ENV[k] = @saved[k] }
  end

  def format_for(env = {})
    env.each { |k, v| ENV[k] = v }
    @renderer.send(:chafa_format)
  end

  def test_kitty_detected_by_term
    assert_equal '-f kitty', format_for('TERM' => 'xterm-kitty')
  end

  def test_kitty_detected_by_kitty_pid
    assert_equal '-f kitty', format_for('KITTY_PID' => '1234', 'TERM' => 'xterm-256color')
  end

  def test_kitty_detected_even_with_unrelated_term_program
    assert_equal '-f kitty', format_for('TERM' => 'xterm-kitty', 'TERM_PROGRAM' => 'Apple_Terminal')
  end

  def test_iterm_detected_by_term_program
    assert_equal '-f iterm', format_for('TERM_PROGRAM' => 'iTerm.app')
  end

  def test_unknown_terminal_falls_back_to_sixels
    assert_equal '-f sixels', format_for('TERM' => 'xterm-256color', 'TERM_PROGRAM' => 'Apple_Terminal')
  end

  def test_no_env_falls_back_to_sixels
    assert_equal '-f sixels', format_for
  end
end
