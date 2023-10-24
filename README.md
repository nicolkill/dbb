[![GitHub release](https://img.shields.io/github/v/release/nicolkill/dbb)](https://github.com/nicolkill/dbb/releases)
[![Docker Image Size](https://img.shields.io/docker/image-size/nicolkill/dbb?sort=semver)](https://hub.docker.com/r/nicolkill/dbb "Click to view the image on Docker Hub")
[![Docker stars](https://img.shields.io/docker/stars/nicolkill/dbb.svg)](https://hub.docker.com/r/nicolkill/dbb 'DockerHub')
[![Docker pulls](https://img.shields.io/docker/pulls/nicolkill/dbb.svg)](https://hub.docker.com/r/nicolkill/dbb 'DockerHub')

## Index

- [General description](#general-description)
    - [`config.json` file example](#configjson-file-example)
- [Usage](#usage)
    - [Search (GET)](#search-get)
    - [Pagination (GET)](#pagination-get)
    - [Body (POST/PUT)](#body-postput)
- [How to run](#how-to-run)
    - [Using docker image](#using-docker-image)
        - [`docker-compose.yml` example](#docker-composeyml-example)
    - [Cloning the repo](#cloning-the-repo)
        - [Requirements](#requirements)
        - [Steps](#steps)
- [Configure](#configure)
- [Roadmap](#roadmap)

## General description

Dbb (doesn't mean nothing, it's just a sticky name) its a basic API-CRUD that provides a unique datasource oriented by 
schemas, you don't need to create your own API and create controller by controller, you just need create an container 
of this project or clone-setup this repo, configure your `config.json` file and the system it's setted up, if you need
more fields or change some field data type to another, change your config file, restart and it's done

The point of Dbb it's, if you don't want spend much time in a project, you can use Dbb as a prototype/beta backend and
if you see that your backed will need more work, you can spend the time creating the micro service or another backend 
that will contain your personal processes

The limits of this concept of project must be tested to know how much in prod can be used, but the main idea of Dbb its
just for prototypes or small/medium projects

#### `config.json` file example:

```
{
  "schemas": [
    {
      "name": "users",
      "fields": {
        "name": "string",
        "age": "number",
        "male": "boolean"
      },
      "hooks": [
        {
          "events": ["index"],
          "url": "",
          "method": "get",
          "headers": {
            "key": "value"
          }
        }
      ]
    },
    {
      "name": "products",
      "fields": {
        "name": "string",
        "expiration": "datetime"
      }
    }
  ]
}
``` 

Available data types

- [x] number
- [x] boolean
- [x] string
- [x] datetime
- [ ] map
- [ ] array
- [x] uuid
- [ ] autogenerated (string, number)

> More would be added in future updates

## Hooks

In every event it's possible call to any url, the use it's to use dbb as a data layer and external services as specific
action services

```
{
  "schemas": [
    {
      "name": "users",
      "fields": {
        "field": "string",
      },
      "hooks": [
        {
          "events": ["index"],
          "url": "",
          "method": "get",
          "headers": {
            "key": "value"
          }
        }
      ]
    }
  ]
}
```

#### Payload

Must give a JSON with 2 fields `responses` and `params`

```
{
    "params": { 
        "data": {
            "data": {
                "key": "value"
            },
            "reference": "some_internal_reference",
            "schema": "your_schema_name"
        },
        "schema": "your_schema_name"
    },
    "responses": {}
}
```

> Multiple hooks can be added to a single event
> `events: ["index", "show", "create", "update", "delete"]`

## Usage

Like all API's, exist a basic usage on how to use it, the basic routes and operations are

- `GET /:schema` - get the list of records
- `GET /:schema/:id` - get an individual record by id
- `POST /:schema` - save the record to database, using the body
- `PUT /:schema/:id` - updates the record data using the body (overrides the whole data)
- `DELETE /:schema/:id` - deletes the record data

### Search (GET)

Its possible query using your own data

The syntax its the next:

```
GET /api/v1/:schema?q=field:value                  # contains text
GET /api/v1/:schema?q=field:value;field2:value2    # multiple fields
GET /api/v1/:schema?q=field:null                   # is null or not exists
GET /api/v1/:schema?q=field:not_null               # not null or exists
```

### Pagination (GET)

The params to paginate its simple, `page` and `count`

- `page` its the number of the page
- `count` number of elements of the page

```
GET /api/v1/:schema?page=0&count=20
```

### Body (POST/PUT)
```jsmin
{
    "data": {                                                // the rule
        "your_field": "value"
    }
}
```

## Swagger

To open the Swagger UI just go to the path `api_docs/v1` and it's ready to use

## How to run:

### Using docker image

Use the public docker image [`nicolkill/dbb:latest`](https://hub.docker.com/r/nicolkill/dbb) and add the env vars listed
bellow

#### `docker-compose.yml` example

```yml
version: '3.4'
services:
  prod:
    image: nicolkill/dbb:latest
    depends_on:
      - postgres
    ports:
      - 4001:443
    volumes:
      - ./prod_test.json:/app/prod_test.json    # important add the volume
    environment:
      PORT: 443
      ALLOWED_SITES: "*"
      CONFIG_SCHEMA: prod_test.json             # must match with volume
      PHX_SERVER: true
      SECRET_KEY_BASE: example_SECRET_KEY_BASE

      # db config
      POSTGRES_USERNAME: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DATABASE: dbb_test_prod
      POSTGRES_HOSTNAME: postgres

  postgres:
    image: postgres:13.3-alpine
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_HOST_AUTH_METHOD: trust
    ports:
      - 5432:5432

```

> IMPORTANT!
> You need already created your database in the db server, migrations must be run once the server starts

### Cloning the repo 

#### Requirements

- Docker with Compose
- Maketool

#### Steps

1. Clone the repo
2. Run `make` to download deps and build docker images (runs every time that you want to reload deps or download new ones)
3. Run `make up` to run create the container and run in the `http://localhost:4000`

## Configure

The schema config exists on his own file, but the server it's configured by env vars, so here the list

```
# server config
PORT: 4000
ALLOWED_SITES: "*" # cors stuff
ALLOWED_API_KEY: "976ba520-7ea4-45cb-9e17-e7c5d922cfb2"
CONFIG_SCHEMA: config.json

# db config
POSTGRES_USERNAME: postgres
POSTGRES_PASSWORD: postgres
POSTGRES_DATABASE: postgres
POSTGRES_HOSTNAME: postgres
```

## Roadmap

- [x] Config database schema by file config
    - [x] Validate config file on startup ([map_schema_validator](https://github.com/nicolkill/map_schema_validator))
- [x] Swagger
- [x] CRUD by config
- [x] Cors configured by env var
- [x] Data validation by config
    - [x] String
    - [x] Number
    - [x] Boolean
    - [x] Datetime
    - [ ] Maps
    - [ ] Array
    - [x] UUID
    - [ ] Autogenerated by format (String)
- [x] Soft delete
- [x] Relate any record to another by a reference field
- [x] Api key by config
- [ ] Query with joins in tables
- [ ] Types of schema
    - [x] Regular tables
    - [ ] Synchronized tables (for race case conditioned)
- [x] Schema events (create, update, delete) and call a webhook by config
- [ ] Same events but call a socket
- [x] Index operations pagination
    - [x] Page number
    - [x] Count of elements per-page
- [x] Index operations filter by query params
    - [x] Contains text
    - [x] Exists the field
    - [x] Not exist the field
    - [x] Multiple query fields
    - [ ] Related fields aggregation
- [ ] Admin panel (CRUD)
    - [ ] Panel type of view's from config file
