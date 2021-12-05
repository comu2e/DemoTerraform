#! bin/bash
colordiff src/$1/main.tf src/$2/main.tf
colordiff src/$1/variables.tf src/$2/variables.tf
colordiff src/$1/output.tf src/$2/output.tf     