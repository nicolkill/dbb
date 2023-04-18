IMAGE_TAG := nicolkill/dbb
REVISION := $(shell git rev-parse --short HEAD)
RUN_STANDARD := docker run --rm -v `pwd`:/app -w /app hexpm/elixir:1.14.4-erlang-25.3-alpine-3.17.2

all: build image

up:
	docker compose up

build:
	$(RUN_STANDARD) sh -c 'apk update && apk add --no-cache git build-base linux-headers \
								&& echo "#include <unistd.h>" > /usr/include/sys/unistd.h \
                           		&& mix do local.rebar --force, local.hex --force, \
                           		deps.get, \
                           		deps.compile --force, \
                           		compile --plt'

image:
	docker build -f Dockerfile.dev -t ${IMAGE_TAG}:${REVISION} .
	docker tag ${IMAGE_TAG}:${REVISION} ${IMAGE_TAG}:latest

testing:
	docker compose run --rm -e "MIX_ENV=test" app mix test

iex:
	docker compose exec app iex -S mix

bash:
	docker compose run --rm app sh

routes:
	docker compose exec app mix phx.routes

rollback:
	docker compose exec app mix ecto.rollback

migrate:
	docker compose exec app mix ecto.migrate

format:
	docker compose exec app mix format
