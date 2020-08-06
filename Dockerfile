FROM golang:latest as builder

MAINTAINER Richard Xie

RUN go get -insecure -u v2ray.com/core/... \
	&& mkdir -p /v2ray/zip \
	&& wget  https://bazel.build/bazel-release.pub.gpg -O - |  apt-key add - \
	&& echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
	&& apt update \
	&& apt -qy install bazel xz-utils \
	&& cd /tmp \
	&& wget -c https://github.com/upx/upx/releases/download/v3.95/upx-3.95-amd64_linux.tar.xz \
	&& tar -Jxf upx-3.95-amd64_linux.tar.xz \
	&& cp upx-3.95-amd64_linux/upx  ${GOPATH}/bin/ \
	&& rm -rf /tmp/upx* \
	&& cd ${GOPATH}/src/v2ray.com/core/ \
	&& sed -i 's/_ "v2ray.com\/core\/main\/json"/\/\/ &/g; s/\/\/ _ "v2ray.com\/core\/main\/jsonem"/_ "v2ray.com\/core\/main\/jsonem"/g' main/distro/all/all.go \
	&& bazel clean \
	&& export HOME=/v2ray/zip \
	&& bazel build --action_env=PATH=$PATH --action_env=SPWD=$PWD --action_env=GOPATH=$(go env GOPATH) --action_env=GOCACHE=$(go env GOCACHE) --spawn_strategy local //release:v2ray_linux_mips32le_package \
	&& cd  /v2ray/zip \
	&& find / -name "v2ray*zip" \
	&& unzip v2ray-linux-mips32le.zip  && ls -l \
	&& upx -k --best --lzma -o /v2ray/v2ray v2ray_softfloat \
	&& cd /v2ray \
	&& md5sum v2ray >v2ray.md5 \
	&& grep -oP "(?<=version  = \").+?(?=\")" ${GOPATH}/src/v2ray.com/core/core.go >version.txt \ 
	&& cd ${GOPATH}/src/v2ray.com/core/ \
	&& cat main/distro/all/all.go \
	&& bazel clean \
	&& rm -rf /var/lib/apt/lists/* 

FROM alpine

RUN mkdir /dist
COPY --from=builder /v2ray /dist
