#!/usr/bin/env bash

echo "$1"

./javaa "$1.jasm"

java $1
