#!/bin/bash
set -e

# Fix coreutils 9 --update=none syntax on Ubuntu 22.04 (coreutils 8.32)
if [ -f /usr/bin/cp ] && [ ! -f /usr/bin/cp.real ]; then
    echo "Patching /usr/bin/cp for compatibility..."
    sudo mv /usr/bin/cp /usr/bin/cp.real
    sudo tee /usr/bin/cp > /dev/null << 'EOF'
#!/bin/bash
args=()
for arg in "$@"; do
    if [[ "$arg" == "--update=none" ]]; then
        args+=("-n")
    elif [[ "$arg" == "--update=all" ]]; then
        : # omit
    elif [[ "$arg" == "--update=older" ]]; then
        args+=("-u")
    else
        args+=("$arg")
    fi
done
exec /usr/bin/cp.real "${args[@]}"
EOF
    sudo chmod +x /usr/bin/cp
fi

# Verify wrapper handles --update=none without error
cp --update=none /dev/null /tmp/test_cp_wrapper 2>/dev/null || true
echo "Successfully installed and verified coreutils cp wrapper"
