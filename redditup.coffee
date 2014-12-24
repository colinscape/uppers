_ = require 'underscore'
ent = require 'ent'
request = require 'request'
fs = require 'fs'



module.exports = (subreddit) ->

	options =
		url: "http://api.reddit.com/r/#{subreddit}/hot.json?limit=100"
		headers:
			'User-Agent': 'topicol-bot/0.1 by colinscape'

	return (old_ids, cb) -> request.get options, (err, resp, body) ->

		if err?
			return console.error "HTTP ERROR #{err}"

		try
			response = JSON.parse body
		catch err
			return console.error "JSON ERROR #{err} when decoding #{body}"
		if not response?
			return console.error "NO JSON RETURNED"
		
		posts = response.data.children
		new_post_ids = _.map posts, (p) -> p.data.id

		new_info = {}
		for post in posts
			if not _.contains old_ids, post.data.id
				new_info[post.data.id] = 
					title: ent.decode post.data.title
					url: post.data.url
					comments: "https://www.reddit.com#{post.permalink}"

		cb null, new_info, new_post_ids




