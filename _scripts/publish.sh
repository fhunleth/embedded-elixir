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
    GIT_USER_ARGS="-c user.name='travis' -c user.email='travis'"
fi

echo "Deleting old publication"
rm -rf public
mkdir public

echo "Creating gh-pages branch in ./public"
git -C public init
git -C public checkout -b gh-pages

echo "Generating site"
hugo

echo "Updating gh-pages branch"
git -C public add --all
git -C public $GIT_USER_ARGS commit -m "Publishing to gh-pages ($SHA)"

echo "Pushing gh-pages branch"
if [ -n "$GITHUB_API_TOKEN" ]; then
    # CI deployment
    git -C public push -f -q https://fhunleth:$GITHUB_API_TOKEN@github.com/fhunleth/embedded-elixir gh-pages:gh-pages &2>/dev/null
else
    # Manual deployment
    git -C public push -f git@github.com:fhunleth/embedded-elixir.git gh-pages
fi

