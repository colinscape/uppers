_ = require 'underscore'
ent = require 'ent'
request = require 'request'
feedparser = require 'ortoo-feedparser'



module.exports = (old_ids, cb) ->

	options =
		url: "http://recode.net/feed/"
		headers:
			'User-Agent': 'topicol-bot/0.1 by colinscape'


	request.get options, (err, resp, body) ->

		if err?
			return cb "HTTP ERROR #{err}"

		new_post_ids = []
		new_info = {}
		callback = (article) ->
			console.log article
			new_post_ids.push article.guid

			if not _.contains old_ids, article.guid
				new_info[article.guid] = 
					title: ent.decode article.title
					url: article.link
					comments: article.comments

		console.log "Parsing..."
		feedparser.parseString body
			.on 'article', callback
			.on 'end', () ->
				console.log "Done parsing!"
				cb null, new_info, new_post_ids
			.on 'error', cb




