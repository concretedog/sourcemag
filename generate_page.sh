#!/bin/bash
# Generates cover thumbnails and index.html
#
# You will need:
#
# sudo apt update
# sudo apt install poppler-utils imagemagick
#

# Function to extract creation date
get_pdf_month_year() {
  local file="$1"

  if [[ -z "$file" ]]; then
    echo "Usage: get_pdf_month_year <file.pdf>"
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    echo "Error: File not found: $file"
    return 1
  fi

  # Extract the raw CreationDate using pdfinfo
  local raw_date
  raw_date=$(pdfinfo "$file" 2>/dev/null | awk -F': +' '/CreationDate/ {print $2}')

  if [[ -z "$raw_date" ]]; then
    echo "No CreationDate found in PDF metadata."
    return 1
  fi

  # Try to parse with the `date` command
  local formatted_date
  formatted_date=$(date -d "$raw_date" +"%B %Y" 2>/dev/null)

  # If the above failed (e.g., PDF-style date like D:20241003142107+02'00')
  if [[ -z "$formatted_date" ]]; then
    # Clean out non-numeric characters and take YYYYMMDD
    local clean_date=${raw_date//[!0-9]/}
    formatted_date=$(date -d "${clean_date:0:8}" +"%B %Y" 2>/dev/null)
  fi

  if [[ -z "$formatted_date" ]]; then
    echo "Could not parse creation date: $raw_date"
    return 1
  fi

  echo "$formatted_date"
}


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
  convert $THUMBNAIL.png -resize 600x600 $THUMBNAIL.png
done

# index.html
echo "Generating index.html..."
ISSUE_HTML=$(for issue in `ls -1 issues | sort -n`; do
  ISSUE_DATE=$(pdfinfo issues/$issue/SOURCE_issue_$issue.pdf | awk -F': +' '/CreationDate/ {
    cmd = "date -d \""$2"\" +\"%B %Y\""
    cmd | getline formatted
    close(cmd)
    print formatted
  }')
  cat templates/issue_snippet.html.template | sed -e "s/ISSUE_NUMBER/$issue/g" | sed -e "s/ISSUE_DATE/$ISSUE_DATE/g"; done)
ISSUE_HTML=$(printf '%s\n' "$ISSUE_HTML" | sed -e 's/[\/&]/\\&/g') # escape replacement
cat templates/index.html.template | sed -e "s|ISSUES_SNIPPET|${ISSUE_HTML//$'\n'/\\n}|g" > index.html
