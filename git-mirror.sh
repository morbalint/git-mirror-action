#!/bin/sh

set -e

SOURCE_REPO=$1
DESTINATION_REPO=$2
SOURCE_DIR=$(basename "$SOURCE_REPO")
SINGLE_BRANCH=$3
DRY_RUN=$4

GIT_SSH_COMMAND="ssh -v"

echo "SOURCE=$SOURCE_REPO"
echo "DESTINATION=$DESTINATION_REPO"
echo "SINGLE BRANCH=$SINGLE_BRANCH"
echo "DRY RUN=$DRY_RUN"

if [ -z "$SINGLE_BRANCH" ]
then
  git clone --mirror "$SOURCE_REPO" "$SOURCE_DIR" && cd "$SOURCE_DIR"
else
  echo "INFO: Single branch mirroring only!"
  git clone --bare --single-branch --branch "$SINGLE_BRANCH" "$SOURCE_REPO" "$SOURCE_DIR" && cd "$SOURCE_DIR"
fi
git remote set-url --push origin "$DESTINATION_REPO"

GIT_PUSH_FLAGS=""

# not much point of pruning all other branches that might be present when mirroring a single branch.
if [ -z "$SINGLE_BRANCH" ]
then
  git fetch -p origin
  # Exclude refs created by GitHub for pull request.
  git for-each-ref --format 'delete %(refname)' refs/pull | git update-ref --stdin
  GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS --mirror"
else
  GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS origin $SINGLE_BRANCH"
fi

if [ "$DRY_RUN" = "true" ]
then
    echo "INFO: Dry Run, no data is pushed"
    GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS --dry-run"
fi

echo "final git command: 'git push $GIT_PUSH_FLAGS'"
git push $GIT_PUSH_FLAGS
