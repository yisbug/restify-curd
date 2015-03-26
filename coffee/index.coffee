mongoose = require 'mongoose'
async = require 'async'

module.exports = (server,Model,options={})->
    Model.schema.add createAt:Number
    Model.schema.add random:Number

    route = require('./route') Model

    methods = ['list','post','get','put','patch','del','delAll']

    opts = 
        path:Model.modelName
        childs:[]
    opts[k]=true for k in methods
    opts[k]=v for k,v of options

    opts.list and server.get "/#{opts.path}",route.doGetList
    opts.post and server.post "/#{opts.path}",route.doPost
    opts.get and server.get "/#{opts.path}/:id",route.doGet
    opts.put and server.put "/#{opts.path}/:id",route.doEdit
    opts.patch and server.patch "/#{opts.path}/:id",route.doEdit
    opts.del and server.del "/#{opts.path}/:id",route.doDelete
    opts.delAll and server.del "/#{opts.path}",route.doDeleteAll

    childs = opts.childs
    childs=[childs] if not Array.isArray(childs)
    for child in childs
        child[k]=true for k in methods when typeof child[k] is 'undefined'
        route = require('./route') Model,child.path
        path = '/:'+child.path + 'id'
        child.list and server.get "/#{opts.path}/:id/#{child.path}",route.doGetList
        child.post and server.post "/#{opts.path}/:id/#{child.path}",route.doPost
        child.get and server.get "/#{opts.path}/:id/#{child.path}"+path,route.doGet
        child.put and server.put "/#{opts.path}/:id/#{child.path}"+path,route.doEdit
        child.patch and server.patch "/#{opts.path}/:id/#{child.path}"+path,route.doEdit
        child.del and server.del "/#{opts.path}/:id/#{child.path}"+path,route.doDelete
        child.delAll and server.del "/#{opts.path}/:id/#{child.path}",route.doDeleteAll
    {
        Model:Model
    }
