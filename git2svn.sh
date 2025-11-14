#!/bin/bash

# ------------------------------------------------------------------------------
# The script's task is to compare the directory with the GIT project (which
# should be fresher) with the directory with the SVN project and update the SVN
# directory to the same state as the GIT directory.
#
# The script is not intended to copy the commit history, it only synchronizes
# files in SVN to the state from the GIT repository.
#
# Usage:
#     ./git2svn.sh /path/to/git /path/to/svn
#
#  First argument  = GIT project directory
#  Second argument = SVN working copy directory
#
#
# To undo everything this script does in your SVN project, run these 2 commands:
#     svn revert -R .
#     svn st | grep '^\?' | sed 's/^? *//' | xargs -r rm -rf
# ------------------------------------------------------------------------------

set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 /git/dir /svn/dir"
    exit 1
fi

# Path to GIT project (source)
GIT_DIR="$1"

# Path to SVN project (target)
SVN_DIR="$2"

# Validate Git directory
if [ ! -d "$GIT_DIR/.git" ]; then
    echo "Error: First parameter is not a Git repository."
    exit 1
fi

# Validate SVN directory (works for subdirectories in a larger repo)
if [ ! -d "$SVN_DIR" ]; then
    echo "Error: Second parameter is not a valid directory."
    exit 1
fi

if ! svn info "$SVN_DIR" &>/dev/null; then
    echo "Error: Directory is not an SVN working copy."
    exit 1
fi

cd "$SVN_DIR"

echo "Synchronizing SVN with GIT..."
echo "GIT: $GIT_DIR"
echo "SVN: $SVN_DIR"

svn up

#
# DELETING FILES THAT HAVE DISAPPEARED FROM GIT
#
echo "Finding files to delete..."

# List of files in SVN (grep -v '/$' removes directories, i.e. entries ending with /)
svn_files=$(svn ls -R | grep -v '/$' || true)

while IFS= read -r f; do
    if [ -z "$f" ]; then
        continue
    fi

    if [ ! -f "$GIT_DIR/$f" ]; then
        echo "DELETE: $f"
        svn delete "$f"
    fi
done <<< "$svn_files"

#
# COPYING NEW AND CHANGED FILES FROM GIT TO SVN
#
echo "Copying new/updated files..."

rsync -av --delete \
    --exclude=".git" \
    --exclude=".svn" \
    --exclude=".env" \
    --exclude=".vscode" \
    "$GIT_DIR"/ "$SVN_DIR"/

#
# MARK NEW FILES TO ADD TO SVN
#
echo "Adding new files..."

svn st | grep '^\?' | sed 's/^? *//' | xargs -r svn add

#
# REMOVE EMPTY DIRECTORIES WITH EXCLAMATION MARKS
#
svn st | grep '^!' | sed 's/^! *//' | xargs -r svn delete

#
# REMOVING svn:executable
#
echo "Removing svn:executable flags..."

svn propdel svn:executable -R .

echo
echo "DONE."
echo

svn st

echo
echo "Now execute: svn commit -m \"Update to version x.y.z\""
