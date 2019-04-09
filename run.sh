#! /bin/bash

docker run -d -it \
    -p 3000:3000 \
    --restart always \
    --name my-theia \
    -v "$(pwd):/home/project:cached" \
    -v "$(pwd)/settings.json:/home/theia/.theia/settings.json" \
    my_theia

