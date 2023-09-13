#!/bin/bash

# Copied from: https://gitlab.inria.fr/formations/cpp/gettingstartedwithmoderncpp/
# This file is expected to be use as pre-commit git hook; copy it in .git/hooks/
echo "This gets called"
file_list=`ls notebooks/*ipynb`
#`git diff --diff-filter=ACM --name-only`

for file in ${file_list}
do
  if [ "${file##*.}" = "ipynb" ]; then
    echo "Converting ${file} to markdown"
    jupyter nbconvert --to markdown ${file}

    export new_name=$(basename -- "$file")
    export new_name="${new_name%.*}"

    sed -i "s/${new_name}_files/..\/images\/${new_name}_files/" notebooks/${new_name}.md

    mv notebooks/${new_name}.md _posts/${new_name}.md
    rsync -a notebooks/${new_name}_files images/${new_name}_files

    git add _posts/${new_name}.md
    git add images/${new_name}_files/*
  fi
done
