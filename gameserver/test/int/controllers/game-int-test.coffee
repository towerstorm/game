app = require('../../../lib/app.coffee')
request = require("supertest")(app)
_ = require 'lodash'
assert = require 'assert'

describe "create", ->

