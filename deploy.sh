#!/bin/bash
#TODO: upgrade git and use git-worktree.
set -e
shopt -s extglob

BOLD_CYAN="\033[1m\033[36m"
NORMAL="\033[0m"

echo -e "${BOLD_CYAN}Cleaning public directory${NORMAL}"
cd public
# Ensure that the current branch is master.
git reset --hard HEAD
git checkout master
# Delete all files except .git
rm -rf !(.git|.|..)
# Bypassing jekyll
touch .nojekyll
cd ..

echo -e "${BOLD_CYAN}Building site${NORMAL}"
hugo

echo -e "${BOLD_CYAN}Pushing site${NORMAL}"
cd public
git add --all .
git commit -m "rebuild site"
git push origin master
