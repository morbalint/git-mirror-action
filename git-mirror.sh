#!/bin/sh

set -e

SOURCE_REPO=$1
DESTINATION_REPO=$2
SOURCE_DIR=$(basename "$SOURCE_REPO")
SINGLE_BRANCH=$3
SINGLE_BRANCH_FORCE=$4
DRY_RUN=$5

GIT_SSH_COMMAND="ssh -v"

echo "SOURCE=$SOURCE_REPO"
echo "DESTINATION=$DESTINATION_REPO"
echo "SINGLE BRANCH=$SINGLE_BRANCH"
echo "SINGLE BRANCH FORCE PUSH=$SINGLE_BRANCH_FORCE"
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
  if [ "$SINGLE_BRANCH_FORCE" = "true" ]
  then
    echo "INFO: Force pushing the single branch"
    GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS --force"
  fi
fi

if [ "$DRY_RUN" = "true" ]
then
    echo "INFO: Dry Run, no data is pushed"
    GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS --dry-run"
fi

echo "final git command: 'git push $GIT_PUSH_FLAGS'"
git push $GIT_PUSH_FLAGS
