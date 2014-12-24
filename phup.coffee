
_ = require 'underscore'
request = require 'request'
async = require 'async'

options =
	url: 'https://api.producthunt.com/v1/posts'
	auth:
		bearer: 'fb5efc24cfbb216ebb9a719804457b7074f8866fe13b3b802869c624209e6657'

module.exports = (old_ids, cb) ->

	request.get options, (err, resp, body) ->

		if err? then return cb err

		try
			response = JSON.parse body
		catch e
			return cb "Failed to parse JSON"

		posts = response.posts
		new_info = {}
		for post in posts

			if not _.contains old_ids, post.id
				new_info[post.id] = 
					title: post.name
					url: post.redirect_url
					comments: post.discussion_url

		cb null, new_info, (_.pluck posts, 'id')
