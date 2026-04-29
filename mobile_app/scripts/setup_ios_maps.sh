#!/bin/bash

# Exit on error
set -e

# Navigate to the project root
cd "$(dirname "$0")/.."

# Load environment variables
if [ -f ".env" ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "Error: .env file not found in the project root directory."
  exit 1
fi

# Check if Google Maps API key is set
if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
  echo "Error: GOOGLE_MAPS_API_KEY is not set in the .env file."
  exit 1
fi

# Path to the template and destination files
TEMPLATE_FILE="ios/Runner/GoogleMaps-Info.plist.template"
DEST_FILE="ios/Runner/GoogleMaps-Info.plist"

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: Template file $TEMPLATE_FILE not found."
  exit 1
fi

# Create the destination directory if it doesn't exist
mkdir -p "$(dirname "$DEST_FILE")"

# Replace the API key in the template and save to destination
sed "s/YOUR_GOOGLE_MAPS_API_KEY/$GOOGLE_MAPS_API_KEY/g" "$TEMPLATE_FILE" | \
  sed "s/YOUR_GOOGLE_PLACES_API_KEY/$GOOGLE_MAPS_API_KEY/g" > "$DEST_FILE"

echo "✅ Successfully created $DEST_FILE with your Google Maps API key."
echo "🔒 Don't forget to add 'GoogleMaps-Info.plist' to your .gitignore file!"

# Make the script executable
chmod +x "$0"

echo "✅ Setup script is now executable."
