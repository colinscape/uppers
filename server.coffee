express = require 'express'
app = express();
expressHbs = require 'express-handlebars'
fs = require 'fs'
_ = require 'underscore'
Source = require './source'

hnup = require './hnup'
hnup_source = new Source 'hnup', hnup, 30000

phup = require './phup'
phup_source = new Source 'phup', phup, 30000

app.engine 'hbs', expressHbs
  extname: 'hbs'
  defaultLayout: 'main.hbs'
app.set 'view engine', 'hbs'

app.get '/', (req, res) ->
  res.render 'index'

app.get '/hnup', (req, res) ->

  data = hnup_source

  if not data.interesting? or data.interesting.length is 0 then return res.send "No data yet! Check back soon :)"

  newcomers = data.newcomers
  dropouts = data.dropouts

  climbers = data.climbers
  unchanged = data.unchanged
  fallers = data.fallers

  peakers = data.peakers
  rising_stars = data.rising_stars
  

  _.each data.data, (v) -> v.tags = []
  _.map newcomers, (c) -> data.data[c].tags.push 'newcomer'
  _.map climbers, (c) -> data.data[c].tags.push 'climber'
  _.map peakers, (c) -> data.data[c].tags.push 'peaker'
  _.map rising_stars, (c) -> data.data[c].tags.push 'rising-star'

  items = _.values _.pick data.data, data.interesting
  items = _.sortBy items, (i) -> -1000*i.tags.length - i.peak_position

  res.render 'hnup', 
    title: 'Hacker News watch'
    items: items



app.get '/phup', (req, res) ->

  if not fs.existsSync './data/phup.json' then res.send "No data yet! Check back soon :)"

  json = fs.readFileSync './data/phup.json'
  data = JSON.parse json

  newcomers = data.newcomers
  dropouts = data.dropouts

  climbers = data.climbers
  unchanged = data.unchanged
  fallers = data.fallers

  peakers = data.peakers
  rising_stars = data.rising_stars
  

  _.each data.data, (v) -> v.tags = []
  _.map newcomers, (c) -> data.data[c].tags.push 'newcomer'
  _.map climbers, (c) -> data.data[c].tags.push 'climber'
  _.map peakers, (c) -> data.data[c].tags.push 'peaker'
  _.map rising_stars, (c) -> data.data[c].tags.push 'rising-star'

  interesting_ids = _.union newcomers, climbers, peakers, rising_stars

  items = _.values _.pick data.data, interesting_ids
  items = _.sortBy items, (i) -> -1000*i.tags.length - i.peak_position

  res.render 'phup', 
    title: 'Product Hunt watch'
    items: items


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
