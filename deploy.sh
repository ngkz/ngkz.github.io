#!/usr/bin/env bash
set -euo pipefail
shopt -s extglob

if tty >/dev/null; then
    BOLD_CYAN="\033[1m\033[36m"
    NORMAL="\033[0m"
else
    BOLD_CYAN=
    NORMAL=
fi

echo -e "${BOLD_CYAN}Cleaning public directory${NORMAL}"
git worktree add public master
cd public
# Delete all files except .git
rm -rf !(.git|.|..|.nojekyll|CNAME)
# Bypassing jekyll
touch .nojekyll
cd ..

echo -e "${BOLD_CYAN}Building site${NORMAL}"
hugo

echo -e "${BOLD_CYAN}Pushing site${NORMAL}"
cd public
git add --all .
if ! git status | grep "nothing to commit" >/dev/null; then
    git commit -m "rebuild site"
fi
git push origin master

cd ..
git worktree remove public
rm -rf public
