#!/bin/bash
# ~/scripts/show_hidden_files.sh
# This script configures Finder AND system file dialogs to show hidden files.
#
# USAGE:
# 1. Save this script to a file named "show_hidden_files.sh"
# 2. Make it executable: chmod +x show_hidden_files.sh
# 3. Run it: ./show_hidden_files.sh
#
# WHAT IT DOES:
# - Shows hidden files in the main Finder windows
# - Shows hidden files in "Open" and "Save" dialogs (THIS IS THE KEY FIX)
# - Restarts Finder and relevant system processes to apply changes

echo "Configuring hidden files visibility..."

# 1. Show hidden files in the main Finder application
defaults write com.apple.finder AppleShowAllFiles -bool true

# 2. THIS IS THE FIX: Show hidden files in all system "Open" and "Save" dialogs
defaults write com.apple.finder AppleShowAllFiles -bool true
# The above command is the main one, but sometimes this is needed for other apps
defaults write -g AppleShowAllFiles -bool true

# 3. Restart Finder to apply the changes
echo "Restarting Finder..."
killall Finder

# 4. Restart any other processes that might be caching the old setting
# This ensures the change takes effect immediately everywhere
echo "Restarting relevant system processes..."
killall Dock
killall SystemUIServer

echo "✅ Done! Hidden files should now be visible in Finder AND in all 'Open'/'Save' dialogs."
echo "You may need to restart any applications that were already open."
