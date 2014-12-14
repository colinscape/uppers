
_ = require 'underscore'
request = require 'request'
async = require 'async'
fs = require 'fs'

module.exports = () ->

	options =
		url: 'https://api.producthunt.com/v1/posts'
		auth:
			bearer: 'fb5efc24cfbb216ebb9a719804457b7074f8866fe13b3b802869c624209e6657'


	retriever = () ->

		if not fs.existsSync './data'
			fs.mkdir './data'

		if fs.existsSync './data/phup.json'
			phup_json = fs.readFileSync './data/phup.json'
			phup_data = JSON.parse phup_json
			current_posts = phup_data.current_posts
			data = phup_data.data
			first = false
		else
			current_posts = []
			phup_data = 
				rising_stars: []
				climbers: []
				peakers: []
				data: {}
				current_posts: []
			data = {}
			first = true

		callback = (err, resp, body) ->
			response = JSON.parse body
			posts = response.posts
			

			# Gather info on the top 100.
			info = {}


			posts = _.sortBy posts, (post) -> -post.votes_count
			for post in posts

				if not data[post.id]?
					data[post.id] = 
						title: post.name
						url: post.redirect_url
						entry_at: null
						history: []
						peak_position: null

			posts = _.pluck posts, 'id'
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

			###
			console.log ""
			console.log "New       : #{new_entries.length}"
			console.log "Up        : #{climbers.length}"
			console.log "Down      : #{fallers.length}"
			console.log "Unchanged : #{unchanged.length}"
			console.log "Total     : #{new_entries.length + climbers.length + fallers.length + unchanged.length}"
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

			current_rising_stars = _.difference (_.union phup_data.rising_stars, rising_stars), fallers
			current_peakers = _.difference (_.union phup_data.peakers, peakers), fallers
			current_climbers = _.difference (_.union phup_data.climbers, climbers), fallers

			phup_data = 
				current_posts: current_posts
				data: data
				rising_stars: current_rising_stars 
				peakers: current_peakers
				climbers: current_climbers
			fs.writeFileSync './data/phup.json', JSON.stringify phup_data
					
		request.get options, callback
	retriever()
	setInterval retriever, 30000

