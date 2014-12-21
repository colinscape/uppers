express = require 'express'
app = express();
expressHbs = require 'express-handlebars'
fs = require 'fs'
_ = require 'underscore'
hnup = require './hnup'
hnup()

phup = require './phup'
phup()

redditup = require './redditup'
redditup('tech')
redditup('technews')

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
    uppers = hnup_data.uppers
    toppers = hnup_data.toppers

    _.each hnup_data.data, (v) -> v.tags = []
    _.map climbers, (c) -> hnup_data.data[c].tags.push 'climber'
    _.map rising_stars, (c) -> hnup_data.data[c].tags.push 'rising-star'
    _.map peakers, (c) -> hnup_data.data[c].tags.push 'peaker'
    _.map uppers, (c) -> hnup_data.data[c].tags.push 'upper'
    _.map toppers, (c) -> hnup_data.data[c].tags.push 'topper'

    interesting_ids = _.union climbers, rising_stars, peakers, uppers

    items = _.values _.pick hnup_data.data, interesting_ids
    items = _.sortBy items, (i) -> -1000*i.tags.length - i.peak_position

    res.render 'hnup', 
      title: 'Hacker News watch'
      items: items

  else
    res.send "No data yet! Check back soon :)"

app.get '/phup', (req, res) ->

  if fs.existsSync './data/phup.json'
    phup_json = fs.readFileSync './data/phup.json'
    phup_data = JSON.parse phup_json

    climbers = phup_data.climbers
    rising_stars = phup_data.rising_stars
    peakers = phup_data.peakers

    _.each phup_data.data, (v) -> v.tags = []
    _.map climbers, (c) -> phup_data.data[c].tags.push 'climber'
    _.map rising_stars, (c) -> phup_data.data[c].tags.push 'rising-star'
    _.map peakers, (c) -> phup_data.data[c].tags.push 'peaker'

    interesting_ids = _.union climbers, rising_stars, peakers

    items = _.values _.pick phup_data.data, interesting_ids
    items = _.sortBy items, (i) -> i.peak_position

    res.render 'phup', 
      title: 'Product Hunt watch'
      items: items

  else
    res.send "No data yet! Check back soon :)"


app.get '/redditup_tech', (req, res) ->

  if fs.existsSync './data/redditup_tech.json'
    json = fs.readFileSync './data/redditup_tech.json'
    data = JSON.parse json

    climbers = data.climbers
    rising_stars = data.rising_stars
    peakers = data.peakers

    _.each data.data, (v) -> v.tags = []
    _.map climbers, (c) -> data.data[c].tags.push 'climber'
    _.map rising_stars, (c) -> data.data[c].tags.push 'rising-star'
    _.map peakers, (c) -> data.data[c].tags.push 'peaker'

    interesting_ids = _.union climbers, rising_stars, peakers

    items = _.values _.pick data.data, interesting_ids
    items = _.sortBy items, (i) -> i.peak_position

    res.render 'redditup',
      title: 'Reddit Tech watch'
      subreddit: 'Tech'
      items: items

  else
    res.send "No data yet! Check back soon :)"


app.get '/redditup_technews', (req, res) ->

  if fs.existsSync './data/redditup_technews.json'
    json = fs.readFileSync './data/redditup_technews.json'
    data = JSON.parse json

    climbers = data.climbers
    rising_stars = data.rising_stars
    peakers = data.peakers

    _.each data.data, (v) -> v.tags = []
    _.map climbers, (c) -> data.data[c].tags.push 'climber'
    _.map rising_stars, (c) -> data.data[c].tags.push 'rising-star'
    _.map peakers, (c) -> data.data[c].tags.push 'peaker'

    interesting_ids = _.union climbers, rising_stars, peakers

    items = _.values _.pick data.data, interesting_ids
    items = _.sortBy items, (i) -> i.peak_position

    res.render 'redditup',
      title: 'Reddit Tech News watch'
      subreddit: 'Tech News'
      items: items

  else
    res.send "No data yet! Check back soon :)"

app.listen 80