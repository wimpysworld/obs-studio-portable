#!/usr/bin/env bash

cd artefacts
for SHA_FILE in *.sha256; do
    sha256sum -c "${SHA_FILE}"
done
