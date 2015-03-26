mongoose = require 'mongoose'
async = require 'async'
# 参数:model,内嵌文档的字段名

module.exports = (Model,childName=null)->
    parentName = Model.modelName # 模型名称
    if childName
        nameOfID = childName + 'id'
    else
        nameOfID = 'id'
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
                    # 是否查询内嵌文档
                    if childName
                        query = _id:req.params.id
                    else
                        query = {}
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
                    query.exec (err,docs)->
                        return cb err if err
                        return cb err,docs if not docs
                        # 是否查询内嵌文档
                        return cb err,docs[0][childName] if childName
                        cb err,docs
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
                if childName
                    # 子文档操作时返回最后一条记录
                    res.send 200,doc[childName][doc[childName].length-1]
                else
                    res.send 200,doc
            if childName
                query = {}
                query['$push'] = {}
                query['$push'][childName]=req.body
                Model.findOneAndUpdate {_id:req.params.id},query,cb
            else
                Model.create req.body,cb
                
        doGet:(req,res,next)->
            Model.findOne _id:req.params.id
            ,(err,doc)->
                return res.send 500,err if err
                # 是否查询子文档
                if childName
                    res.send 200,doc[childName].id(req.params[nameOfID])
                else
                    res.send 200,doc
        doEdit:(req,res,next)->
            editObj = {}
            query = {}
            not req.body and req.body = {}
            if childName
                for k,v of req.body
                    editObj[childName+'.$.'+k]=v
                query[childName+'._id']=req.params[nameOfID]
            else
                editObj=req.body
                query._id = req.params.id
            editObj = '$set':editObj
            Model.findOneAndUpdate query
            ,editObj
            ,(err,doc)->
                return res.send 500,err if err
                if childName
                    res.send 200,doc[childName].id(req.params[nameOfID])
                else
                    res.send 200,doc
        doDelete:(req,res,next)->
            if childName
                query = {}
                query[childName]=_id:req.params[nameOfID]
                query=Model.update _id:req.params.id
                ,{
                    $pull:query
                }
            else
                query=Model.remove _id:req.params.id
            query.exec (err,rows)->
                return res.send 500,err if err
                res.send 200,rows

        doDeleteAll:(req,res,next)->
            query = req.params or {}
            if childName
                query = {}
                query[childName] = req.params or {}
                query=Model.update _id:req.params.id
                ,{
                    $pull:query
                }
            else
                query = req.params or {}
                query = Model.remove query
            query.exec (err,rows)->
                return res.send 500,err if err
                res.send 200,rows


    }
