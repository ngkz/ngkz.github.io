#!/usr/bin/env bash
set -euo pipefail

hugo
tar -Jcvf public.tar.xz public
