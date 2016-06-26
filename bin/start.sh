#!/bin/bash
TARGET="$HOME/Dropbox/blog/joaocenoura"
BUNDLE_GEMFILE=$TARGET/Gemfile \
bundle exec jekyll serve \
       --host 127.0.0.1 \
       --port 4000 \
       --source $TARGET \
       --destination /tmp/jekyll-joaocenoura \
       --baseurl /blog \
       --watch
