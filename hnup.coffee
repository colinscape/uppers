Firebase = require 'firebase'
_ = require 'underscore'
async = require 'async'
fs = require 'fs'

module.exports = () ->

	top_stories_ref = new Firebase 'https://hacker-news.firebaseio.com/v0/topstories'
	item_ref = new Firebase 'https://hacker-news.firebaseio.com/v0/item/'

	retriever = () ->

		if not fs.existsSync './data'
			fs.mkdir './data'

		if fs.existsSync './data/hnup.json'
			hnup_json = fs.readFileSync './data/hnup.json'
			hnup_data = JSON.parse hnup_json
			current_posts = hnup_data.current_posts
			data = hnup_data.data
			first = false
		else
			current_posts = []
			hnup_data = 
				rising_stars: []
				climbers: []
				peakers: []
				uppers: []
				toppers: []
				data: {}
				current_posts: []
			data = {}
			first = true

		top_stories_ref.on 'value', (snapshot) ->

			if first
				first = false
				current_posts = snapshot.val()
				return

			# Gather info on the top 100.
			info = {}
			posts = snapshot.val()


			get_details = (post, callback) ->
				if not data[post]?
					item_ref.child(post).once 'value', (snapshot) ->
						item = snapshot.val()
						if item?
							data[item.id] =
								title: item.title
								url: item.url
								entry_at: null
								history: []
								peak_position: null
							callback()
						else
							callback 'null item'
				else
					callback()

			async.each posts, get_details, (err) ->

				if err? then return

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

				current_rising_stars = _.difference (_.union hnup_data.rising_stars, rising_stars), fallers
				current_peakers = _.difference (_.union hnup_data.peakers, peakers), fallers
				current_climbers = _.difference (_.union hnup_data.climbers, climbers), fallers

				hnup_data = 
					current_posts: current_posts
					data: data
					rising_stars: current_rising_stars 
					peakers: current_peakers
					climbers: current_climbers
					uppers: uppers
					toppers: toppers
				fs.writeFileSync './data/hnup.json', JSON.stringify hnup_data
					

	retriever()
