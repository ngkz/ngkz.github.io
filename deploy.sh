#!/bin/sh
#TODO: upgrade git and use git-worktree.
set -e

TEMPLATE_COMMIT=be94da0318fa2f742e1bf99826b565d51074a658
BOLD_CYAN="\033[1m\033[36m"
NORMAL="\033[0m"

echo "${BOLD_CYAN}Cleaning public directory${NORMAL}"
cd public
git reset --hard HEAD
git checkout master
git read-tree "$TEMPLATE_COMMIT"
git clean -fdx
cd ..

echo "${BOLD_CYAN}Generating site${NORMAL}"
hugo

echo "${BOLD_CYAN}Pushing site${NORMAL}"
cd public
git add --all .
git commit -m "generate site"
git push origin master
