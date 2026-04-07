#!/usr/bin/env bash
set -e
REPO="https://github.com/ThomasITU/macOsSetup.git"
DEST="$HOME/macOsSetup"

if [ -d "$DEST" ]; then
  echo "Directory $DEST already exists. Pulling latest changes..."
  git -C "$DEST" pull
else
  git clone "$REPO" "$DEST"
fi

cd "$DEST"
./bootstrap.sh
