(function() {
  var async, mongoose;

  mongoose = require('mongoose');

  async = require('async');

  module.exports = function(server, Model, options) {
    var child, childs, i, j, k, l, len, len1, len2, methods, opts, path, route, v;
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
    methods = ['list', 'post', 'get', 'put', 'patch', 'del', 'delAll'];
    opts = {
      path: Model.modelName,
      childs: []
    };
    for (i = 0, len = methods.length; i < len; i++) {
      k = methods[i];
      opts[k] = true;
    }
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
    opts.delAll && server.del("/" + opts.path, route.doDeleteAll);
    childs = opts.childs;
    if (!Array.isArray(childs)) {
      childs = [childs];
    }
    for (j = 0, len1 = childs.length; j < len1; j++) {
      child = childs[j];
      for (l = 0, len2 = methods.length; l < len2; l++) {
        k = methods[l];
        if (typeof child[k] === 'undefined') {
          child[k] = true;
        }
      }
      route = require('./route')(Model, child.path);
      path = '/:' + child.path + 'id';
      child.list && server.get("/" + opts.path + "/:id/" + child.path, route.doGetList);
      child.post && server.post("/" + opts.path + "/:id/" + child.path, route.doPost);
      child.get && server.get(("/" + opts.path + "/:id/" + child.path) + path, route.doGet);
      child.put && server.put(("/" + opts.path + "/:id/" + child.path) + path, route.doEdit);
      child.patch && server.patch(("/" + opts.path + "/:id/" + child.path) + path, route.doEdit);
      child.del && server.del(("/" + opts.path + "/:id/" + child.path) + path, route.doDelete);
      child.delAll && server.del("/" + opts.path + "/:id/" + child.path, route.doDeleteAll);
    }
    return {
      Model: Model
    };
  };

}).call(this);
