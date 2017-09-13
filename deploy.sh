#!/bin/sh
#TODO: upgrade git and use git-worktree.
set -e

BOLD_CYAN="\033[1m\033[36m"
NORMAL="\033[0m"

echo "${BOLD_CYAN}Cleaning public directory${NORMAL}"
cd public
git reset --hard HEAD
git clean -fdx
git revert -n HEAD
cd ..

echo "${BOLD_CYAN}Generating site${NORMAL}"
hugo

echo "${BOLD_CYAN}Pushing site${NORMAL}"
cd public
git add --all .
git commit -m "generate site"
git push origin master
