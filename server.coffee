express = require 'express'
app = express();
expressHbs = require 'express-handlebars'
fs = require 'fs'
_ = require 'underscore'
hnup = require './hnup'
hnup()

app.engine 'hbs', expressHbs
  extname: 'hbs'
  defaultLayout: 'main.hbs'
app.set 'view engine', 'hbs'

app.get '/', (req, res) ->
  res.render 'index'

app.get '/hnup', (req, res) ->

  if fs.existsSync './data/hnup.json'
    hnup_json = fs.readFileSync './data/hnup.json'
    hnup_data = JSON.parse hnup_json

    climbers = hnup_data.climbers
    rising_stars = hnup_data.rising_stars
    peakers = hnup_data.peakers

    _.each hnup_data.data, (v) -> v.tags = []
    _.map climbers, (c) -> hnup_data.data[c].tags.push 'climber'
    _.map rising_stars, (c) -> hnup_data.data[c].tags.push 'rising-star'
    _.map peakers, (c) -> hnup_data.data[c].tags.push 'peaker'

    interesting_ids = _.union climbers, rising_stars, peakers

    items = _.values _.pick hnup_data.data, interesting_ids
    items = _.sortBy items, (i) -> i.peak_position

    res.render 'hnup', 
      items: items

  else
    res.send "No data yet! Check back soon :)"

app.listen 80