FROM google/cloud-sdk:262.0.0-alpine
LABEL maintainer "KoopaKiller / koopakiller.com"

ARG KUBECTL_VERSION=1.18.0

RUN set -x \
  && : "installing kubectl command" \
  && curl -LO https://storage.googleapis.com/kubernetes-release/release/v"${KUBECTL_VERSION}"/bin/linux/amd64/kubectl \
  && chmod +x kubectl \
  && mv kubectl /bin

RUN set -x \
  && : "installing beta components" \
  && gcloud components install beta \
  && gcloud components update

RUN set -x \
  && : "installing cloud functions emulator" \
  && apk update \
  && apk add --no-cache \
    nodejs \
    npm \
    jq \
  && npm install -g @google-cloud/functions-framework \
  && : "clean" \
  && rm -rf /var/cache/apk/*

CMD ["gcloud"]
