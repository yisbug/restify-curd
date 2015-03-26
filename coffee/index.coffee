mongoose = require 'mongoose'
async = require 'async'

module.exports = (server,Model,options={})->
    Model.schema.add createAt:Number
    Model.schema.add random:Number

    route = require('./route') Model

    opts = 
        list:true
        post:true
        get:true
        put:true
        patch:true
        del:true
        path:Model.modelName
    opts[k]=v for k,v of options

    opts.list and server.get "/#{opts.path}",route.doGetList
    opts.post and server.post "/#{opts.path}",route.doPost
    opts.get and server.get "/#{opts.path}/:id",route.doGet
    opts.put and server.put "/#{opts.path}/:id",route.doEdit
    opts.patch and server.patch "/#{opts.path}/:id",route.doEdit
    opts.del and server.del "/#{opts.path}/:id",route.doDelete
    {
        Model:Model
    }
