FROM --platform=linux/aarch64 ubuntu:22.04

RUN apt update && apt install -y ca-certificates && apt clean
COPY edge /
CMD /edge --name RaspberryPi4B