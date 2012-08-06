require './support/spec_helper'
mongoose = require 'mongoose'


describe "Calls pre 'save' on invalid embedded doc", ->
  Child = Parent = null
  beforeEach ->
    childSchema = new mongoose.Schema
      name: type: String
    childSchema.path('name').validate (v) ->
      return v in ['foo', 'bar']
    , "name in list"
    childSchema.pre 'save', (next) ->
      throw "pre 'save' should not be called"
    Child = mongoose.model 'C', childSchema

    parentSchema = new mongoose.Schema
      children: [childSchema]
    Parent = mongoose.model 'P', parentSchema

  it "calls save on invalid child", (done) ->
    spyOn(Child.prototype, 'save')
    child = new Child(name: 'baz')
    parent = new Parent children: [child]
    parent.save (err) ->
      expect(err).toBeTruthy()
      expect(Child.prototype.save).not.toHaveBeenCalled()
      done()
