# restify-curd

通用的collection操作，包含`GET`,`POST`,`PATCH`,`DEL`等。

### 更新

#### 1.0.2

* 参数由原先的(server,db,modelName,schemaConfig,options)修改为(server,Model,options)
* createAt和random字段由默认配置修改为schema动态添加
* 如果传入的Model.schema中未设置createAt和random字段时，REST请求将无法获取这两个字段。
* `options`参数增加一个字段`path`，标识路由路径，默认为`Model.modelName`，不需要加`/`





### Installation

    npm install restify-curd

### 使用

``` coffee
restify = require 'restify'
mongoose = require 'mongoose'
curd = require 'restify-curd'

server = restify.createServer()
db = mongoose.createConnection 'mongodb://localhost/restify-curd-test'
db.once 'open',->
    Model = db.model 'test',schema
    curd (server,Model,options)
    server.listen port,->
        console.log 'server start.'
```

### 参数

* `server` object
* `Model` mongoose Model
* `options` object

options参数
* `list` boolean 是否开放获取列表接口，默认开放
* `post` boolean 是否开放新建接口，默认开放
* `get` boolean 是否开放获取详情接口，默认开放
* `put` boolean 是否开放修改接口，默认开放
* `patch` boolean 是否开放修改接口，默认开放
* `del` boolean 是否开放删除接口，默认开放
* `path` String 路由资源地址，默认为Model.modelName

### 其他默认设置

* 默认为schemaConfig添加createAt和random两个数字类型数字，一个标识创建资源的时间，一个为小于1的随机数字，用于获取随机数据。

### `GET /collection` 获取列表
参数：
* limit number
* page number
* sortby string 默认按createAt大小逆序排列
* desc asc/desc
* fields string 逗号分隔的字符串

返回：

* count number
* page number
* limit number
* sortby string
* desc asc/desc
* list array

### `POST /collection` 新建
返回新建的记录

### `GET /collection/:id` 查询指定id的记录
参数：
* fields string 逗号分隔的字符串

### `PUT /collection/:id` 更新指定id的记录
返回该记录信息

### `PATCH /collection/:id` 修改指定id的记录
返回该记录信息

### `DELETE /collection/:id` 删除指定id的记录