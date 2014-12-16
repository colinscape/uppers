_ = require 'underscore'
ent = require 'ent'
request = require 'request'
fs = require 'fs'

data = {}
current_posts = []


module.exports = (subreddit) ->

	options =
		url: "http://api.reddit.com/r/#{subreddit}/hot.json?limit=100"
		headers:
        	'User-Agent': 'topicol-bot/0.1 by colinscape'

	if not fs.existsSync './data'
		fs.mkdir './data'

	if fs.existsSync "./data/redditup_#{subreddit}.json"
		redditup_json = fs.readFileSync "./data/redditup_#{subreddit}.json"
		redditup_data = JSON.parse redditup_json
		current_posts = redditup_data.current_posts
		data = redditup_data.data
		first = false
	else
		current_posts = []
		redditup_data = 
			rising_stars: []
			climbers: []
			peakers: []
			uppers: []
			toppers: []
			data: {}
			current_posts: []
		data = {}
		first = true

	callback = (err, resp, body) ->

		if err?
			return console.error "HTTP ERROR #{err}"

		try
			response = JSON.parse body
		catch err
			return console.error "JSON ERROR #{err} when decoding #{body}"
		if not response?
			return console.error "NO JSON RETURNED"
		
		posts = response.data.children
		for post in posts
			if not data[post.data.id]?
				data[post.data.id] = 
					title: ent.decode post.data.title
					url: post.data.url
					entry_at: null
					history: []
					peak_position: null

		#posts = _.pluck (_.sortBy posts, (p) -> -p.data.votes_count), 'id'
		posts = _.map posts, (p) -> p.data.id

		info = _.object posts, _.map posts, (id, i) ->
			id: id
			new_position: i+1
			old_position: null

		# Extract the information on movements by comparing old position to new position.
		for id, i in posts
			index = _.indexOf current_posts, id
			if index isnt -1
				info[id].old_position = index+1
				if index+1 isnt info[id].new_position then data[id].history.push (i+1)
				if not data[id].peak_position? then data[id].peak_position = info[id].new_position
				if info[id].new_position < data[id].peak_position then data[id].peak_position = info[id].new_position
		current_posts = posts


		new_entries = _.filter (_.keys info), (id) -> not info[id].old_position?
		climbers = _.filter (_.keys info), (id) -> info[id].old_position? and info[id].new_position < info[id].old_position
		peakers = _.filter (_.keys info), (id) -> info[id].new_position is data[id].peak_position and info[id].old_position? and info[id].new_position < info[id].old_position
		rising_stars = _.filter (_.keys info), (id) -> info[id].new_position is data[id].peak_position and info[id].old_position? and info[id].new_position < info[id].old_position and
			_.isEqual data[id].history, (_.sortBy data[id].history, (h) -> -h)
		fallers = _.filter (_.keys info), (id) -> info[id].old_position? and info[id].new_position > info[id].old_position
		unchanged = _.filter (_.keys info), (id) -> info[id].old_position? and info[id].new_position is info[id].old_position

		uppers =  _.filter (_.keys info), (id) ->
			if not data[id] or data[id].history.length < 2 then return false
			zip = _.zip (_.initial data[id].history), (_.tail data[id].history)
			changes = _.map zip, ([from, to]) -> from - to
			ups = _.reduce changes, ((memo, num) -> memo + num), 0
			return ups > 0

		console.log data
		toppers = _.filter (_.keys info), (id) ->
			if not data[id] then return false
			return _.any data[id].history, (h) -> h <= 10

		###
		console.log ""
		console.log "New       : #{new_entries.length}"
		console.log "Up        : #{climbers.length}"
		console.log "Down      : #{fallers.length}"
		console.log "Unchanged : #{unchanged.length}"
		console.log "Total     : #{new_entries.length + climbers.length + fallers.length + unchanged.length}"
		###

		###
		for id in (_.sortBy uppers, (id) -> info[id].new_position - info[id].old_position)
			console.log ""
			console.log "UPPER #{info[id].old_position} -> #{info[id].new_position}"
			console.log data[id].history
			console.log "#{data[id].title}"
			console.log data[id].url
		###

		###
		for id in (_.sortBy peakers, (id) -> info[id].new_position - info[id].old_position)
			console.log ""
			console.log "PEAKER #{info[id].old_position} -> #{info[id].new_position}"
			console.log data[id].history
			console.log "#{data[id].title}"
			console.log data[id].url

		for id in (_.sortBy rising_stars, (id) -> info[id].new_position - info[id].old_position)
			console.log ""
			console.log "RISING STAR #{info[id].old_position} -> #{info[id].new_position}"
			console.log data[id].history
			console.log "#{data[id].title}"
			console.log data[id].url

		for id in (_.sortBy climbers, (id) -> info[id].new_position - info[id].old_position)
			console.log ""
			console.log "CLIMBER #{info[id].old_position} -> #{info[id].new_position}"
			console.log data[id].history
			console.log "#{data[id].title}"
			console.log data[id].url
		###

		current_rising_stars = _.difference (_.union redditup_data.rising_stars, rising_stars), fallers
		current_peakers = _.difference (_.union redditup_data.peakers, peakers), fallers
		current_climbers = _.difference (_.union redditup_data.climbers, climbers), fallers

		redditup_data = 
			current_posts: current_posts
			data: data
			rising_stars: current_rising_stars 
			peakers: current_peakers
			climbers: current_climbers
			uppers: uppers
			toppers: toppers
		fs.writeFileSync "./data/redditup_#{subreddit}.json", JSON.stringify redditup_data

	#request.get(options.url).set('Authorization', 'Bearer ' + options.auth.bearer).end(callback)
	retriever = () -> request.get options, callback

	setInterval retriever, 30000


