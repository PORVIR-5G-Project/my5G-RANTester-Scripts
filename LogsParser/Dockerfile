# Use NodeJS LTS Slim image
FROM node:lts-slim

# Create app directory
WORKDIR /data
VOLUME /data

# Define script file name
ENV SCRIPT="parse_tester_logs.js"

# Define input file name
ENV INPUT="my5grantester_logs.txt"

# Define output file name
ENV OUTPUT="my5grantester_logs.csv"

# Run JS file with Node
CMD [ "sh", "-c", "node ${SCRIPT} ${INPUT} ${OUTPUT}"]

# How to run:
# docker build . -t lando/my5grantester-logs-parser
# docker run --rm -e SCRIPT="" -e INPUT="" -e OUTPUT="" -v $(pwd)/data:/data lando/my5grantester-logs-parser