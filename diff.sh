#bin/sh
colordiff env/$1/main.tf env/$2/main.tf
colordiff env/$1/variables.tf env/$2/variables.tf
colordiff env/$1/output.tf env/$2/output.tf     