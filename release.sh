#!/bin/bash

# Release script for Markdown Editor
# This script will:
# 1. Show the current version
# 2. Prompt for a new version
# 3. Check if the tag already exists
# 4. Update the version in pubspec.yaml
# 5. Prompt for a changelog
# 6. Commit the changes
# 7. Create a tag with a changelog
# 8. Push everything to the repository

echo "=== Markdown Editor Release Tool ==="
echo ""

# Get current version
current_version=$(grep -m 1 "version:" pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
echo "Current version: $current_version"
echo ""

# Prompt for new version
echo "Enter new version (e.g., 1.0.1):"
read new_version
echo ""

if [ -z "$new_version" ]; then
    echo "Error: Version cannot be empty."
    exit 1
fi

# Check if tag already exists
if git rev-parse "v$new_version" >/dev/null 2>&1; then
    echo "Error: Tag v$new_version already exists."
    exit 1
fi

# Update version in pubspec.yaml
build_number=$(grep -m 1 "version:" pubspec.yaml | awk '{print $2}' | cut -d'+' -f2)
new_build_number=$((build_number + 1))
sed -i '' "s/version: .*$/version: $new_version+$new_build_number/" pubspec.yaml

echo "Updated version to $new_version+$new_build_number in pubspec.yaml"
echo ""

# Create a temporary file for the changelog
temp_file=$(mktemp)
echo "# Enter your changelog below (lines starting with # will be ignored)" > $temp_file
echo "# Save and close the editor when finished" >> $temp_file
echo "# ------------------------------------------" >> $temp_file
echo "" >> $temp_file
echo "Version $new_version" >> $temp_file
echo "" >> $temp_file
echo "- Add your changes here" >> $temp_file

# Open the editor (explicitly using vi)
vi $temp_file

# Extract the changelog (ignore comments and empty lines)
changelog=$(grep -v '^#' $temp_file | sed '/^$/d')
rm $temp_file

if [ -z "$changelog" ]; then
    echo "Error: Changelog cannot be empty."
    exit 1
fi

echo "Changelog:"
echo "$changelog"
echo ""

# Commit changes
git add pubspec.yaml
git commit -m "Bump version to $new_version"

# Create tag with changelog
git tag -a "v$new_version" -m "Version $new_version

$changelog"

echo "Created tag v$new_version"
echo ""

# Confirm push
echo "Push changes and tag to remote repository? (y/n):"
read confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    git push origin master
    git push origin "v$new_version"
    echo ""
    echo "Successfully pushed v$new_version to remote repository."
else
    echo ""
    echo "Changes are committed locally but not pushed."
    echo "To push manually:"
    echo "  git push origin master"
    echo "  git push origin v$new_version"
fi
