# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','mdless','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'mdless'
  s.version = CLIMarkdown::VERSION
  s.author = 'Brett Terpstra'
  s.email = 'me@brettterpstra.com'
  s.homepage = 'http://brettterpstra.com/project/mdless/'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A pager like less, but for Markdown files'
  s.description = 'A CLI that provides a formatted and highlighted view of Markdown files in a terminal'
  s.license = 'MIT'
  s.files = %w(
bin/mdless
lib/helpers/formattables.py
lib/mdless.rb
lib/mdless/colors.rb
lib/mdless/converter.rb
lib/mdless/version.rb
  )
  s.require_paths << 'lib'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options << '--title' << 'mdless' << '--main' << 'README.md' << '--markup' << 'markdown' << '-ri'
  s.bindir = 'bin'
  s.executables << 'mdless'
  s.add_development_dependency 'rake', '~> 0'
  s.add_development_dependency 'rdoc', '~> 4.1', '>= 4.1.1'
  s.add_development_dependency 'aruba', '~> 0'
end
