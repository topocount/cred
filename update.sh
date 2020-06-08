#!/bin/sh

set -eu

# requires that the user has set a SC_REPO_DIR environment variable
# and it points to a repository containing sourcecred, where `yarn backend`
# has been run to build the CLI.
# requires that this script be run from the root of the makerdao-cred repo

main() {
  if ! [ -z "$(git status --porcelain)" ]; then
    die "Git status not clean"
  fi
  DEMO_DIR=$(pwd)
  SITE_DIR="$DEMO_DIR/docs"
  if ! [ -d "${SITE_DIR}" ]; then
    die "Can't find site dir; probably running script from wrong location"
  fi

  SOURCECRED_CLI="$SC_REPO_DIR/bin/sourcecred.js"
  if ! [ -f "${SOURCECRED_CLI}" ]; then
    die "Can't find sourcecred CLI"
  fi
  export SOURCECRED_DIRECTORY="$DEMO_DIR/sourcecred_data"
  export SOURCECRED_INITIATIVES_DIRECTORY="$DEMO_DIR/initiatives"

  node "$SOURCECRED_CLI" load --project project.json --weights weights.json
  node "$SOURCECRED_CLI" scores @sourcecred > scores.json
  (cd "$SC_REPO_DIR" && yarn build --output-path "$SITE_DIR")
  mkdir -p "$SITE_DIR/api/v1"
  cp -r "$SOURCECRED_DIRECTORY" "$SITE_DIR/api/v1/data"
  rm -rf "$SITE_DIR/api/v1/data/cache"
  cp "$DEMO_DIR/CNAME" "$SITE_DIR"

  git add docs
  git add scores.json
  git commit -m "Autogenerated cred update commit"
}

die() {
    printf >&2 'fatal: %s\n' "$@"
    exit 1
}

main
