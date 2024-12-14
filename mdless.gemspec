# Ensure we require the local version and not one we might have installed already
require './lib/mdless/version.rb'
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
  s.files = Dir['lib/**/*.rb'] + Dir['bin/*']
  s.files << 'CHANGELOG.md'
  s.files << 'README.md'
  s.require_paths << 'lib'
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options << '--title' << 'mdless' << '--main' << 'README.md' << '--markup' << 'markdown' << '-ri'
  s.bindir = 'bin'
  s.executables << 'mdless'
  s.add_dependency 'redcarpet', '~> 3.6'
  s.add_dependency 'rouge', '~> 4.2'
  s.add_dependency 'tty-screen', '~> 0.8'
  s.add_dependency 'tty-spinner', '~> 0.8'
  s.add_dependency 'tty-which', '~> 0.5'
  s.add_development_dependency 'rake', '~> 13'
  s.add_development_dependency 'rdoc', '>= 6.6.2'
  s.add_development_dependency 'rubocop', '~> 0.49'
end
