#!/bin/sh

set -e

export GIT_SSH_COMMAND="ssh -v"

echo "SOURCE=$INPUT_SOURCE_REPO"
echo "DESTINATION=$DINPUT_ESTINATION_REPO"
echo "BRANCHES=$INPUT_BRANCHES"
echo "FORCE PUSH BRANCHES=$INPUT_FORCE_PUSH_BRANCHES"
echo "DRY RUN=$INPUT_DRY_RUN"

SOURCE_DIR=$(basename "$INPUT_SOURCE_REPO")

if [ -n "$SSH_PRIVATE_KEY" ]
then
  mkdir -p /root/.ssh
  echo "$SSH_PRIVATE_KEY" > /root/.ssh/id_rsa
  chmod 600 /root/.ssh/id_rsa
fi

if [ -n "$SSH_KNOWN_HOSTS" ]
then
  mkdir -p /root/.ssh
  echo "StrictHostKeyChecking yes" >> /etc/ssh/ssh_config
  echo "$SSH_KNOWN_HOSTS" > /root/.ssh/known_hosts
  chmod 600 /root/.ssh/known_hosts
else
  echo "WARNING: StrictHostKeyChecking disabled"
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
fi


if [ -z "$INPUT_BRANCHES" ]
then
  git clone --mirror "$INPUT_SOURCE_REPO" "$SOURCE_DIR" && cd "$SOURCE_DIR"
else
  echo "INFO: Branch mirroring only!"
  git init --bare -q target && cd target
  git remote add origin "$INPUT_SOURCE_REPO"
  git config --unset-all remote.origin.fetch
  SPLIT_BRANCHES=$(echo "$INPUT_BRANCHES" | tr ":" "\n")
  for BRANCH in $SPLIT_BRANCHES;
  do
    git config --add remote.origin.fetch "+refs/heads/$BRANCH:refs/remotes/origin/$BRANCH"
    git config --add remote.origin.push "+refs/remotes/origin/$BRANCH:refs/heads/$BRANCH"
  done
  git fetch --no-tags
fi

git remote set-url --push origin "$INPUT_DESTINATION_REPO"
GIT_PUSH_FLAGS=""

# not much point of pruning all other branches that might be present when mirroring a single branch.
if [ -z "$INPUT_BRANCHES" ]
then
  git fetch -p origin
  # Exclude refs created by GitHub for pull request.
  git for-each-ref --format 'delete %(refname)' refs/pull | git update-ref --stdin
  GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS --mirror"
else
  GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS origin"
  if [ "$INPUT_FORCE_PUSH_BRANCHES" = "true" ]
  then
    echo "INFO: Force pushing the branches"
    GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS --force"
  fi
fi

if [ "$INPUT_DRY_RUN" = "true" ]
then
    echo "INFO: Dry Run, no data is pushed"
    GIT_PUSH_FLAGS="$GIT_PUSH_FLAGS --dry-run"
fi

echo "final git command: 'git push $GIT_PUSH_FLAGS'"
git push $GIT_PUSH_FLAGS
