_ = require 'underscore'
Page = require '../../models/page'
fs = require 'fs'

@index = (req, res) ->
  fs.readFile __dirname + '/content.json', (err, json) ->
    return next(err) if err
    res.render 'index', JSON.parse(json.toString())