#!/bin/bash

# Obsidian Cache Flush
# Run this to backup and clear Obsidian cache when it's frozen

# Configuration
VAULT_PATH="$HOME/Documents/🟣-obs/"
BACKUP_DIR="$HOME/obsidian_cache_backup"
OBSIDIAN_APP_SUPPORT="$HOME/Library/Application Support/obsidian"

echo "========================================="
echo "Obsidian Cache Flush Script"
echo "========================================="
echo ""

# Step 1: Create backup directory
echo "1. Creating backup directory..."
mkdir -p "$BACKUP_DIR"
echo "   ✓ Created: $BACKUP_DIR"
echo ""

# Step 2: Force kill Obsidian
echo "2. Killing Obsidian processes..."
pkill -9 obsidian 2>/dev/null
killall -9 Obsidian 2>/dev/null
echo "   ✓ Processes killed"
echo ""

# Step 3: Backup cache files
echo "3. Backing up cache files..."
if [ -d "$OBSIDIAN_APP_SUPPORT/IndexedDB" ]; then
    cp -R "$OBSIDIAN_APP_SUPPORT/IndexedDB" "$BACKUP_DIR/"
    echo "   ✓ Backed up IndexedDB"
fi

if [ -d "$OBSIDIAN_APP_SUPPORT/Session Storage" ]; then
    cp -R "$OBSIDIAN_APP_SUPPORT/Session Storage" "$BACKUP_DIR/"
    echo "   ✓ Backed up Session Storage"
fi

if [ -d "$OBSIDIAN_APP_SUPPORT/blob_storage" ]; then
    cp -R "$OBSIDIAN_APP_SUPPORT/blob_storage" "$BACKUP_DIR/"
    echo "   ✓ Backed up blob_storage"
fi

if [ -f "$OBSIDIAN_APP_SUPPORT/obsidian.log" ]; then
    cp "$OBSIDIAN_APP_SUPPORT/obsidian.log" "$BACKUP_DIR/"
    echo "   ✓ Backed up obsidian.log"
fi

# Backup vault workspace.json
if [ -f "$VAULT_PATH/.obsidian/workspace.json" ]; then
    cp "$VAULT_PATH/.obsidian/workspace.json" "$BACKUP_DIR/vault_workspace.json"
    echo "   ✓ Backed up vault workspace.json"
fi
echo ""

# Step 4: Clear cache files
echo "4. Clearing cache files..."
rm -rf "$OBSIDIAN_APP_SUPPORT/Cache" 2>/dev/null
rm -rf "$OBSIDIAN_APP_SUPPORT/Code Cache" 2>/dev/null
rm -rf "$OBSIDIAN_APP_SUPPORT/GPUCache" 2>/dev/null
rm -rf "$OBSIDIAN_APP_SUPPORT/IndexedDB" 2>/dev/null
rm -rf "$OBSIDIAN_APP_SUPPORT/Session Storage" 2>/dev/null
rm -rf "$OBSIDIAN_APP_SUPPORT/blob_storage" 2>/dev/null
echo "   ✓ Cleared cache directories"

# Step 5: Remove lock files
echo "5. Removing lock files..."
rm -f "$OBSIDIAN_APP_SUPPORT/SingletonLock" 2>/dev/null
rm -f "$OBSIDIAN_APP_SUPPORT/SingletonCookie" 2>/dev/null
rm -f "$OBSIDIAN_APP_SUPPORT/SingletonSocket" 2>/dev/null
echo "   ✓ Removed lock files"

# Step 6: Clear vault workspace.json
echo "6. Clearing vault workspace.json..."
rm -f "$VAULT_PATH/.obsidian/workspace.json" 2>/dev/null
echo "   ✓ Cleared vault workspace.json"
echo ""

echo "========================================="
echo "✓ DONE!"
echo "========================================="
echo ""
echo "Backup saved to: $BACKUP_DIR"
echo ""
echo "Now open Obsidian - it will rebuild the cache fresh."
echo ""
