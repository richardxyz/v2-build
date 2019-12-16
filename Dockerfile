FROM golang:latest as builder

MAINTAINER Richard Xie

RUN go get -insecure -u v2ray.com/core/... \
	&& mkdir -p /usr/bin/v2ray/ \
	&& apt -qy install curl \
	&& curl https://bazel.build/bazel-release.pub.gpg |  apt-key add - \
	&& echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list \
	&& apt update \
	&& apt -qy install bazel \
	&& rm -rf /var/lib/apt/lists/* 



#RUN CGO_ENABLED=0 go build -o /usr/bin/v2ray/v2ray v2ray.com/core/main
#RUN CGO_ENABLED=0 go build -o /usr/bin/v2ray/v2ctl v2ray.com/core/infra/control/main
#RUN cp -r ${GOPATH}/src/v2ray.com/core/release/config/* /usr/bin/v2ray/

#FROM alpine

#RUN apk update
#RUN apk upgrade
#RUN apk add ca-certificates && update-ca-certificates
## Change TimeZone
#RUN apk add --update tzdata
#ENV TZ=Asia/Shanghai
## Clean APK cache
#RUN rm -rf /var/cache/apk/*

#RUN mkdir /usr/bin/v2ray/
#RUN mkdir /etc/v2ray/
#RUN mkdir /var/log/v2ray/

#COPY --from=builder /usr/bin/v2ray  /usr/bin/v2ray

#ENV PATH /usr/bin/v2ray/:$PATH

#EXPOSE 8000
#COPY config.json /etc/v2ray/config.json

#CMD ["/usr/bin/v2ray/v2ray", "-config=/etc/v2ray/config.json"]