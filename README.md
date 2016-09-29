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
* [Dynamic interface generators](#dynamic-interface-generators)
* Hierarchical (deeply nested) data tree
* Adaptive validations
* Flexibe RPCs and notifications

This module also *inherits* all the features from
[Express](http://expressjs.com) and
[yang-js](http://github.com/corenova/yang-js).

## Quick Start

Create a YANG schema [petstore.yang](./example/petstore.yang):

```
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
```

Create a new [Express](http://expressjs.com) app:

```coffeescript
require 'yang-js'

data = require('./example/petstore.json')
petstore = require('./example/petstore.yang').eval(data)
express = require('yang-express').eval {
  'yang-express:server':
    router: [
	  { name: 'petstore' }
	]
}
express.enable 'restjson'
express.in('run').invoke port: 5000
  .then  (res) -> console.log "running"
  .catch (err) -> console.error err
```

The above example *mimics* the PetStore example found inside the
[OpenAPI Specification 2.0](http://github.com/OAI/OpenAPPI-Specification)
project.

When the `yang-express` app runs, it will auto-generate the data model
using the [petstore.yang](./example/petstore.yang) schema and
dynamically route the following endpoints utilizing the
[restjson](./src/restjson.litcoffee) dynamic interface generator:

endpoint        | methods    | description
---             | ---        | ---
/pet            | **CRUMDO** | operate on the pet collection
/pet/:id        | **RUMDO**  | operate on a specific pet
/pet/:id/:leaf  | **RUMDO**  | operate on a pet's attribute
/pet/:leaf      | **RUMDO**  | bulk operate attributes*

You can try this example implementation located inside the
[example/](./example) folder via:

```bash
$ npm run example:petstore
```

### CRUMDO

- C: CREATE (POST)
- R: READ (GET)
- U: UPDATE (PUT)
- M: MODIFY (PATCH)
- D: DELETE
- O: OPTIONS

Alternative API endpoints can be fully-qualified `/petstore:pet/...`
as well as prefix-qualified `/ps:pet/...`. This is the suggested
convention when using multiple models that may have namespace
conflict (if mounted together at '/').

**Note**: Bulk operation on all matching attributes can be used to set a new
value for every matching attribute in the collection. 

## Dynamic Interface Generators

name | description
--- | ---
[restjson](./src/feature/restjson.coffee)   | REST/JSON API
[openapi](./src/feature/openapi.coffee)     | OpenAPI/Swagger 2.0 spec
[websocket](./src/feature/websocket.coffee) | [socket.io](http://socket.io)

## API

This module is a YANG model-driven data module, which is essentially a
composition of the [YANG Schema](./schema/yang-express.yang) and
[Control Binding](./src/yang-exress.coffee).  It is designed to model
middleware routing runtime configuration and can be utilized with or
without an actual [Express](http://expressjs.com) instance.

For information on operations available on this module, please refer
to [yang-js Model API](http://github.com/corenova/yang-js#model-instance)
documentation.

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
