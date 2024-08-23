#!/bin/bash

# Check if the source directory is provided as an argument
if [ -z "$1" ]; then
  echo "Usage: $0 <source_directory>"
  exit 1
fi

SOURCE_DIR=$1
BUILD_DIR=$2

# Create the build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Copy all files from the source directory to the build directory
cp -r "$SOURCE_DIR"/* "$BUILD_DIR"

# Install Python requirements into the build directory
pip install -r requirements.txt -t "$BUILD_DIR"

echo "Files copied and dependencies installed in the build directory."
