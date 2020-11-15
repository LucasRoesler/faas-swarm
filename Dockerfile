FROM teamserverless/license-check:0.3.9 as license-check

FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.13 as build

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

ARG NS
ARG REPO
ARG VERSION="dev"
ARG GIT_COMMIT="000000"

ENV CGO_ENABLED=0
ENV GO111MODULE=on
ENV GOFLAGS=-mod=vendor

COPY --from=license-check /license-check /usr/bin/

WORKDIR /go/src/github.com/openfaas/faas-swarm

COPY . .

RUN license-check -path /go/src/github.com/openfaas/faas-swarm/ --verbose=false "Alex Ellis" "OpenFaaS Author(s)"

RUN gofmt -l -d $(find . -type f -name '*.go' -not -path "./vendor/*")

RUN CGO_ENABLED=${CGO_ENABLED} GOOS=${TARGETOS} GOARCH=${TARGETARCH} go test -v ./...

RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} CGO_ENABLED=${CGO_ENABLED} go build \
    --ldflags "-s -w \
    -X github.com/openfaas/faas-swarm/version.GitCommit=${GIT_COMMIT}\
    -X github.com/openfaas/faas-swarm/version.Version=${VERSION}" \
    -a -installsuffix cgo -o faas-swarm .

FROM --platform=${TARGETPLATFORM:-linux/amd64} alpine:3.12 as ship

ARG REPO_URL
# Get automactic ghcr linking via the image source
# https://github.com/opencontainers/image-spec/blob/master/annotations.md#pre-defined-annotation-keys
# https://github.community/t/github-container-registry-link-to-a-repo/130336
LABEL org.label-schema.license="MIT" \
    org.label-schema.vcs-url="$REPO_URL" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.name="openfaas/faas-swarm" \
    org.label-schema.vendor="openfaas" \
    org.label-schema.docker.schema-version="1.0" \
    org.opencontainers.image.source="$REPO_URL"

RUN apk --no-cache add \
    ca-certificates

WORKDIR /root/

EXPOSE 8080

ENV http_proxy      ""
ENV https_proxy     ""

COPY --from=build /go/src/github.com/openfaas/faas-swarm/faas-swarm    .

CMD ["./faas-swarm"]
