'use strict'

const Yang = require('yang-js')
const Schema = require('./yang-express.yang')
const Config = require('config')

const express = require('express')
const os = require('os')

module.exports = Schema.bind({

  "feature(express)": function() {
    if (!this.content) this.content = express()
    return this.content
  },
  "feature(restjson)":  require('../lib/restjson'),
  "feature(openapi)":   require('../lib/openapi'),
  "feature(websocket)": require('../lib/websocket'),
  "/express:server": {
    hostname() {
      if (!this.content) this.content = os.hostname()
      return this.content
    }
  },
  "/express:run": function() {
    const { features = [], modules = [] } = this.input
    const { express: app } = this.instance

    if (!features.length)
      this.throw('cannot run without any features enabled')

    this.in('/express:server').merge(this.input)
    for (let feature in features)
      this.enable(feature)

    modules.forEach((name) => {
      let m
      this.debug(`import/route ${name}`)
      try {
        m = this.access(name)
      } 
      catch(e) {
        try {
          m = this.schema.constructor.import(name).eval(Config)
        } 
        catch(e) {
          console.error(e)
          this.throw(`unable to import '${name}' YANG module, check your local 'package.json' for yang.resolve`)
        }
      }
      this.in('/express:server/router').create({ name: m.name })
    })
    let server = this.get('/express:server')
    if (!server.router || !server.router.length)
      this.throw("cannot run without any modules to route")

    this.output = new Promise((resolve, reject) => {
      let http = app.listen(server.port)
      http.on('listening', () => {
        this.debug(`running on ${server.port}`)
        app.emit('listening', http)
        resolve(server)
      })
    })
  }
})
