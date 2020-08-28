#!/bin/sh
clang -arch x86_64 -framework Foundation -lobjc main.m -o inject_lib
