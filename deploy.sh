#!/usr/bin/env bash
set -euo pipefail

mkdir -p build
echo "Signature: 8a477f597d28d172789f06886806bc55" >build/CACHEDIR.TAG
hugo -d build/public
tar -Jcvf build/public.tar.xz -C build public
