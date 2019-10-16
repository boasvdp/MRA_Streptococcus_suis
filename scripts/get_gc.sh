#!/bin/bash
seqtk comp $1 | awk '{gc += ($4 + $5)} {at += ($3 + $6)} END {print gc/(gc + at)}'
