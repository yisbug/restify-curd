restify = require 'restify'
mongoose = require 'mongoose'
assert = require 'assert'
should = require 'should'
async = require 'async'

describe 'test',->
    port = 8002

    client = restify.createJSONClient url:'http://localhost:' + port
    server = ''
    db = ''
    before (done)->
        server = restify.createServer {}
        server.use restify.authorizationParser()
        server.use restify.bodyParser mapParams:false
        server.use restify.queryParser()
        db = mongoose.createConnection 'mongodb://localhost/restify-curd-test'
        port = 8002
        db.once 'open',->
            curd = require '../coffee/index'
            Animal = db.model 'animal',{
                name:String
                age:Number
            }
            curd server,Animal
            server.listen port,->
                console.log 'server start on test mode.'
                done()
    after (done)->
        server.close()
        db.close()
        done()

    newData = {
        name:'测试名称'+Math.random()
        age:parseInt Math.random()*10
    }

    patchData = {name:'test'+Math.random()}
    editData = {name:'test'+Math.random()}


    id = ''
    resData = ''
    list = null

    describe 'test',->

        it 'post',(done)->
            async.map [1..10],(item,cb)->
                client.post '/animal',newData,(err,req,res,obj)->
                    assert.ifError err
                    for k,v of newData
                        obj[k].should.be.equal v
                    time = Date.now()
                    obj.createAt.should.be.above time-2000
                    # obj.createAt.should.be.below Date.now()
                    obj.random.should.be.below 1
                    obj.random.should.be.above 0
                    cb()
            ,(err,results)->
                assert.ifError err
                done()

        it 'get list',(done)->
            client.get '/animal',(err,req,res,obj)->
                assert.ifError err
                obj.should.have.keys 'count','page','limit','sortby','desc','list'
                obj.count.should.be.above 0
                list = obj.list
                list.length.should.be.equal obj.count
                obj.sortby.should.be.equal 'createAt'
                if obj.desc is 'asc'
                    for item,k in list
                        list[k+1] and list[k+1].createAt.should.not.be.below item.createAt
                if obj.desc is 'desc'
                    for item,k in list
                        list[k+1] and list[k+1].createAt.should.not.be.above item.createAt

                resData = obj.list[0]
                done()
        it 'get list...limit',(done)->
            client.get '/animal?limit=2',(err,req,res,obj)->
                assert.ifError err
                obj.limit.should.be.equal 2
                obj.list.length.should.be.equal 2
                assert.deepEqual obj.list[0],list[0]
                assert.deepEqual obj.list[1],list[1]
                assert.notDeepEqual obj.list[0],list[1]
                done()
        it 'get list...page',(done)->
            client.get '/animal?limit=2&page=2',(err,req,res,obj)->
                assert.ifError err
                obj.limit.should.be.equal 2
                obj.list.length.should.be.equal 2
                assert.deepEqual obj.list[0],list[2]
                assert.deepEqual obj.list[1],list[3]
                assert.notDeepEqual obj.list[1],list[2]
                done()
        it 'get list...sortby',(done)->
            client.get '/animal?sortby=age&desc=asc',(err,req,res,obj)->
                assert.ifError err
                list = obj.list
                list.length.should.be.equal obj.count
                obj.sortby.should.be.equal 'age'
                obj.desc.should.be.equal 'asc'
                if obj.desc is 'asc'
                    for item,k in list
                        list[k+1] and list[k+1].age.should.not.be.below item.age
                if obj.desc is 'desc'
                    for item,k in list
                        list[k+1] and list[k+1].age.should.not.be.above item.age
                resData = obj.list[0]
                done()
        it 'get list...fields',(done)->
            client.get '/animal?fields=name,createAt',(err,req,res,obj)->
                assert.ifError err
                for k in obj.list
                    should(k.age).be.undefined
                    k.name.should.not.be.undefined
                    k.createAt.should.not.be.undefined
                done()

        it 'put',(done)->
            client.put '/animal/'+resData._id,editData,(err,req,res,obj)->
                assert.ifError err
                for k,v of editData
                    obj[k].should.be.equal v
                done()

        it 'get ',(done)->
            client.get '/animal/'+resData._id,(err,req,res,obj)->
                assert.ifError err
                for k,v of editData
                    obj[k].should.be.equal v
                done()
        it 'patch',(done)->
            client.patch '/animal/'+resData._id,patchData,(err,req,res,obj)->
                assert.ifError err
                for k,v of patchData
                    obj[k].should.be.equal v
                done()
        it 'delete',(done)->
            client.del '/animal/'+resData._id,(err,req,res,obj)->
                assert.ifError err
                obj.should.be.equal 1
                done()
        it 'get list...length',(done)->
            client.get '/animal',(err,req,res,obj)->
                assert.ifError err
                obj.list.length.should.be.equal list.length-1
                done()
