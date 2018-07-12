FROM golang:alpine
MAINTAINER "Docker container for automated Hana DB test"

ENV TERRAFORM_VERSION=0.10.0

RUN apk add --update git bash openssh

ENV TF_DEV=true
ENV TF_RELEASE=true

WORKDIR $GOPATH/src/github.com/hashicorp/terraform
RUN git clone https://github.com/hashicorp/terraform.git ./ && \
    git checkout v${TERRAFORM_VERSION} && \
    /bin/bash scripts/build.sh

#Copy the hana terraform script
WORKDIR $GOPATH/src/single_hana_instance
# Copying the single hana master branch from local machine for now.
COPY experiment experiment
WORKDIR $GOPATH
COPY terraform_cmd.sh terraform_cmd.sh
RUN ls -l && pwd
ENTRYPOINT ["/bin/bash","terraform_cmd.sh"]


