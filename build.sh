#!/bin/sh
# Собирает шейдерпак в zip, который кладётся в .minecraft/shaderpacks
set -e
cd "$(dirname "$0")"
rm -f Backrooms-Shaders.zip
zip -r -q Backrooms-Shaders.zip shaders
echo "Готово: Backrooms-Shaders.zip"
