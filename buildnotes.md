template: gem,git,project,git-flow
project: mdless
readme: README.md
changelog: CHANGELOG.md

# mdless

Terminal Markdown

## File Structure

- Gem structure

@run(subl -p mdless.sublime-project)

## Test

- `bundle exec bin/mdless TESTFILE`

## Deploy

- Increment lib/mdless/version.rb (`rake bump[inc|min|maj]`)
- Package gem (`rake clobber package`)
- Create git release (`git release create X.X.X`)
- `gem push pkg/mdless-X.X.X.gem`

@run(./pushgem.fish)
@include(Update Blog Project)

## Strike

Testing ~~STRIKE~~