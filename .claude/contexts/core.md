# Core of the app

## Concept

the application objective its have a dynamic complete system, and instead have a lot of different tables its just one
named `table` that contains `schema` (the name) and `data` (the information) and when you insert schema type with
defined values, on the config `.json` file must check the schema name exists and the values has the right format
to allow/deny the action

## Schema

its a basic json file that contains all the configuration for the entire application, the central point off all,
if you need a change in the entire app you need to modify this file, changes are applied on startup

```json
{
  // for ui changes
  "ui": {
    "title": "example title"
  },
  // the data model, different value types
  "schemas": [
    {
      "name": "user_accounts",
      // key and value type of the value, works to validate the inputs
      "fields": {
        "email": "string",
        "name": "string",
        "last_name": "string",
        "age": "number",
        "male": "boolean",
        "birth": "datetime",
        "flags": ["string"]
      },
      // this are called once an action its performed
      "hooks": [
        {
          "events": ["create"],
          "url": "https://someurl.test/webhook",
          "method": "post",
          "headers": {
            "custom_header": "header value"
          }
        }
      ]
    },
    {
      "name": "orders",
      "fields": {
        // this id is for a relation, here defines the field name
        "user_id": "string",
        "estimated_delivery_time": "datetime"
      },
      "relations": {
        // here its defined the other schema name, always referes to the id of the record on database
        "user_id:mandatory": "user_accounts"
      }
    }
  ]
}
```

## Database Table

its just one Schema (database table) that its the `lib/dbb/content/table.ex` file and on that file just must contain the
database info like fields, type of values and how to transform external data to the ecto changeset that its the
one that inserts the values to the database

as mentioned before, has 2 important fields `schema` and `data` but has another implicit field that its the `id`
and its a `uuid` and mentioned in the json format when an schema has a relation to other, in all cases, uses
this implicit id of the record on database

## Database actions

all database queries (any type of action) its managed on `lib/dbb/content.ex` file, so the data layer its this file

## Validations

are performed on the `lib/dbb/schema_manager/value_validator.ex` file, basically checks inputs and compares with the
format in the json file of config

## Handler

all on the `lib/dbb/schema_manager/table_handler.ex` file, this is one of the core parts because uses the previous 
mentioned topic, call a function, get the data, validate format and value types and then performs the database action,
calls the webhooks if are configured and returns the result of the action

## API

all the actions are called by `lib/dbb/schema_manager/table_api.ex` file that contains all the basic actions that can
be performed like `index` (get all elements with pagination), so this file uses the "Database actions" and not deals
with part of the process actions like validations

> History: on previous changes all was performed directly on the api controller but once the frontend part was added,
> this api file was created to centralize that controller or frontend calls the same function and performs the same
> side actions (webhooks)

## Controller

The external API layer, all request are here, located on `lib/dbb_web/controllers/table/table_controller.ex` file with
`lib/dbb_web/controllers/table/table_json.ex` as isolated responses formats


