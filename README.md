# Dbb

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

## Features

- [x] Config database schema by file config
- [x] CRUD by config
- [x] Cors configured by env var
- [x] Data validation by config
- [x] Soft delete
- [x] Relate any record to another by a reference field
- [x] Api key by config
- [ ] General search on schema fields
- [ ] Schema events (create, update, delete) and call a webhook by config
- [ ] Same events but call a socket

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
      }
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

- number
- boolean
- string
- datetime

more would be added in future updates

## How to run:

### Using docker image

Use the public docker image `nicolkill/dbb:latest` and add the env vars listed bellow

#### Consider

You need already created your database in the db server

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
