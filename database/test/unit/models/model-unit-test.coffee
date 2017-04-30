assert = require 'assert'
_ = require 'lodash'
proxyquire = require 'proxyquire'

mockDbHelpers = {}
mockDb = {}
Model = null
model = null

describe "model unit test", ->
  beforeEach ->
    Model = proxyquire('../../../models/model', {'../lib/rethinkdb-client': mockDb, 'dbHelpers': mockDbHelpers})
    model = new Model()

  describe "remove", ->
    it "Should remove the item from the array", ->
      model.data =
        nums: ['2', '3', '5', '6']
      model.remove('nums', '3')
      assert.deepEqual(model.data.nums, ['2', '5', '6'])

  describe "sanitize", ->
    beforeEach ->
      model.tableName = 'users'

    it "Should replace missing fields with default ones", ->
      info = {id: "123"}
      sanitizedInfo = model.sanitize(info)
      assert sanitizedInfo
      assert sanitizedInfo.email?
      assert sanitizedInfo.username?

    it "Should remove fields that are not in the schema", ->
      info = {id: "123", notInHere: "mewmew"}
      sanitizedInfo = model.sanitize(info)
      assert sanitizedInfo
      assert sanitizedInfo.id?
      assert !sanitizedInfo.notInHere?

  describe "save", ->
    it "Should work without a callback", ->
