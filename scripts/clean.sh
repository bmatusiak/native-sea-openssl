#!/usr/bin/env bash
set -euo pipefail

# Default to dry-run unless -y/--yes passed
DRY_RUN="--dry-run"
for arg in "$@"; do
	if [ "$arg" = "-y" ] || [ "$arg" = "--yes" ]; then
		DRY_RUN=""
		break
	fi
done

if [ -z "$DRY_RUN" ]; then
	echo "Running for git 'clean -fdX'."
else
	echo "Dry run 'clean -fdX --dry-run': Pass -y to apply."
fi

git clean -fdX $DRY_RUN