# git2svn.sh

The script's task is to compare the directory with the GIT project (which should be fresher) with the directory with the SVN project and update the SVN directory to the same state as the GIT directory.

The script is not intended to copy the commit history, it only synchronizes files in SVN to the state from the GIT repository.

Usage:

```bash
./git2svn.sh /path/to/git /path/to/svn
```

To undo everything this script does in your SVN project, run these 2 commands:

```bash
svn revert -R .
svn st | grep '^\?' | sed 's/^? *//' | xargs -r rm -rf
```

Finally, you need to commit the changes to the SVN repository manually, using a command like:

```bash
svn commit -m "Update to version x.y.z"
```
