#! /bin/bash

docker run -it \
    -p 3000:3000 \
    --name my-theia \
    -v "/var/www:/home/project:cached" \
    my_theia

