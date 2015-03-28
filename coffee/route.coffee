mongoose = require 'mongoose'
async = require 'async'
# 参数:model,内嵌文档的字段名

module.exports = (Model,ids=[])->
    copyIds = (k for k in ids)
    parentName = Model.modelName # 模型名称
    # baseNameOfID = "#{ids[0]}id"
    baseId = copyIds[0]+'id'
    lastId = copyIds[copyIds.length-1]+'id'
    prevId = copyIds[copyIds.length-2]+'id'

    # 获取基础查询条件
    getBaseQuery = (req)->
        baseQuery = {}
        baseQuery._id = req.params[baseId]
        if copyIds.length>2
            baseQuery[copyIds[1..-2].join('.')+'._id'] = req.params[prevId]
        baseQuery

    # 获取详细查询条件
    getMoreQuery = (req)->
        baseQuery = {}
        for id,i in copyIds
            head = copyIds[1..i].join('.')
            if head then head+='._id' else head = '_id'
            baseQuery[head] = req.params[id+'id']
        baseQuery


    # 获取基础返回结果
    getBaseResult = (req,doc)->
        result = doc
        if copyIds.length>2
            for id in copyIds[1..-2]
                result = result[id].id(req.params[id+'id'])
        result

    # 获取详细返回结果
    getMoreResult = (req,doc)->
        result = doc
        if copyIds.length>1
            for id in copyIds[1..]
                result = result[id].id(req.params[id+'id'])
        result
    # 获取基础的列表数据
    getBaseList = (req,doc)->
        result = doc
        if copyIds.length is 2
            return result[copyIds[1]]
        else
            for id in copyIds[1..-2]
                result = result[id].id(req.params[id+'id'])
            return result[copyIds[copyIds.length-1]]
    {
        doGetList:(req,res,next)->
            limit = Number(req.params.limit) or 0
            page = Number(req.params.page) or 1
            sortby = req.params.sortby or 'createAt'
            desc = req.params.desc or 'desc'
            fields = req.params.fields
            async.parallel 
                count:(cb)->
                    Model.count cb
                list:(cb)->
                    # 直接查询
                    if ids.length is 1
                        # 是否查询指定字段
                        if fields
                            query = Model.find query,fields.split(',').join ' '
                        else
                            query = Model.find query
                        # 排序
                        sort = {}
                        sort[sortby]=desc
                        query.sort sort
                        # 分页
                        if limit
                            query.limit limit
                            query.skip (page-1)*limit
                        query.exec cb
                    else
                        query = Model.findOne getBaseQuery(req)
                        query.exec (err,doc)->
                            return cb err if err
                            cb err,getBaseList(req,doc)
            ,(err,result)->
                return res.send 500,err if err
                result.limit = limit
                result.page = page
                result.sortby = sortby
                result.desc = desc
                res.send 200,result
        doPost:(req,res,next)->
            not req.body and req.body={}
            req.body.createAt = Date.now()
            req.body.random = Math.random()
            cb = (err,doc)->
                return res.send 500,err if err
                if copyIds.length > 1
                    result = doc
                    for id in copyIds[1..]
                        result=result[id]
                    # 子文档操作时返回最后一条记录
                    docs = getBaseResult(req,doc)[copyIds[copyIds.length-1]]
                    res.send 200,docs[docs.length-1]
                else
                    res.send 200,doc
            if copyIds.length > 1
                update = {}
                update['$push'] = {}
                update['$push'][copyIds[1..].join('.$.')] = req.body
                query = getBaseQuery req
                Model.findOneAndUpdate query,update,cb
            else
                Model.create req.body,cb
        doGet:(req,res,next)->
            Model.findOne getBaseQuery(req)
            ,(err,doc)->
                return res.send 500,err if err
                res.send 200,getMoreResult(req,doc)

        # 操作子文档时，更新操作非原子操作
        # https://jira.mongodb.org/browse/SERVER-831
        doEdit:(req,res,next)->
            update = {}
            query = getMoreQuery req
            not req.body and req.body = {}
            if copyIds.length > 1
                Model.findOne query,(err,doc)->
                    return res.send 500,err if err
                    result = getMoreResult req,doc
                    for k,v of req.body
                        result[k]=v
                    doc.save (err,doc)->
                        return res.send 500,err if err
                        res.send 200,result
            else
                Model.findOneAndUpdate query,{$set:req.body},(err,doc)->
                    return res.send 500,err if err
                    res.send 200,doc
        doDelete:(req,res,next)->
            if copyIds.length > 1
                update = {}
                update[copyIds[1..].join('.$.')] = _id:req.params[lastId]
                query=Model.update getMoreQuery(req)
                ,{
                    $pull:update
                }
            else
                query=Model.remove _id:req.params[baseId]
            query.exec (err,rows)->
                return res.send 500,err if err
                res.send 200,rows

        doDeleteAll:(req,res,next)->
            if copyIds.length > 1
                query = {}
                query[copyIds[1..].join('.$.')] = req.query or {}
                query = Model.update getBaseQuery(req),{$pull:query}
            else
                query = req.query or {}
                query = Model.remove query
            query.exec (err,rows)->
                return res.send 500,err if err
                res.send 200,rows
    }
