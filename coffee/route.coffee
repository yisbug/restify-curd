mongoose = require 'mongoose'
async = require 'async'

module.exports = (Model)->
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
                if fields
                    query = Model.find {},fields.split(',').join ' '
                else
                    query = Model.find {}
                sort = {}
                sort[sortby]=desc
                query.sort sort
                if limit
                    query.limit limit
                    query.skip (page-1)*limit
                query.exec cb
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
        Model.create req.body,(err,doc)->
            return res.send 500,err if err
            res.send 200,doc
    doGet:(req,res,next)->
        id = req.params.id
        Model.findOne _id:mongoose.Types.ObjectId(id)
        ,(err,doc)->
            return res.send 500,err if err
            res.send 200,doc
    doEdit:(req,res,next)->
        id = req.params.id
        Model.findOneAndUpdate _id:mongoose.Types.ObjectId(id)
        ,req.body
        ,(err,doc)->
            return res.send 500,err if err
            res.send 200,doc
    doDelete:(req,res,next)->
        id = req.params.id
        Model.remove _id:mongoose.Types.ObjectId(id)
        ,(err,rows)->
            return res.send 500,err if err
            res.send 200,rows