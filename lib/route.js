(function() {
  var async, mongoose;

  mongoose = require('mongoose');

  async = require('async');

  module.exports = function(Model, ids) {
    var baseId, copyIds, getBaseList, getBaseQuery, getBaseResult, getMoreQuery, getMoreResult, k, lastId, parentName, prevId;
    if (ids == null) {
      ids = [];
    }
    copyIds = (function() {
      var j, len, results;
      results = [];
      for (j = 0, len = ids.length; j < len; j++) {
        k = ids[j];
        results.push(k);
      }
      return results;
    })();
    parentName = Model.modelName;
    baseId = copyIds[0] + 'id';
    lastId = copyIds[copyIds.length - 1] + 'id';
    prevId = copyIds[copyIds.length - 2] + 'id';
    getBaseQuery = function(req) {
      var baseQuery;
      baseQuery = {};
      baseQuery._id = req.params[baseId];
      if (copyIds.length > 2) {
        baseQuery[copyIds.slice(1, -1).join('.') + '._id'] = req.params[prevId];
      }
      return baseQuery;
    };
    getMoreQuery = function(req) {
      var baseQuery, head, i, id, j, len;
      baseQuery = {};
      for (i = j = 0, len = copyIds.length; j < len; i = ++j) {
        id = copyIds[i];
        head = copyIds.slice(1, +i + 1 || 9e9).join('.');
        if (head) {
          head += '._id';
        } else {
          head = '_id';
        }
        baseQuery[head] = req.params[id + 'id'];
      }
      return baseQuery;
    };
    getBaseResult = function(req, doc) {
      var id, j, len, ref, result;
      result = doc;
      if (copyIds.length > 2) {
        ref = copyIds.slice(1, -1);
        for (j = 0, len = ref.length; j < len; j++) {
          id = ref[j];
          result = result[id].id(req.params[id + 'id']);
        }
      }
      return result;
    };
    getMoreResult = function(req, doc) {
      var id, j, len, ref, result;
      result = doc;
      if (copyIds.length > 1) {
        ref = copyIds.slice(1);
        for (j = 0, len = ref.length; j < len; j++) {
          id = ref[j];
          result = result[id].id(req.params[id + 'id']);
        }
      }
      return result;
    };
    getBaseList = function(req, doc) {
      var id, j, len, ref, result;
      result = doc;
      if (copyIds.length === 2) {
        return result[copyIds[1]];
      } else {
        ref = copyIds.slice(1, -1);
        for (j = 0, len = ref.length; j < len; j++) {
          id = ref[j];
          result = result[id].id(req.params[id + 'id']);
        }
        return result[copyIds[copyIds.length - 1]];
      }
    };
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
            if (ids.length === 1) {
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
              return query.exec(cb);
            } else {
              query = Model.findOne(getBaseQuery(req));
              return query.exec(function(err, doc) {
                if (err) {
                  return cb(err);
                }
                return cb(err, getBaseList(req, doc));
              });
            }
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
        var cb, query, update;
        !req.body && (req.body = {});
        req.body.createAt = Date.now();
        req.body.random = Math.random();
        cb = function(err, doc) {
          var docs, id, j, len, ref, result;
          if (err) {
            return res.send(500, err);
          }
          if (copyIds.length > 1) {
            result = doc;
            ref = copyIds.slice(1);
            for (j = 0, len = ref.length; j < len; j++) {
              id = ref[j];
              result = result[id];
            }
            docs = getBaseResult(req, doc)[copyIds[copyIds.length - 1]];
            return res.send(200, docs[docs.length - 1]);
          } else {
            return res.send(200, doc);
          }
        };
        if (copyIds.length > 1) {
          update = {};
          update['$push'] = {};
          update['$push'][copyIds.slice(1).join('.$.')] = req.body;
          query = getBaseQuery(req);
          return Model.findOneAndUpdate(query, update, cb);
        } else {
          return Model.create(req.body, cb);
        }
      },
      doGet: function(req, res, next) {
        return Model.findOne(getBaseQuery(req), function(err, doc) {
          if (err) {
            return res.send(500, err);
          }
          return res.send(200, getMoreResult(req, doc));
        });
      },
      doEdit: function(req, res, next) {
        var query, update;
        update = {};
        query = getMoreQuery(req);
        !req.body && (req.body = {});
        if (copyIds.length > 1) {
          return Model.findOne(query, function(err, doc) {
            var ref, result, v;
            if (err) {
              return res.send(500, err);
            }
            result = getMoreResult(req, doc);
            ref = req.body;
            for (k in ref) {
              v = ref[k];
              result[k] = v;
            }
            return doc.save(function(err, doc) {
              if (err) {
                return res.send(500, err);
              }
              return res.send(200, result);
            });
          });
        } else {
          return Model.findOneAndUpdate(query, {
            $set: req.body
          }, function(err, doc) {
            if (err) {
              return res.send(500, err);
            }
            return res.send(200, doc);
          });
        }
      },
      doDelete: function(req, res, next) {
        var query, update;
        if (copyIds.length > 1) {
          update = {};
          update[copyIds.slice(1).join('.$.')] = {
            _id: req.params[lastId]
          };
          query = Model.update(getMoreQuery(req), {
            $pull: update
          });
        } else {
          query = Model.remove({
            _id: req.params[baseId]
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
        if (copyIds.length > 1) {
          query = {};
          query[copyIds.slice(1).join('.$.')] = req.query || {};
          query = Model.update(getBaseQuery(req), {
            $pull: query
          });
        } else {
          query = req.query || {};
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
