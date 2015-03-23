(function() {
  var async, mongoose;

  mongoose = require('mongoose');

  async = require('async');

  module.exports = function(server, db, modelName, schemaConfig, options) {
    var Model, k, opts, route, schema, v;
    if (schemaConfig == null) {
      schemaConfig = {};
    }
    if (options == null) {
      options = {};
    }
    schemaConfig.createAt = Number;
    schemaConfig.random = Number;
    schema = mongoose.Schema(schemaConfig);
    Model = db.model(modelName, schema);
    route = require('./route')(Model);
    opts = {
      list: true,
      post: true,
      get: true,
      put: true,
      patch: true,
      del: true
    };
    for (k in options) {
      v = options[k];
      opts[k] = v;
    }
    opts.list && server.get("/" + modelName, route.doGetList);
    opts.post && server.post("/" + modelName, route.doPost);
    opts.get && server.get("/" + modelName + "/:id", route.doGet);
    opts.put && server.put("/" + modelName + "/:id", route.doEdit);
    opts.patch && server.patch("/" + modelName + "/:id", route.doEdit);
    opts.del && server.del("/" + modelName + "/:id", route.doDelete);
    return {
      Model: Model
    };
  };

}).call(this);
