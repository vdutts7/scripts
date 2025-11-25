#!/usr/bin/env python3
import sys
from pynput import keyboard
from pynput.keyboard import Controller, Key
import time

# This script listens for a global hotkey and triggers the strikethrough action.
# It will run in the background until you stop it.

# The hotkey combination. Use <cmd> for Command, <alt> for Option, <ctrl> for Control, <shift> for Shift.
HOTKEY = '<cmd>+<alt>+s'

def on_activate():
    """When the hotkey is pressed, type the strikethrough markdown."""
    print("Hotkey activated. Typing strikethrough.")
    # A tiny delay to ensure context is right
    time.sleep(0.05)
    kb_controller = keyboard.Controller()
    
    # Type the two tildes
    kb_controller.press('~')
    kb_controller.release('~')
    kb_controller.press('~')
    kb_controller.release('~')

    # Move the cursor back two positions
    kb_controller.press(Key.left)
    kb_controller.release(Key.left)
    kb_controller.press(Key.left)
    kb_controller.release(Key.left)

def for_exit():
    """Gracefully exit the listener."""
    print("Exiting strikethrough script.")
    return False

# --- Main execution ---
if __name__ == "__main__":
    print(f"Strikethrough script running in the background.")
    print(f"Listening for hotkey: {HOTKEY}")
    print("Press Ctrl+C in this terminal to stop the script.")

    # Create the listener
    with keyboard.GlobalHotKeys({
        HOTKEY: on_activate,  # Your strikethrough function
        '<ctrl>+<cmd>+q': for_exit # A hotkey to gracefully quit the script
    }) as h:
        h.join()
