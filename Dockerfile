FROM hexpm/elixir:1.14.4-erlang-25.3-alpine-3.17.2 AS build

# install build dependencies
RUN apk add --no-cache build-base \
    linux-headers \
    git

RUN echo "#include <unistd.h>" > /usr/include/sys/unistd.h

WORKDIR /app

ARG MIX_ENV
ENV MIX_ENV $MIX_ENV
RUN echo "MIX_ENV ==> $MIX_ENV"

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force


# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

COPY priv priv
RUN mix phx.digest

# compile and build release
COPY lib lib
COPY assets assets
# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, assets.build, assets.deploy, release

FROM alpine:3.17.0 AS app
RUN apk add --no-cache \
    openssl \
    ncurses-libs \
    build-base \
    linux-headers \
    make \
    git \
    curl

RUN echo "#include <unistd.h>" > /usr/include/sys/unistd.h

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody
ARG MIX_ENV
ENV MIX_ENV $MIX_ENV
RUN echo "MIX_ENV ==> $MIX_ENV"

COPY --from=build --chown=nobody:nobody /app/_build/$MIX_ENV/rel ./

ENV HOME=/app
EXPOSE 4000
EXPOSE 443

CMD /app/dbb/bin/dbb start
