# Use NodeJS LTS Slim image
FROM node:lts-slim

# Create app directory 
WORKDIR /data
VOLUME /data

# Define input file name
ENV INPUT="my5grantester_logs.txt"

# Define output file name
ENV OUTPUT="my5grantester_logs.csv"

# Run JS file with Node
CMD [ "node", "parse_tester_logs.js $INPUT $OUTPUT"]

# How to run:
# docker build . -t lando/my5grantester-logs-parser
# docker run --name my5grantester-logs-parser -e INPUT="" -e OUTPUT="" -v $(pwd)/data:/data lando/my5grantester-logs-parser
