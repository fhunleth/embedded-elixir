#!/bin/sh

set -e

DIR=$(dirname "$0")

cd $DIR/..

if [ "$(git status -s)" ]; then
    echo "The working directory is dirty. Please commit any pending changes."
    exit 1;
fi

SHA=$(git rev-parse HEAD)
if [ -n "$GITHUB_API_TOKEN" ]; then
    GIT_USER_ARGS="-c user.name='CI' -c user.email='fhunleth@troodon-software.com'"
fi

echo "Deleting old publication"
rm -rf public
mkdir public

echo "Creating gh-pages branch in ./public"
git -C public init
git -C public checkout -b gh-pages

echo "Generating site"
hugo

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "main" ]; then
    echo "Not on main, so skipping deploy."
    exit 0
fi

if [ -n "$CIRCLE_PR_USERNAME" ]; then
    echo "Not deploying PR"
    exit 0
fi

echo "Updating gh-pages branch"
git -C public add --all
git -C public $GIT_USER_ARGS commit -m "Publishing to gh-pages ($SHA) [skip ci]"

echo "Pushing gh-pages branch"
if [ -n "$GITHUB_API_TOKEN" ]; then
    # CI deployment
    git -C public push -f https://fhunleth:$GITHUB_API_TOKEN@github.com/fhunleth/embedded-elixir gh-pages:gh-pages 2>&1 | \
        sed s/$GITHUB_API_TOKEN/HIDDEN/g
  #  &2>/dev/null
else
    # Manual deployment
    git -C public push -f git@github.com:fhunleth/embedded-elixir.git gh-pages
fi

