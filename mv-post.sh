#!/bin/sh
set -e
mv "content/post/$1.md" "content/post/$2.md"
if [ -e "static/assets/$1" ]; then
    mv "static/assets/$1" "static/assets/$2"
    sed -i "s|/assets/$1/|/assets/$2/|g" "content/post/$2.md"
fi
