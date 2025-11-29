#!/bin/bash
# Script to help manage VS Code terminals
# This script provides commands to clean up terminal sessions

echo "VS Code Terminal Management Helper"
echo "=================================="
echo ""
echo "To manually close extra terminals in VS Code:"
echo "1. Click the '+' icon in the terminal panel to create a new terminal"
echo "2. Right-click on unwanted terminals and select 'Kill Terminal'"
echo "3. Or use Ctrl+Shift+P → 'Terminal: Kill All Terminals'"
echo ""
echo "To prevent multiple terminals:"
echo "- Tasks now use 'reveal: silent' to avoid popping up"
echo "- Set 'terminal.integrated.enablePersistentSessions': false"
echo "- Tasks reuse the shared terminal panel"
echo ""
echo "Current VS Code settings applied:"
echo "- terminal.integrated.shellIntegration.enabled: true"
echo "- terminal.integrated.enablePersistentSessions: false"
echo "- terminal.integrated.confirmOnExit: hasChildProcesses"
echo "- Tasks use 'panel: shared' and 'showReuseMessage: false'"