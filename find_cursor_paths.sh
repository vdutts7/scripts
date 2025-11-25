#!/bin/bash
# pwd: ~/scripts
# chmod: chmod +x ~/scripts/find_cursor_paths.sh
# purpose: Discovers and reports all Cursor IDE data storage locations on macOS
#
# USAGE:
#   Interactive mode:
#     ./find_cursor_paths.sh
#
#   Automated mode (command-line args):
#     ./find_cursor_paths.sh -f 2 -o ~/output
#
#   Automated mode (piped input):
#     echo -e "2\n~/output" | ./find_cursor_paths.sh
#
# OPTIONS:
#   -f, --format FORMAT    Output format: 1 (text), 2 (json), 3 (both) [default: 1]
#   -o, --output DIR       Output directory [default: ~/Downloads]
#   -h, --help             Show help message
#
# EXAMPLES:
#   ./find_cursor_paths.sh                    # Interactive prompts
#   ./find_cursor_paths.sh -f 2 -o ~/tmp      # JSON to ~/tmp (one line, no prompts)
#   echo -e "2\n~/tmp" | ./find_cursor_paths.sh  # Piped input (automated)

# ============================================================================
# CONFIGURATION
# ============================================================================
DEFAULT_OUTPUT_DIR="$HOME/Downloads"
OUTPUT_FILENAME_PREFIX="cursor_paths"
TREE_MAX_DEPTH=3

# ============================================================================
# DEPENDENCY MANAGEMENT
# ============================================================================

# Check and install tree command if needed
ensure_tree_installed() {
    if ! command -v tree &> /dev/null; then
        echo "📦 Installing 'tree' command via Homebrew..."
        if command -v brew &> /dev/null; then
            brew install tree
        else
            echo "❌ Error: Homebrew not found. Please install Homebrew first:"
            echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    fi
}

# ============================================================================
# DATA COLLECTION FUNCTIONS
# ============================================================================

collect_path_data() {
    local path="$1"
    local type="$2"
    
    if [ ! -d "$path" ] && [ ! -f "$path" ]; then
        return
    fi
    
    local size_bytes=$(du -sb "$path" 2>/dev/null | cut -f1)
    local size_human=$(du -sh "$path" 2>/dev/null | cut -f1)
    local size_mb=$(du -sm "$path" 2>/dev/null | cut -f1)
    
    echo "{\"path\":\"$path\",\"type\":\"$type\",\"size_bytes\":$size_bytes,\"size_human\":\"$size_human\",\"size_mb\":$size_mb}"
}

collect_chat_databases() {
    local db_files=()
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            local size_bytes=$(du -sb "$file" 2>/dev/null | cut -f1)
            [ -z "$size_bytes" ] && size_bytes=0
            local size_human=$(du -sh "$file" 2>/dev/null | cut -f1 | sed 's/"/\\"/g')
            [ -z "$size_human" ] && size_human="0B"
            db_files+=("{\"path\":\"$file\",\"size_bytes\":$size_bytes,\"size_human\":\"$size_human\"}")
        fi
    done < <(find "$HOME/Library/Application Support/Cursor/User/globalStorage" -name "state.vscdb*" 2>/dev/null)
    
    if [ ${#db_files[@]} -eq 0 ]; then
        echo "[]"
    else
        IFS=','
        echo "[${db_files[*]}]"
    fi
}

collect_workspace_storage() {
    local workspaces=()
    while IFS= read -r workspace_dir; do
        if [ -d "$workspace_dir" ]; then
            local workspace_id=$(basename "$workspace_dir")
            local db_file="$workspace_dir/state.vscdb"
            local db_backup="$workspace_dir/state.vscdb.backup"
            local has_db="false"
            local has_backup="false"
            local db_size_bytes=0
            local db_size_human="0B"
            local backup_size_bytes=0
            local backup_size_human="0B"
            
            if [ -f "$db_file" ]; then
                has_db="true"
                db_size_bytes=$(du -sb "$db_file" 2>/dev/null | cut -f1)
                [ -z "$db_size_bytes" ] && db_size_bytes=0
                db_size_human=$(du -sh "$db_file" 2>/dev/null | cut -f1 | sed 's/"/\\"/g')
                [ -z "$db_size_human" ] && db_size_human="0B"
            fi
            
            if [ -f "$db_backup" ]; then
                has_backup="true"
                backup_size_bytes=$(du -sb "$db_backup" 2>/dev/null | cut -f1)
                [ -z "$backup_size_bytes" ] && backup_size_bytes=0
                backup_size_human=$(du -sh "$db_backup" 2>/dev/null | cut -f1 | sed 's/"/\\"/g')
                [ -z "$backup_size_human" ] && backup_size_human="0B"
            fi
            
            workspaces+=("{\"workspace_id\":\"$workspace_id\",\"path\":\"$workspace_dir\",\"has_database\":$has_db,\"database\":{\"path\":\"$db_file\",\"size_bytes\":$db_size_bytes,\"size_human\":\"$db_size_human\"},\"has_backup\":$has_backup,\"backup\":{\"path\":\"$db_backup\",\"size_bytes\":$backup_size_bytes,\"size_human\":\"$backup_size_human\"}}")
        fi
    done < <(find "$HOME/Library/Application Support/Cursor/User/workspaceStorage" -maxdepth 1 -type d ! -path "$HOME/Library/Application Support/Cursor/User/workspaceStorage" 2>/dev/null)
    
    if [ ${#workspaces[@]} -eq 0 ]; then
        echo "[]"
    else
        IFS=','
        echo "[${workspaces[*]}]"
    fi
}

collect_all_paths() {
    local paths=()
    while IFS= read -r path; do
        if [ -d "$path" ] || [ -f "$path" ]; then
            paths+=("\"$path\"")
        fi
    done < <(find ~/Library -type d -o -type f \( -name "*cursor*" -o -name "*Cursor*" \) 2>/dev/null | grep -v node_modules)
    
    if [ ${#paths[@]} -eq 0 ]; then
        echo "[]"
    else
        IFS=','
        echo "[${paths[*]}]"
    fi
}

# ============================================================================
# JSON GENERATION
# ============================================================================

generate_json() {
    local app_support_path="$HOME/Library/Application Support/Cursor"
    local config_path="$HOME/.cursor"
    local cache_path="$HOME/Library/Caches/Cursor"
    local app_path="/Applications/Cursor.app"
    
    local app_support_size_mb=0
    local config_size_mb=0
    local cache_size_mb=0
    local total_size_mb=0
    
    [ -d "$app_support_path" ] && app_support_size_mb=$(du -sm "$app_support_path" 2>/dev/null | cut -f1)
    [ -d "$config_path" ] && config_size_mb=$(du -sm "$config_path" 2>/dev/null | cut -f1)
    [ -d "$cache_path" ] && cache_size_mb=$(du -sm "$cache_path" 2>/dev/null | cut -f1)
    total_size_mb=$((app_support_size_mb + config_size_mb + cache_size_mb))
    
    local log_count=0
    [ -d "$app_support_path/logs" ] && log_count=$(find "$app_support_path/logs" -type f -name "*.log" 2>/dev/null | wc -l | xargs)
    
    local workspace_count=0
    [ -d "$app_support_path/User/workspaceStorage" ] && workspace_count=$(find "$app_support_path/User/workspaceStorage" -name "state.vscdb" 2>/dev/null | wc -l | xargs)
    
    cat <<EOF
{
  "metadata": {
    "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "generated_by": "find_cursor_paths.sh",
    "system": "$(uname -s)",
    "hostname": "$(hostname)",
    "user": "$USER"
  },
  "storage_summary": {
    "total_size_mb": $total_size_mb,
    "total_size_human": "${total_size_mb}MB",
    "breakdown": {
      "application_support": {
        "path": "$app_support_path",
        "exists": $([ -d "$app_support_path" ] && echo "true" || echo "false"),
        "size_mb": $app_support_size_mb,
        "size_human": "$(du -sh "$app_support_path" 2>/dev/null | cut -f1 || echo "0B")"
      },
      "configuration": {
        "path": "$config_path",
        "exists": $([ -d "$config_path" ] && echo "true" || echo "false"),
        "size_mb": $config_size_mb,
        "size_human": "$(du -sh "$config_path" 2>/dev/null | cut -f1 || echo "0B")"
      },
      "cache": {
        "path": "$cache_path",
        "exists": $([ -d "$cache_path" ] && echo "true" || echo "false"),
        "size_mb": $cache_size_mb,
        "size_human": "$(du -sh "$cache_path" 2>/dev/null | cut -f1 || echo "0B")"
      }
    }
  },
  "chat_storage": {
    "global_database": {
      "path": "$app_support_path/User/globalStorage",
      "databases": $(collect_chat_databases)
    },
    "workspace_databases": {
      "count": $workspace_count,
      "path": "$app_support_path/User/workspaceStorage",
      "workspaces": $(collect_workspace_storage)
    }
  },
  "logs": {
    "path": "$app_support_path/logs",
    "exists": $([ -d "$app_support_path/logs" ] && echo "true" || echo "false"),
    "count": $log_count
  },
  "application": {
    "path": "$app_path",
    "exists": $([ -d "$app_path" ] && echo "true" || echo "false"),
    "size_mb": $(du -sm "$app_path" 2>/dev/null | cut -f1 || echo "0"),
    "size_human": "$(du -sh "$app_path" 2>/dev/null | cut -f1 || echo "0B")"
  },
  "all_paths": $(collect_all_paths)
}
EOF
}

# ============================================================================
# TEXT REPORT GENERATION
# ============================================================================

generate_text_report() {
    echo "=========================================="
    echo "Cursor IDE - Complete Path Discovery"
    echo "Generated: $(date)"
    echo "=========================================="
    echo ""

    echo "📁 PRIMARY DATA LOCATIONS:"
    echo "---------------------------"
    echo ""
    
    echo "1. Application Support (Main Data):"
    echo "   ~/Library/Application Support/Cursor"
    if [ -d "$HOME/Library/Application Support/Cursor" ]; then
        size=$(du -sh "$HOME/Library/Application Support/Cursor" 2>/dev/null | cut -f1)
        echo "   Size: $size"
        echo ""
        echo "   Directory Structure:"
        tree -L "$TREE_MAX_DEPTH" -d "$HOME/Library/Application Support/Cursor" 2>/dev/null || find "$HOME/Library/Application Support/Cursor" -type d -maxdepth "$TREE_MAX_DEPTH" 2>/dev/null
    fi
    echo ""

    echo "2. Configuration Directory:"
    echo "   ~/.cursor"
    if [ -d "$HOME/.cursor" ]; then
        size=$(du -sh "$HOME/.cursor" 2>/dev/null | cut -f1)
        echo "   Size: $size"
        echo ""
        echo "   Directory Structure:"
        tree -L "$TREE_MAX_DEPTH" -d "$HOME/.cursor" 2>/dev/null || find "$HOME/.cursor" -type d -maxdepth "$TREE_MAX_DEPTH" 2>/dev/null
    fi
    echo ""

    echo "3. Cache Directory:"
    echo "   ~/Library/Caches/Cursor"
    if [ -d "$HOME/Library/Caches/Cursor" ]; then
        size=$(du -sh "$HOME/Library/Caches/Cursor" 2>/dev/null | cut -f1)
        echo "   Size: $size"
        echo ""
        echo "   Directory Structure:"
        tree -L "$TREE_MAX_DEPTH" -d "$HOME/Library/Caches/Cursor" 2>/dev/null || find "$HOME/Library/Caches/Cursor" -type d -maxdepth "$TREE_MAX_DEPTH" 2>/dev/null
    fi
    echo ""

    echo "💬 CHAT/CONVERSATION STORAGE:"
    echo "------------------------------"
    echo ""
    echo "Global Chat Database:"
    if [ -d "$HOME/Library/Application Support/Cursor/User/globalStorage" ]; then
        find "$HOME/Library/Application Support/Cursor/User/globalStorage" -name "state.vscdb*" 2>/dev/null | while read file; do
            if [ -f "$file" ]; then
                size=$(du -h "$file" | cut -f1)
                echo "   $file ($size)"
            fi
        done
    fi
    echo ""

    echo "Workspace Chat Databases:"
    workspace_count=$(find "$HOME/Library/Application Support/Cursor/User/workspaceStorage" -name "state.vscdb" 2>/dev/null | wc -l | xargs)
    echo "   Found: $workspace_count"
    if [ -d "$HOME/Library/Application Support/Cursor/User/workspaceStorage" ] && [ "$workspace_count" -gt 0 ]; then
        echo ""
        echo "   Workspace Storage Structure:"
        tree -L 2 -d "$HOME/Library/Application Support/Cursor/User/workspaceStorage" 2>/dev/null || ls -la "$HOME/Library/Application Support/Cursor/User/workspaceStorage"
    fi
    echo ""

    echo "📝 LOG FILES:"
    echo "-------------"
    if [ -d "$HOME/Library/Application Support/Cursor/logs" ]; then
        log_count=$(find "$HOME/Library/Application Support/Cursor/logs" -type f -name "*.log" 2>/dev/null | wc -l | xargs)
        echo "   Log files found: $log_count"
        echo "   Location: ~/Library/Application Support/Cursor/logs/"
        echo ""
        echo "   Log Directory Structure:"
        tree -L 2 -d "$HOME/Library/Application Support/Cursor/logs" 2>/dev/null || ls -la "$HOME/Library/Application Support/Cursor/logs"
    fi
    echo ""

    echo "🗂️ APPLICATION FILES:"
    echo "---------------------"
    if [ -d "/Applications/Cursor.app" ]; then
        size=$(du -sh "/Applications/Cursor.app" 2>/dev/null | cut -f1)
        echo "   /Applications/Cursor.app ($size)"
        echo ""
        echo "   Application Structure:"
        tree -L 2 -d "/Applications/Cursor.app/Contents" 2>/dev/null || find "/Applications/Cursor.app/Contents" -type d -maxdepth 2 2>/dev/null
    fi
    echo ""

    echo "📊 STORAGE SUMMARY:"
    echo "-------------------"
    total=0
    if [ -d "$HOME/Library/Application Support/Cursor" ]; then
        app_support_size=$(du -sm "$HOME/Library/Application Support/Cursor" 2>/dev/null | cut -f1)
        total=$((total + app_support_size))
        echo "   Application Support: ${app_support_size}MB"
    fi
    if [ -d "$HOME/.cursor" ]; then
        config_size=$(du -sm "$HOME/.cursor" 2>/dev/null | cut -f1)
        total=$((total + config_size))
        echo "   Configuration: ${config_size}MB"
    fi
    if [ -d "$HOME/Library/Caches/Cursor" ]; then
        cache_size=$(du -sm "$HOME/Library/Caches/Cursor" 2>/dev/null | cut -f1)
        total=$((total + cache_size))
        echo "   Cache: ${cache_size}MB"
    fi
    echo "   Total: ~${total}MB"
    echo ""

    echo "🔍 ALL CURSOR-RELATED PATHS (Tree View):"
    echo "----------------------------------------"
    echo ""
    echo "Directories in ~/Library:"
    find ~/Library -type d \( -name "*cursor*" -o -name "*Cursor*" \) 2>/dev/null | grep -v node_modules | while read dir; do
        if [ -d "$dir" ]; then
            echo "   $dir"
        fi
    done
    echo ""

    echo "✅ Manifest saved to: ~/.cursor/CURSOR_DATA_MANIFEST.md"
    echo ""
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

# Parse command-line arguments
FORMAT_ARG=""
OUTPUT_ARG=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--format)
            FORMAT_ARG="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_ARG="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -f, --format FORMAT    Output format: 1 (text), 2 (json), 3 (both) [default: 1]"
            echo "  -o, --output DIR       Output directory [default: $DEFAULT_OUTPUT_DIR]"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Interactive mode"
            echo "  $0 -f 2 -o ~/tmp                      # JSON to ~/tmp"
            echo "  echo -e \"2\n~/tmp\" | $0              # Piped input"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Ensure tree is installed
ensure_tree_installed

# Get format choice and output directory
if [ -n "$FORMAT_ARG" ] && [ -n "$OUTPUT_ARG" ]; then
    # Both provided via args - use them
    format_choice="$FORMAT_ARG"
    output_dir="$OUTPUT_ARG"
elif [ -n "$FORMAT_ARG" ]; then
    # Format from arg, output from stdin/prompt
    format_choice="$FORMAT_ARG"
    if [ -t 0 ]; then
        echo ""
        echo "Enter output directory path (press Enter for default: $DEFAULT_OUTPUT_DIR):"
        read -r output_dir
    else
        read -r output_dir
    fi
elif [ -n "$OUTPUT_ARG" ]; then
    # Output from arg, format from stdin/prompt
    output_dir="$OUTPUT_ARG"
    if [ -t 0 ]; then
        echo ""
        echo "Select output format:"
        echo "  1) Text (human-readable)"
        echo "  2) JSON (structured, machine-readable)"
        echo "  3) Both (text + JSON)"
        echo ""
        echo "Enter choice (press Enter for default: 1):"
        read -r format_choice
    else
        read -r format_choice
    fi
else
    # Neither provided - check if stdin is piped
    if [ -t 0 ]; then
        # Interactive mode - prompt for both
        echo ""
        echo "Select output format:"
        echo "  1) Text (human-readable)"
        echo "  2) JSON (structured, machine-readable)"
        echo "  3) Both (text + JSON)"
        echo ""
        echo "Enter choice (press Enter for default: 1):"
        read -r format_choice
        echo ""
        echo "Enter output directory path (press Enter for default: $DEFAULT_OUTPUT_DIR):"
        read -r output_dir
    else
        # Non-interactive mode - read both from stdin (one per line)
        read -r format_choice
        read -r output_dir
    fi
fi

# Set defaults if empty
if [ -z "$format_choice" ]; then
    format_choice="1"
fi
if [ -z "$output_dir" ]; then
    output_dir="$DEFAULT_OUTPUT_DIR"
fi

# Use default if empty
if [ -z "$output_dir" ]; then
    output_dir="$DEFAULT_OUTPUT_DIR"
fi

# Expand ~ to home directory
output_dir="${output_dir/#\~/$HOME}"

# Create directory if it doesn't exist
mkdir -p "$output_dir"

# Generate timestamped filenames
timestamp=$(date +"%Y%m%d_%H%M%S")
text_file="$output_dir/${OUTPUT_FILENAME_PREFIX}_${timestamp}.txt"
json_file="$output_dir/${OUTPUT_FILENAME_PREFIX}_${timestamp}.json"

# Generate outputs based on choice
case "$format_choice" in
    1)
        generate_text_report | tee "$text_file"
        output_file="$text_file"
        ;;
    2)
        generate_json | tee "$json_file"
        output_file="$json_file"
        ;;
    3)
        generate_text_report | tee "$text_file"
        echo ""
        generate_json | tee "$json_file"
        output_file="$text_file + $json_file"
        ;;
    *)
        echo "Invalid choice. Using text format."
        generate_text_report | tee "$text_file"
        output_file="$text_file"
        ;;
esac

# Display output location clearly
echo ""
echo "═══════════════════════════════════════════"
echo "📄 OUTPUT SAVED TO:"
echo "═══════════════════════════════════════════"
if [ "$format_choice" = "3" ]; then
    echo "   Text: $text_file"
    echo "   JSON: $json_file"
else
    echo "   $output_file"
fi
echo "═══════════════════════════════════════════"
echo ""
