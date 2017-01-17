#!/bin/sh

umask "${UMASK}"
echo "umask: $(umask -S)"

exec $@
