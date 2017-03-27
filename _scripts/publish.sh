#!/bin/sh

set -e

DIR=$(dirname "$0")

cd $DIR/..

if [ "$(git status -s)" ]; then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

echo "Deleting old publication"
rm -rf public
mkdir public
git worktree prune
rm -rf .git/worktrees/public/

echo "Checking out gh-pages branch into public"
git worktree add public origin/gh-pages
git -C public checkout -B gh-pages

echo "Removing existing files"
rm -rf public/*

echo "Generating site"
hugo

echo "Updating gh-pages branch"
git -C public add --all
git -C public commit -m "Publishing to gh-pages (publish.sh)"
git -C public push

