FROM alpine
RUN apk add --update nodejs npm
ENV BASEDIR=/home/node
WORKDIR $BASEDIR
COPY . $BASEDIR
