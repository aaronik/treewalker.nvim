#!/bin/bash
# Script to check local nvim-treesitter version

echo "=== Local nvim-treesitter Version ==="
cd ~/.local/share/nvim/lazy/nvim-treesitter || exit 1
echo "Latest commit:"
git log -1 --oneline
echo ""
echo "Version tag:"
git describe --tags --always
echo ""
echo "Remote URL:"
git remote get-url origin
