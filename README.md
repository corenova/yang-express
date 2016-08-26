# yang-express

YANG model-driven Express framework

Minimalistic web framework leveraging powerful YANG schema expressions
according to [RFC 6020](http://tools.ietf.org/html/rfc6020). Generates
dynamic model-driven interfaces with flexible plugin system.

  [![NPM Version][npm-image]][npm-url]
  [![NPM Downloads][downloads-image]][downloads-url]

## Installation

```bash
$ npm install yang-express
```

## Features

* Robust model-driven routing
* Hotplug runtime models
* Dynamic interface generators
  * [restjson](./src/restjson.coffee)
  * [websocket](./src/websocket.coffee)
  * [openapi/swagger](./src/openapi.coffee)
  * [yangapi](./src/yangapi.coffee)
* Hierarchical (deeply nested) data tree
* Adaptive validations
* Flexibe RPCs and notifications

This module also *inherits* all the features from
[Express](http://expressjs.com) and
[yang-js](http://github.com/corenova/yang-js).

## Quick Start

```coffeescript
schema = """
  module petstore {
    prefix ps;
    description "Yang Petstore";
    grouping Pet {
      leaf id   { type uint64; mandatory true; }
      leaf name { type string; mandatory true; }
      leaf tag  { type string; }
    }
    list pet { key "id"; uses Pet; }
  }
"""
app = require 'yang-express' ->
  @enable 'openapi', {
    title: 'Yang Petstore'
	description: 'Example'
	version: '0.1'
	contact: {
	  name: 'John Doe'
	  url: 'http://github.com/corenova/yang-express'
    }
	license: {
	  name: 'Apache-2.0'
	}
  }
  @enable 'yangapi'
  @enable 'restjson'
  @enable 'websocket'
  @open 'petstore', ->
    @import schema
	@on 'update', (prop, prev) -> console.log "#{prop.path} triggered update"
app.listen 5000
```

The above example *mimics* the PetStore example found inside the
[OpenAPI Specification 2.0](http://github.com/OAI/OpenAPPI-Specification)
project.

When the `yang-express` app runs, it will auto-generate the data model
using the `schema` and dynamically route the following endpoints:

endpoint        | methods          | feature   | description
---             | ---              | ---       | ---
/openapi.spec   | GET              | openapi   | openapi/swagger 2.0 specification (JSON or YAML)
/petstore.yang  | **RUMDO** + POST | yangapi   | manage YANG schema link
/socket.io      |                  | websocket | socket.io interface
/pet            | **RUMDO** + POST | restjson  | operate on the pet collection
/pet/:id        | **RUMDO**        | restjson  | operate on a specific pet
/pet/:id/:leaf  | **RUMDO**        | restjson  | operate on a pet's attribute
/pet/:leaf      | **RUMDO**        | restjson  | bulk operate attributes*

*RUMDO*: READ (GET), UPDATE (PUT), MODIFY (PATCH), DELETE, OPTIONS

Bulk operation on all matching attributes can be used to set a new
value for every matching attribute in the collection. 

Alternative API endpoints can be fully-qualified `/petstore:pet/...`
as well as prefix-qualified `/ps:pet/...`. This is the suggested
convention when using multiple models that may have namespace
conflict.

You can try this example implementation located inside the
[example/](./example) folder:

```bash
$ npm run example:petstore
```

## API

This module contains **all** the methods available inside
[Express](http://expressjs.com) instance and further override/extend
the following additional methods.

### enable (name, opts={})

This call *overloads* prior `enable` method and provides ability to
*activate* a registered/available **feature plugin** along with `opts`
for that plugin.

### disable (name)

This call *overloads* prior `disable` method and provides ability to
*deactivate* a currently *active* **feature plugin** instance.

### open (name, callback)

This new facility provides the primary mechanism to initialize a new
[Yang.Store](http://github.com/corenova/yang-js) instance inside the
[Express](http://expressjs.com) runtime and associate various YANG
model instances to be served by the `Store`.

It currently supports opening *multiple* stores internally but in most
scenarios, only one `Store` instance should be sufficient.

The `callback` if provided will be called with the `Store` instance as
the `this` context and is a convenience pattern for grouping all
`Store` related operations before it is *registered* within the
express application instance.

## Tests

To run the test suite, first install the dependencies, then run `npm
test`:
```
$ npm install
$ npm test
```

## License
  [Apache 2.0](LICENSE)

This software is brought to you by
[Corenova Technologies](http://www.corenova.com). We'd love to hear
your feedback.  Please feel free to reach me at <peter@corenova.com>
anytime with questions, suggestions, etc.

[npm-image]: https://img.shields.io/npm/v/yang-express.svg
[npm-url]: https://npmjs.org/package/yang-express
[downloads-image]: https://img.shields.io/npm/dt/yang-express.svg
[downloads-url]: https://npmjs.org/package/yang-express
