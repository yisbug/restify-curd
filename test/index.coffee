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
            Animal = db.model 'animal',new mongoose.Schema({
                name:String
                age:Number
                sons:[{
                    name:String
                    age:Number
                    friends:[{
                        name:String
                        age:Number
                    }]
                }]
            })
            curd server,Animal,{
                childs:
                    path:'sons'
                    childs:
                        path:'friends'
            }
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
    sonid = ''
    resData = ''
    list = null

    describe '主文档',->
        it 'delAll',(done)->
            len = 0
            client.get '/animal',(err,req,res,obj)->
                assert.ifError err
                len = obj.count
                client.del '/animal',(err,req,res,obj)->
                    assert.ifError err
                    if typeof obj is 'object'
                    else
                        len.should.be.equal obj
                    done()


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
                id = obj.list[1]._id
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
                # console.log 123123,editData
                # console.log obj,123123
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
                # obj.should.be.equal 1
                done()
        it 'get list...length',(done)->
            client.get '/animal',(err,req,res,obj)->
                assert.ifError err
                obj.list.length.should.be.equal list.length-1
                done()

        it '批量删除',(done)->
            tmpList = []
            client.post '/animal',{
                name:'等待删除'
            },(err,req,res,obj)->
                assert.ifError err
                client.get '/animal',(err,req,res,obj)->
                    assert.ifError err
                    tmpList = obj.list
                    name = encodeURI 'name=等待删除'
                    client.del '/animal?'+name,(err,req,res,obj)->
                        assert.ifError err
                        # obj.should.be.equal 1
                        client.get '/animal',(err,req,res,obj)->
                            assert.ifError err
                            obj.list.length.should.be.equal tmpList.length-1
                            done()

    describe '子文档',->
        testData = {
            name:'儿子1'
            age:15
        }
        it 'post',(done)->
            client.post '/animal/'+id+'/sons',testData,(err,req,res,obj)->
                assert.ifError err
                obj.name.should.be.equal testData.name
                obj.age.should.be.equal testData.age
                client.get '/animal/'+id+'/sons/'+obj._id,(err,req,res,obj1)->
                    assert.ifError err
                    obj1.name.should.be.equal testData.name
                    obj1.age.should.be.equal testData.age
                    obj1._id.should.be.equal obj._id
                    done()

        it 'list',(done)->
            client.get '/animal/'+id+'/sons',(err,req,res,obj)->
                assert.ifError err
                obj.list.length.should.be.equal 1
                obj.list[0].name.should.be.equal testData.name
                obj.list[0].age.should.be.equal testData.age
                testData._id = obj.list[0]._id
                done()

        list = []
        it '批量插入一批数据',(done)->
            async.map [1..10],(item,cb)->
                tmpData =
                    name:Math.random() + '名称'
                    age:Math.random()* 10
                client.post '/animal/'+id+'/sons',tmpData,(err,req,res,obj)->
                    obj.name.should.be.equal tmpData.name
                    obj.age.should.be.equal tmpData.age
                    cb err
            ,(err,results)->
                assert.ifError err
                client.get '/animal/'+id+'/sons',(err,req,res,obj)->
                    assert.ifError err
                    list = obj.list
                    done()

        it '修改',(done)->
            editData = {
                name:'儿子'+Math.random()
                age:12
            }
            index = parseInt(list.length*Math.random())
            o = list[index]
            client.put '/animal/'+id+'/sons/'+o._id,editData,(err,req,res,obj)->
                assert.ifError err
                obj.name.should.be.equal editData.name
                obj.age.should.be.equal editData.age
                client.get '/animal/'+id+'/sons',(err,req,res,obj)->
                    assert.ifError err
                    obj.list[index].name.should.be.equal editData.name
                    obj.list[index].age.should.be.equal editData.age
                    for item,i in obj.list
                        if i is index
                            item.name.should.be.equal editData.name
                            item.age.should.be.equal editData.age
                        else
                            item.name.should.not.be.equal editData.name
                            item.name.should.not.be.equal editData.age
                    done()

        it '删除',(done)->
            index = parseInt(list.length*Math.random())
            o = list[index]
            client.del '/animal/'+id+'/sons/'+o._id,(err,req,res,obj)->
                assert.ifError err
                # obj.should.be.equal 1
                client.get '/animal/'+id+'/sons',(err,req,res,obj)->
                    assert.ifError err
                    obj.list.length.should.be.equal list.length-1
                    done()
        it '删除所有',(done)->
            client.del '/animal/'+id+'/sons',(err,req,res,obj)->
                assert.ifError err
                # obj.should.be.equal 1
                client.get '/animal/'+id+'/sons',(err,req,res,obj)->
                    assert.ifError err
                    obj.list.length.should.be.equal 0
                    done()

    describe '孙文档',->
        testData = {
            name:'朋友1'
            age:17
        }
        list = []
        sonid = ''
        it '批量插入一批儿子',(done)->
            async.map [1..3],(item,cb)->
                tmpData =
                    name:Math.random() + '名称'
                    age:Math.random()* 10
                client.post '/animal/'+id+'/sons',tmpData,(err,req,res,obj)->
                    obj.name.should.be.equal tmpData.name
                    obj.age.should.be.equal tmpData.age
                    cb err
            ,(err,results)->
                assert.ifError err
                client.get '/animal/'+id+'/sons',(err,req,res,obj)->
                    assert.ifError err
                    list = obj.list
                    sonid = list[0]._id
                    done()
        it 'post',(done)->
            client.post '/animal/'+id+'/sons/'+sonid+'/friends',testData,(err,req,res,obj)->
                assert.ifError err
                for k,v of testData
                    obj[k].should.be.equal v
                client.get "/animal/#{id}/sons/#{sonid}/friends/#{obj._id}",(err,req,res,obj)->
                    assert.ifError err
                    for k,v of testData
                        obj[k].should.be.equal v
                    done()

        it 'list',(done)->
            client.get "/animal/#{id}/sons/#{sonid}/friends",(err,req,res,obj)->
                assert.ifError err
                obj.list.length.should.be.equal 1
                obj.list[0].name.should.be.equal testData.name
                obj.list[0].age.should.be.equal testData.age
                done()
        it '批量插入一批朋友',(done)->
            async.map [1..5],(item,cb)->
                tmpData =
                    name:Math.random() + '朋友'
                    age:Math.random()* 10
                client.post '/animal/'+id+'/sons/'+sonid+'/friends',tmpData,(err,req,res,obj)->
                    obj.name.should.be.equal tmpData.name
                    obj.age.should.be.equal tmpData.age
                    cb err
            ,(err,results)->
                assert.ifError err
                client.get '/animal/'+id+'/sons/'+sonid+'/friends',(err,req,res,obj)->
                    assert.ifError err
                    list = obj.list
                    list.length.should.be.equal 6
                    done()

        it '修改',(done)->
            editData = {
                name:'朋友'+Math.random()
                age:120
            }
            index = parseInt(list.length*Math.random())
            o = list[index]
            client.put '/animal/'+id+'/sons/'+sonid+'/friends/'+o._id,editData,(err,req,res,obj)->
                assert.ifError err
                obj.name.should.be.equal editData.name
                obj.age.should.be.equal editData.age
                client.get '/animal/'+id+'/sons/'+sonid+'/friends',(err,req,res,obj)->
                    assert.ifError err
                    obj.list[index].name.should.be.equal editData.name
                    obj.list[index].age.should.be.equal editData.age
                    for item,i in obj.list
                        if i is index
                            item.name.should.be.equal editData.name
                            item.age.should.be.equal editData.age
                        else
                            item.name.should.not.be.equal editData.name
                            item.name.should.not.be.equal editData.age
                    done()

        it '删除',(done)->
            index = parseInt(list.length*Math.random())
            o = list[index]
            client.del '/animal/'+id+'/sons/'+sonid+'/friends/'+o._id,(err,req,res,obj)->
                assert.ifError err
                # obj.should.be.equal 1
                client.get '/animal/'+id+'/sons/'+sonid+'/friends',(err,req,res,obj)->
                    assert.ifError err
                    obj.list.length.should.be.equal list.length-1
                    done()
        it '删除特定条件',(done)->
            client.post "/animal/#{id}/sons/#{sonid}/friends",{name:'test'},(err,req,res,obj)->
                assert.ifError err
                obj.name.should.be.equal 'test'
                client.del "/animal/#{id}/sons/#{sonid}/friends?name=test",(err,req,res,obj)->
                    assert.ifError err
                    client.get "/animal/#{id}/sons/#{sonid}/friends",(err,req,res,obj)->
                        for item in obj.list
                            item.name.should.not.be.equal 'test'
                        done()

        it '删除所有',(done)->
            client.del '/animal/'+id+'/sons/'+sonid+'/friends',(err,req,res,obj)->
                assert.ifError err
                # obj.should.be.equal 1
                client.get '/animal/'+id+'/sons/'+sonid+'/friends',(err,req,res,obj)->
                    assert.ifError err
                    obj.list.length.should.be.equal 0
                    done()
