express = require 'express'
app = express();
expressHbs = require 'express-handlebars'
fs = require 'fs'
_ = require 'underscore'
Source = require './source'

hnup = require './hnup'
hnup_source = new Source app, 'hnup', 'Hacker News watch', 'hnup', hnup, 30000

phup = require './phup'
phup_source = new Source app, 'phup', 'Product Hunt watch', 'phup', phup, 30000

redditup = require './redditup'
redditup_tech = redditup 'tech'
redditup_tech_source = new Source app, 'redditup_tech', 'Reddit Tech watch', 'redditup', redditup_tech, 30000


app.engine 'hbs', expressHbs
  extname: 'hbs'
  defaultLayout: 'main.hbs'
app.set 'view engine', 'hbs'

app.get '/', (req, res) ->
  res.render 'index'

app.listen 80
