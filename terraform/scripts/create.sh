#!/bin/sh

terraform $@ 2>&1 | tee ./terraform.log 
