mongoose = require 'mongoose'
async = require 'async'

module.exports = (server,Model,options={})->
    Model.schema.add createAt:Number
    Model.schema.add random:Number
    methods = ['list','post','get','put','patch','del','delAll']
    opts = 
        path:Model.modelName
        childs:[]
    opts[k]=v for k,v of options

    addRoute = (config,ids=[])->
        copyIds = (k for k in ids)
        copyIds.push config.path
        len = copyIds.length
        basePathID = basePath = ''
        for id,k in copyIds
            basePath =  "#{basePathID}/#{id}" if k is len-1
            basePathID+="/#{id}/:#{id}id"            


        route = require('./route') Model,copyIds
        # 初始化各方法初始值，默认均为true
        config[k]=true for k in methods when typeof config[k] is 'undefined'


        config.list and server.get basePath,route.doGetList
        config.post and server.post basePath,route.doPost
        config.get and server.get basePathID,route.doGet
        config.put and server.put basePathID,route.doEdit
        config.patch and server.patch basePathID,route.doEdit
        config.del and server.del basePathID,route.doDelete
        config.delAll and server.del basePath,route.doDeleteAll

        # 处理内嵌文档
        childs = config.childs
        return if not childs
        childs = [childs] if not Array.isArray(childs)
        return if childs.length<1
        for child in childs
            addRoute child,copyIds

    addRoute opts,[]

    {
        Model:Model
    }
