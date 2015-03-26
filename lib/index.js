(function() {
  var async, mongoose;

  mongoose = require('mongoose');

  async = require('async');

  module.exports = function(server, Model, options) {
    var k, opts, route, v;
    if (options == null) {
      options = {};
    }
    Model.schema.add({
      createAt: Number
    });
    Model.schema.add({
      random: Number
    });
    route = require('./route')(Model);
    opts = {
      list: true,
      post: true,
      get: true,
      put: true,
      patch: true,
      del: true,
      path: Model.modelName
    };
    for (k in options) {
      v = options[k];
      opts[k] = v;
    }
    opts.list && server.get("/" + opts.path, route.doGetList);
    opts.post && server.post("/" + opts.path, route.doPost);
    opts.get && server.get("/" + opts.path + "/:id", route.doGet);
    opts.put && server.put("/" + opts.path + "/:id", route.doEdit);
    opts.patch && server.patch("/" + opts.path + "/:id", route.doEdit);
    opts.del && server.del("/" + opts.path + "/:id", route.doDelete);
    return {
      Model: Model
    };
  };

}).call(this);
