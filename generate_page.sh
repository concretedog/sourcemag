#!/bin/bash
# Generates cover thumbnails and index.html
#
# You will need:
#
# sudo apt update
# sudo apt install poppler-utils imagemagick
#

# Cover thumbnails
for issue in `ls -1 issues`; do
  THUMBNAIL=covers/SOURCE_issue_$issue-cover
  if [ -f "$THUMBNAIL.png" ]; then
    echo "Skipping issue $issue as thumnail exists."
    continue
  fi
  echo "Generating issue $issue thumbnail as $THUMBNAIL.png..."
  pdftoppm -f 1 -l 1 -png issues/$issue/SOURCE_issue_$issue.pdf $THUMBNAIL
  mv $THUMBNAIL-01.png $THUMBNAIL.png
  convert $THUMBNAIL.png -resize 300x300 $THUMBNAIL.png
done

# index.html
echo "Generating index.html..."
ISSUE_HTML=$(for issue in `ls -1 issues | sort -n`; do cat templates/issue_snippet.html.template | sed -e "s/ISSUE_NUMBER/$issue/g"; done)
ISSUE_HTML=$(printf '%s\n' "$ISSUE_HTML" | sed -e 's/[\/&]/\\&/g') # escape replacement
cat templates/index.html.template | sed -e "s|ISSUES_SNIPPET|${ISSUE_HTML//$'\n'/\\n}|g" > index.html
