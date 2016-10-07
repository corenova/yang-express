# yang-express

YANG model-driven Express framework

Minimalistic web framework leveraging powerful YANG schema expressions
according to [RFC 6020](http://tools.ietf.org/html/rfc6020). Generates
dynamic model-driven interfaces with flexible plugin system.

  [![NPM Version][npm-image]][npm-url]
  [![NPM Downloads][downloads-image]][downloads-url]

## Installation

```bash
$ npm install -g yang-express
```
The preferred installation is *global* for easy access to the
`yang-express` utility but can also be used as a dependency module to
enable YANG model-driven express app as part of your project.

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

```bash
$ yang-express example/example-petstore.yang
```

The above example will import the `example-petstore` YANG module and
start an instance of `yang-express` listening on port 5000 with
`restjson` feature enabled.

```
  Usage: yang-express [options] modules...

  Options:
      -p, --port <number>    Run yang-express on <port> (default: 5000)
      -f, --feature <name>   Enable one or more features: (restjson, openapi, etc.)
```

You can run `yang-express` inside your own project and it will
dynamically import one or more `modules` and route them using the
`feature` plugins specified.

You can also use it as a library module:

```coffeescript
require 'yang-js'
opts =
  port: 5000
  feature: [ 'restjson', 'openapi' ]
  modules: [ 'ietf-yang-library' ]
express = require('yang-express').eval()
express.in('run')
  .invoke opts
  .then  (res) -> console.log "running"
  .catch (err) -> console.error err
```

For more information on programmatic usage, be sure to take a look at
the References listed below.

## References

This module is a YANG model-driven data module, which is essentially a
composition of the [YANG Schema](./yang-express.yang) and
[Control Binding](./src/yang-exress.coffee).  It is designed to model
middleware routing runtime configuration and can be utilized with or
without an actual [Express](http://expressjs.com) instance.

- [Apiary Documentation](http://docs.yangexpress.apiary.io)
- [Using YANG with JavaScript](http://github.com/corenova/yang-js)
- [Using Model API](http://github.com/corenova/yang-js#model-instance)

## Examples

**PetStore** is a simple example based on the provided spec sample in the
[OpenAPI Specification 2.0](http://github.com/OAI/OpenAPPI-Specification)
project.

```bash
$ npm run example:petstore
```

When the `yang-express` app runs, it will auto-generate the data model
using the [example-petstore.yang](./example/example-petstore.yang)
schema and dynamically route the following endpoints utilizing the
[restjson](./src/feature/restjson.coffee) dynamic interface
generator:

endpoint        | methods    | description
---             | ---        | ---
/pet            | **CRUMDO** | operate on the pet collection
/pet/:id        | **RUMDO**  | operate on a specific pet
/pet/:id/:leaf  | **RUMDO**  | operate on a pet's attribute
/pet/:leaf      | **RUMDO**  | bulk operate attributes*

This example runs using the
[sample data](./config/example-petstore.yaml) found inside the
`config` directory.

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
