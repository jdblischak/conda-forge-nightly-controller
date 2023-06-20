#!/bin/bash
set -eu

# Attempt to locally replicate GitHub Actions workflow
#
# Usage: bash run-local-tiledb-vcf.sh [TRUE/FALSE]
#
# Pass argument TRUE to push changes to feedstocks
#
# Requires SSH keys for an account that has push access to feedstock repos
#
# Requires mamba
#
# Run from root of nightlies repo

PUSH="${1-FALSE}"
echo "Push to GitHub: $PUSH"
export TZ="America/New_York"

rm -rf tiledb-vcf-feedstock
git clone --quiet --depth 1 git@github.com:TileDB-Inc/tiledb-vcf-feedstock.git tiledb-vcf-feedstock

rm -rf TileDB-VCF
git clone --quiet git@github.com:TileDB-Inc/TileDB-VCF.git TileDB-VCF

bash scripts/obtain-date.sh

# Note: re-using same conda env as TileDB. Just need conda-smithy since `python
# setup.py --version` gives an outdated version string
if conda env list | grep -q "env-nightlies-tiledb\s"
then
  echo "Conda env already exists: env-nightlies-tiledb"
else
  echo "Installing conda env 'env-nightlies-tiledb'"
  mamba create --yes --quiet -n env-nightlies-tiledb \
    -c conda-forge --override-channels \
    conda-smithy
fi
source activate env-nightlies-tiledb
mamba update --yes --quiet conda-smithy

# Skipping this. Version bumps are rare and associated with new releases,
# so using the version in the recipe is fine 
#bash scripts/tiledb-py/obtain-version.sh
bash scripts/obtain-commit.sh TileDB-VCF
# There is no upstream conda-forge feedstock for TileDB-VCF
# bash scripts/pull-upstream-feedstock.sh tiledb-vcf-feedstock
bash scripts/tiledb-vcf/update-recipe.sh
# only need to change upload channel label
bash scripts/update-channels.sh tiledb-vcf-feedstock
bash scripts/add-and-commit.sh tiledb-vcf-feedstock

bash scripts/rerender-feedstock.sh tiledb-vcf-feedstock
source deactivate

if [[ "$PUSH" == "TRUE" || "$PUSH" == "True" || "$PUSH" == "true" ]]
then
  echo "Pushing to GitHub"
  bash scripts/push-update.sh tiledb-vcf-feedstock
else
  echo "Did **not** push to GitHub"
fi
