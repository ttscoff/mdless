#!/usr/local/bin/fish

set -l ver (rake bump[inc])
changelog -f git >current_changelog.md
changelog -u
git commit -a -F current_changelog.md
git push
rake clobber package
GEM_HOST_OTP_CODE=$(op item get RubyGems --fields type=OTP --format json | jq -r .totp) gem push pkg/mdless-$ver.gem
# hub release create -m "v$ver" $ver
git pull
git flow release start $ver
git flow release finish -m "v$ver" $ver
FORCE_PUSH=true git push --all
FORCE_PUSH=true git push --tags
gh release create $ver --title "$ver" -F current_changelog.md
git pull
git push
git checkout $(git config --get gitflow.branch.develop)
rm current_changelog.md
