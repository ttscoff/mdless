#!/usr/local/bin/fish

set -l ver (rake bump[inc])
changelog -f markdown > current_changelog.md
changelog -u
git commit -a -m "v$ver" -F current_changelog.md
git push
rake clobber package
gem push pkg/mdless-$ver.gem
# hub release create -m "v$ver" $ver
git pull
git flow release start $ver
git flow release finish -m "v$ver" $ver
FORCE_PUSH=true git push --all
FORCE_PUSH=true git push --tags
gh release create $ver -F current_changelog.md
git pull
git push
git checkout $(git config --get gitflow.branch.develop)
rm current_changelog.md
