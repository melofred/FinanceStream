#!/bin/bash
export GF_HOME=/Users/wmarkito/Pivotal/GemFire/sources/github/gemfire/build-artifacts/mac/product
export PATH=$GF_HOME/bin:$PATH

gfsh stop server --dir=server1
gfsh stop locator --dir=locator1






