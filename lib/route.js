(function() {
  var async, mongoose;

  mongoose = require('mongoose');

  async = require('async');

  module.exports = function(Model, childName) {
    var nameOfID, parentName;
    if (childName == null) {
      childName = null;
    }
    parentName = Model.modelName;
    if (childName) {
      nameOfID = childName + 'id';
    } else {
      nameOfID = 'id';
    }
    return {
      doGetList: function(req, res, next) {
        var desc, fields, limit, page, sortby;
        limit = Number(req.params.limit) || 0;
        page = Number(req.params.page) || 1;
        sortby = req.params.sortby || 'createAt';
        desc = req.params.desc || 'desc';
        fields = req.params.fields;
        return async.parallel({
          count: function(cb) {
            return Model.count(cb);
          },
          list: function(cb) {
            var query, sort;
            if (childName) {
              query = {
                _id: req.params.id
              };
            } else {
              query = {};
            }
            if (fields) {
              query = Model.find(query, fields.split(',').join(' '));
            } else {
              query = Model.find(query);
            }
            sort = {};
            sort[sortby] = desc;
            query.sort(sort);
            if (limit) {
              query.limit(limit);
              query.skip((page - 1) * limit);
            }
            return query.exec(function(err, docs) {
              if (err) {
                return cb(err);
              }
              if (!docs) {
                return cb(err, docs);
              }
              if (childName) {
                return cb(err, docs[0][childName]);
              }
              return cb(err, docs);
            });
          }
        }, function(err, result) {
          if (err) {
            return res.send(500, err);
          }
          result.limit = limit;
          result.page = page;
          result.sortby = sortby;
          result.desc = desc;
          return res.send(200, result);
        });
      },
      doPost: function(req, res, next) {
        var cb, query;
        !req.body && (req.body = {});
        req.body.createAt = Date.now();
        req.body.random = Math.random();
        cb = function(err, doc) {
          if (err) {
            return res.send(500, err);
          }
          if (childName) {
            return res.send(200, doc[childName][doc[childName].length - 1]);
          } else {
            return res.send(200, doc);
          }
        };
        if (childName) {
          query = {};
          query['$push'] = {};
          query['$push'][childName] = req.body;
          return Model.findOneAndUpdate({
            _id: req.params.id
          }, query, cb);
        } else {
          return Model.create(req.body, cb);
        }
      },
      doGet: function(req, res, next) {
        return Model.findOne({
          _id: req.params.id
        }, function(err, doc) {
          if (err) {
            return res.send(500, err);
          }
          if (childName) {
            return res.send(200, doc[childName].id(req.params[nameOfID]));
          } else {
            return res.send(200, doc);
          }
        });
      },
      doEdit: function(req, res, next) {
        var editObj, k, query, ref, v;
        editObj = {};
        query = {};
        !req.body && (req.body = {});
        if (childName) {
          ref = req.body;
          for (k in ref) {
            v = ref[k];
            editObj[childName + '.$.' + k] = v;
          }
          query[childName + '._id'] = req.params[nameOfID];
        } else {
          editObj = req.body;
          query._id = req.params.id;
        }
        editObj = {
          '$set': editObj
        };
        return Model.findOneAndUpdate(query, editObj, function(err, doc) {
          if (err) {
            return res.send(500, err);
          }
          if (childName) {
            return res.send(200, doc[childName].id(req.params[nameOfID]));
          } else {
            return res.send(200, doc);
          }
        });
      },
      doDelete: function(req, res, next) {
        var query;
        if (childName) {
          query = {};
          query[childName] = {
            _id: req.params[nameOfID]
          };
          query = Model.update({
            _id: req.params.id
          }, {
            $pull: query
          });
        } else {
          query = Model.remove({
            _id: req.params.id
          });
        }
        return query.exec(function(err, rows) {
          if (err) {
            return res.send(500, err);
          }
          return res.send(200, rows);
        });
      },
      doDeleteAll: function(req, res, next) {
        var query;
        query = req.params || {};
        if (childName) {
          query = {};
          query[childName] = req.params || {};
          query = Model.update({
            _id: req.params.id
          }, {
            $pull: query
          });
        } else {
          query = req.params || {};
          query = Model.remove(query);
        }
        return query.exec(function(err, rows) {
          if (err) {
            return res.send(500, err);
          }
          return res.send(200, rows);
        });
      }
    };
  };

}).call(this);
