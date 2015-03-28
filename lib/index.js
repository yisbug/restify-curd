(function() {
  var async, mongoose;

  mongoose = require('mongoose');

  async = require('async');

  module.exports = function(server, Model, options) {
    var addRoute, k, methods, opts, v;
    if (options == null) {
      options = {};
    }
    Model.schema.add({
      createAt: Number
    });
    Model.schema.add({
      random: Number
    });
    methods = ['list', 'post', 'get', 'put', 'patch', 'del', 'delAll'];
    opts = {
      path: Model.modelName,
      childs: []
    };
    for (k in options) {
      v = options[k];
      opts[k] = v;
    }
    addRoute = function(config, ids) {
      var basePath, basePathID, child, childs, copyIds, i, id, j, l, len, len1, len2, len3, results, route;
      if (ids == null) {
        ids = [];
      }
      copyIds = (function() {
        var i, len1, results;
        results = [];
        for (i = 0, len1 = ids.length; i < len1; i++) {
          k = ids[i];
          results.push(k);
        }
        return results;
      })();
      copyIds.push(config.path);
      len = copyIds.length;
      basePathID = basePath = '';
      for (k = i = 0, len1 = copyIds.length; i < len1; k = ++i) {
        id = copyIds[k];
        if (k === len - 1) {
          basePath = basePathID + "/" + id;
        }
        basePathID += "/" + id + "/:" + id + "id";
      }
      route = require('./route')(Model, copyIds);
      for (j = 0, len2 = methods.length; j < len2; j++) {
        k = methods[j];
        if (typeof config[k] === 'undefined') {
          config[k] = true;
        }
      }
      config.list && server.get(basePath, route.doGetList);
      config.post && server.post(basePath, route.doPost);
      config.get && server.get(basePathID, route.doGet);
      config.put && server.put(basePathID, route.doEdit);
      config.patch && server.patch(basePathID, route.doEdit);
      config.del && server.del(basePathID, route.doDelete);
      config.delAll && server.del(basePath, route.doDeleteAll);
      childs = config.childs;
      if (!childs) {
        return;
      }
      if (!Array.isArray(childs)) {
        childs = [childs];
      }
      if (childs.length < 1) {
        return;
      }
      results = [];
      for (l = 0, len3 = childs.length; l < len3; l++) {
        child = childs[l];
        results.push(addRoute(child, copyIds));
      }
      return results;
    };
    addRoute(opts, []);
    return {
      Model: Model
    };
  };

}).call(this);
