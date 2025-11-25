#!/bin/zsh

# ==============================================================================
#   MAC SYSTEM ENUMERATION SCRIPT
#
#   How to Use:
#   -----------
#   1. Save this file to your system, for example:
#      ~/scripts/enumerate.sh
#
#   2. Open your Terminal and make this script executable by running:
#      chmod +x ~/scripts/enumerate.sh
#
#   3. From now on, to run the full system enumeration, execute this
#      script from your terminal. You will be prompted for your password.
#
#      ~/scripts/enumerate.sh
#
#   What it Does:
#   -------------
#   - Checks for and installs Homebrew if missing.
#   - Gathers key system, network, user, and software information.
#   - Is optimized for speed and low system impact.
#   - Saves a final report to a timestamped directory inside ~/scripts/
#
# ==============================================================================

# --- Dependency Handling ---
# Check for Homebrew and install if it's missing.
if ! command -v brew &> /dev/null; then
    echo "🔧 Homebrew not found. Installing now..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew is already installed."
fi

# --- Configuration ---
REPORT_DIR="Final-Report-$(date +%Y-%m-%d-%H%M%S)-$(system_profiler SPHardwareDataType | awk '/Hardware UUID/ {print $3}')"
mkdir -p "$REPORT_DIR"
OUTPUT_FILE="$REPORT_DIR/final-report.txt"

echo "🧠 Starting final system enumeration..."
echo "Report will be saved to: $OUTPUT_FILE"

# --- Helper Function ---
run_command() {
    local cmd="$1"
    local description="$2"
    echo "--- [ $description ] ---" >> "$OUTPUT_FILE"
    echo ">>> Running: $cmd" >> "$OUTPUT_FILE"
    eval "$cmd" >> "$OUTPUT_FILE" 2>&1
    echo "" >> "$OUTPUT_FILE"
    echo "============================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# --- The Smart Enumeration ---

# Print a header
echo "============================================================" >> "$OUTPUT_FILE"
echo "FINAL SYSTEM ENUMERATION REPORT" >> "$OUTPUT_FILE"
echo "Date: $(date)" >> "$OUTPUT_FILE"
echo "Hostname: $(hostname)" >> "$OUTPUT_FILE"
echo "User: $(whoami)" >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# 1. Core System Information (High Value, Low Cost)
run_command "system_profiler SPHardwareDataType" "Hardware Overview"
run_command "sw_vers && system_profiler SPSoftwareDataType | grep -E '(System Version|Computer Name|User Name)'" "Essential Software Info"
run_command "system_profiler SPPowerDataType" "Power & Battery Info"
run_command "system_profiler SPStorageDataType" "Storage Volumes"

# 2. Network Information (High Value, Low Cost)
run_command "ifconfig" "Network Interface Configuration"
run_command "netstat -rn | head -20" "Routing Table (First 20 Lines)"
run_command "lsof -i -P -n | grep LISTEN" "Listening Network Ports"

# 3. User & Security Information (High Value, Low Cost)
run_command "id && whoami" "Current User Identity"
run_command "sudo dscl . list /Users | grep -v '^_'" "All User Accounts"
run_command "sudo dscl . list /Groups | grep -v '^_'" "All User Groups"
run_command "sudo launchctl list | head -30" "Launch Daemons (First 30)"
run_command "launchctl list | head -30" "Launch Agents (First 30)"
run_command "fdesetup status" "FileVault Status"
run_command "csrutil status" "System Integrity Protection (SIP) Status"

# 4. Process Information (Medium Value, Medium Cost)
run_command "ps aux | head -30" "Running Processes (First 30)"
run_command "top -l 1 -n 10" "Top 10 Processes by CPU"

# 5. Software Information (High Value, Low Cost)
run_command "find /Applications -maxdepth 1 -print | head -30" "Installed GUI Applications (First 30)"
run_command "brew list --cask 2>/dev/null || echo 'Homebrew Cask not found'" "Homebrew Casks"
run_command "brew list 2>/dev/null || echo 'Homebrew not found'" "Homebrew Formulae"

# 6. Recent Logs (High Value, Low Cost)
run_command "last -10" "Last 10 Logins"
run_command "log show --predicate 'eventMessage contains \"error\"' --last 30m --style compact" "Recent Error Logs (Last 30 Mins)"

echo "============================================================" >> "$OUTPUT_FILE"
echo "FINAL ENUMERATION COMPLETE." >> "$OUTPUT_FILE"
echo "============================================================" >> "$OUTPUT_FILE"

echo ""
echo "✅ Done. Your final report is ready: $OUTPUT_FILE"

# ==============================================================================
#   COMPREHENSIVE MANIFEST OF ADDITIONAL ENUMERATION COMMANDS
#   ==============================================================================
#   The commands below are commented out to keep the base script fast.
#   To add more detail, uncomment the desired 'run_command' lines.
#   Be aware that each added command will increase execution time.
# ==============================================================================

# --- Deeper Network & Connectivity State ---
# run_command "netstat -rn" "Full Routing Table"
# run_command "arp -an" "ARP Table"
# run_command "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I" "Wireless Connection Details"
# run_command "scutil --nc list" "List All VPN and Network Configurations"
# run_command "networksetup -listallhardwareports" "List All Network Hardware Ports"

# --- Deeper Security & Persistence Mechanisms ---
# run_command "sudo crontab -l" "System Cron Jobs (root)"
# run_command "crontab -l" "Current User Cron Jobs"
# run_command "osascript -e 'tell application \"System Events\" to get the name of every login item'" "Current User Login Items"
# run_command "fdesetup list" "FileVault User & Recovery Key Status"
# run_command "cat /etc/hosts" "Hosts File Contents"
# run_command "ls -la /etc/sudoers.d/" "Sudoers.d Directory Contents"
# run_command "atq" "List AT Jobs"

# --- System & Kernel Integrity ---
# run_command "kextstat" "Loaded Kernel Extensions (kexts)"
# run_command "systemextensionsctl list" "System Extensions"
# run_command "csrutil status" "System Integrity Protection (SIP) Status" # Already included, but good to have here for completeness
# run_command "launchctl print system | grep com.apple" "Print System Launch Services"

# --- Sensitive File & Configuration Checks ---
# run_command "ls -la ~/.ssh" "List User SSH Keys"
# run_command "cat ~/.zshrc | grep -v '^#'" "Current User Zsh Profile (non-commented lines)"
# run_command "cat ~/.bash_profile | grep -v '^#'" "Current User Bash Profile (non-commented lines)"
# run_command "find /etc -maxdepth 1 -type f -exec ls -la {} \;" "List All Files in /etc Directory"

# --- Application & Browser Data (Advanced & Slower) ---
# run_command "find ~/Library/Application\ Support -maxdepth 2 -name 'Extensions' -print" "Find Browser Extension Directories"
# run_command "defaults read com.apple.Safari" "Safari's Plist Preferences"
# run_command "plutil -p ~/Library/Preferences/com.google.Chrome.plist" "Chrome's Plist Preferences"

# --- Full System State (High Impact, Use with Caution) ---
# run_command "sudo find / -type f -name '*.plist' -print" "Find All Plist Files System-Wide (SLOW)"
# run_command "ioreg -l" "Full I/O Kit Registry (VERY SLOW)"
# run_command "sysctl -a" "All Kernel Parameters (SLOW)"
# run_command "sudo lsof" "List All Open Files (VERY SLOW)"
# run_command "ps -ef" "All Running Processes in Full Format"
# run_command "sudo fs_usage" "Live Filesystem Activity (Requires manual stop)"

