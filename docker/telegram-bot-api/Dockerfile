# creates a layer from the base Docker image.
FROM alpine:3.7

RUN apk update && \
  apk upgrade

RUN apk add --update \
    alpine-sdk \
    libstdc++ \
    linux-headers \
    git \
    zlib-dev \
    openssl \
    openssl-dev \
    gperf \
    php7 \
    php7-ctype \
    cmake && \
  git clone --recursive https://github.com/tdlib/telegram-bot-api.git && \
  cd telegram-bot-api && \
  rm -rf build && \
  mkdir build && \
  cd build && \
  export CXXFLAGS="" && \
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=.. .. && \
  cmake --build . --target prepare_cross_compiling && \
  cmake --build . --target install && \

  cd ../.. && \
  ls -l /telegram-bot-api/bin/telegram-bot-api*

WORKDIR /app

RUN cp /telegram-bot-api/bin/telegram-bot-api /usr/bin/telegram-bot-api
COPY . .

RUN chmod a+x docker-entrypoint.sh

# ENTRYPOINT ["./docker-entrypoint.sh"]
ENTRYPOINT ["telegram-bot-api", "--local", "--http-port=8009", "--verbosity=10", "--temp-dir=/tmp/tgbot", "--log=/dev/stdout" ]


