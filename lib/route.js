(function() {
  var async, mongoose;

  mongoose = require('mongoose');

  async = require('async');

  module.exports = function(Model) {
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
            if (fields) {
              query = Model.find({}, fields.split(',').join(' '));
            } else {
              query = Model.find({});
            }
            sort = {};
            sort[sortby] = desc;
            query.sort(sort);
            if (limit) {
              query.limit(limit);
              query.skip((page - 1) * limit);
            }
            return query.exec(cb);
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
        !req.body && (req.body = {});
        req.body.createAt = Date.now();
        req.body.random = Math.random();
        return Model.create(req.body, function(err, doc) {
          if (err) {
            return res.send(500, err);
          }
          return res.send(200, doc);
        });
      },
      doGet: function(req, res, next) {
        var id;
        id = req.params.id;
        return Model.findOne({
          _id: mongoose.Types.ObjectId(id)
        }, function(err, doc) {
          if (err) {
            return res.send(500, err);
          }
          return res.send(200, doc);
        });
      },
      doEdit: function(req, res, next) {
        var id;
        id = req.params.id;
        return Model.findOneAndUpdate({
          _id: mongoose.Types.ObjectId(id)
        }, req.body, function(err, doc) {
          if (err) {
            return res.send(500, err);
          }
          return res.send(200, doc);
        });
      },
      doDelete: function(req, res, next) {
        var id;
        id = req.params.id;
        return Model.remove({
          _id: mongoose.Types.ObjectId(id)
        }, function(err, rows) {
          if (err) {
            return res.send(500, err);
          }
          return res.send(200, rows);
        });
      }
    };
  };

}).call(this);
