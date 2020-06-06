#!/usr/bin/env python3
keywords = input()
keywords = keywords.split()
for keyword in keywords:
    print(f'"{keyword.lower()}"        {{ INSERT; return K_{keyword}; }}')

for keyword in keywords:
    print(f'tok_{keyword.lower()}: {keyword} | {keyword} \'\\n\';')