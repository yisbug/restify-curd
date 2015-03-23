mongoose = require 'mongoose'
async = require 'async'

module.exports = (server,db,modelName,schemaConfig={},options={})->
    schemaConfig.createAt = Number
    schemaConfig.random = Number
    
    schema = mongoose.Schema schemaConfig
    Model = db.model modelName,schema

    route = require('./route') Model

    opts = 
        list:true
        post:true
        get:true
        put:true
        patch:true
        del:true
    opts[k]=v for k,v of options

    opts.list and server.get "/#{modelName}",route.doGetList
    opts.post and server.post "/#{modelName}",route.doPost
    opts.get and server.get "/#{modelName}/:id",route.doGet
    opts.put and server.put "/#{modelName}/:id",route.doEdit
    opts.patch and server.patch "/#{modelName}/:id",route.doEdit
    opts.del and server.del "/#{modelName}/:id",route.doDelete
    {
        Model:Model
    }
