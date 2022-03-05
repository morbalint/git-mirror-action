#!/bin/sh

set -e

SOURCE_REPO=$1
DESTINATION_REPO=$2
SOURCE_DIR=$(basename "$SOURCE_REPO")
BRANCHES=$3
FORCE_PUSH_BRANCHES=$4
DRY_RUN=$5

GIT_SSH_COMMAND="ssh -v"

echo "SOURCE=$SOURCE_REPO"
echo "DESTINATION=$DESTINATION_REPO"
echo "BRANCHES=$BRANCHES"
echo "FORCE PUSH BRANCHES=$FORCE_PUSH_BRANCHES"
echo "DRY RUN=$DRY_RUN"

if [ -z "$BRANCHES" ]
then
  git clone --mirror "$SOURCE_REPO" "$SOURCE_DIR" && cd "$SOURCE_DIR"
else
  echo "INFO: Branch mirroring only!"
  git init --bare -q target && cd target
  git remote add origin "$SOURCE_REPO"
  git config --unset-all remote.origin.fetch
  SPLIT_BRANCHES=$(echo "$BRANCHES" | tr ":" "\n")
  for BRANCH in $SPLIT_BRANCHES;
  do
    git config --add remote.origin.fetch "+refs/heads/$BRANCH:refs/remotes/origin/$BRANCH"
    git config --add remote.origin.push "+refs/remotes/origin/$BRANCH:refs/heads/$BRANCH"
  done
  git fetch --no-tags
fi

git remote set-url --push origin "$DESTINATION_REPO"
GIT_PUSH_FLAGS=""

# not much point of pruning all other branches that might be present when mirroring a single branch.
if [ -z "$BRANCHES" ]
then
  git fetch -p origin
  # Exclude refs created by GitHub for pull request.
  git for-each-ref --format 'delete %(refname)' refs/pull | git update-ref --stdin
  GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS --mirror"
else
  GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS origin"
  if [ "$FORCE_PUSH_BRANCHES" = "true" ]
  then
    echo "INFO: Force pushing the branches"
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
