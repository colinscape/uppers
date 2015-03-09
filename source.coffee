_ = require 'underscore'
async = require 'async'
fs = require 'fs'

class Source

	constructor: (@app, @name, @title, @template, @retriever, @interval) ->

		if not fs.existsSync './data'
			fs.mkdirSync './data'

		if fs.existsSync "./data/#{@name}.json"
			json = fs.readFileSync "./data/#{@name}.json"
			info = JSON.parse json
			@data = info.data
			@current_post_ids = info.current_post_ids
			@newcomers = info.newcomers
			@climbers = info.climbers
			@unchanged = info.unchanged
			@fallers = info.fallers
			@hidden_gems = info.hidden_gems
			@peakers = info.peakers
			@rising_stars = info.rising_stars
			@interesting = info.interesting
		else
			@data = {}
			@current_post_ids = []
			@newcomers = []
			@climbers = []
			@unchanged = []
			@fallers = []
			@hidden_gems = []
			@peakers = []
			@rising_stars = []
			@interesting = []
			@save []

		setInterval (_.bind @update, this), @interval


		app.get "/#{name}" , (req, res) =>
			if not @interesting? or @interesting.length is 0 then return res.send "No data yet! Check back soon :)"

			newcomers = @newcomers

			climbers = @climbers
			unchanged = @unchanged
			fallers = @fallers
			hidden_gems = @hidden_gems

			peakers = @peakers
			rising_stars = @rising_stars

			_.each @data, (v) -> v.tags = []
			_.map newcomers, (c) => @data[c].tags.push 'newcomer'
			_.map climbers, (c) => @data[c].tags.push 'climber'
			_.map peakers, (c) => @data[c].tags.push 'peaker'
			_.map rising_stars, (c) => @data[c].tags.push 'rising-star'
			_.map hidden_gems, (c) => @data[c].tags.push 'hidden-gem'

			items = _.values _.pick @data, @interesting
			items = _.sortBy items, (i) -> -1000*i.tags.length - i.peak_position

			res.render @template,
				title: @title
				items: items


	update: () ->
		old_post_ids = _.clone @current_post_ids
		@retriever @current_post_ids, (err, new_info, current_post_ids) =>

			if err? then return

			for id, info of new_info
				@data[id] = info

			@current_post_ids = current_post_ids

			_.each current_post_ids, (id, index) =>

				if not @data[id].history? then @data[id].history = []
				@data[id].history.push (index+1)
				
				if not @data[id].peak_position? or @data[id].peak_position > (index+1) then @data[id].peak_position = (index+1)

			@save old_post_ids

	save: (old_post_ids) ->

		@newcomers = _.difference @current_post_ids, old_post_ids
		dropouts = _.difference old_post_ids, @current_post_ids
		_.each dropouts, ((id) -> delete @data[id]), this

		@climbers = _.filter @current_post_ids, (id) =>
			current_position = _.last @data[id].history
			previous_position = _.last (_.without @data[id].history, current_position)
			return not previous_position? or previous_position > (current_position + 1)
		@unchanged = _.filter @current_post_ids, (id) => (@data[id].history.length > 1) and (_.last @data[id].history) is (_.last _.initial @data[id].history)
		@fallers = _.filter @current_post_ids, (id) =>
			current_position = _.last @data[id].history
			previous_position = _.last (_.without @data[id].history, current_position)
			return not previous_position? or previous_position < (current_position - 1)
		@hidden_gems = @current_post_ids[30..]

		@peakers = _.filter @current_post_ids, (id) => (_.last @data[id].history) is @data[id].peak_position

		@rising_stars = _.filter @current_post_ids, (id) => (@data[id].history.length) > 1 and
			_.isEqual @data[id].history, (_.sortBy @data[id].history, (h) => -h)

		@interesting = _.union @newcomers, @climbers, @peakers, @rising_stars

		info = 
			data: @data
			current_post_ids: @current_post_ids
			newcomers: @newcomers
			climbers: @climbers
			unchanged: @unchanged
			fallers: @fallers
			hidden_gems: @hidden_gems
			peakers: @peakers
			rising_stars: @rising_stars
			interesting: @interesting

		fs.writeFileSync "./data/#{@name}.json", JSON.stringify info

module.exports = Source
