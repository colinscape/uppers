_ = require 'underscore'
ent = require 'ent'
request = require 'request'
feedparser = require 'ortoo-feedparser'



module.exports = (old_ids, cb) ->

	options =
		url: "https://lobste.rs/rss"
		headers:
			'User-Agent': 'topicol-bot/0.1 by colinscape'


	request.get options, (err, resp, body) ->

		if err?
			return cb "HTTP ERROR #{err}"

		new_post_ids = []
		new_info = {}
		callback = (article) ->
			new_post_ids.push article.guid

			if not _.contains old_ids, article.guid
				new_info[article.guid] = 
					title: ent.decode article.title
					url: article.link
					comments: article.comments

		feedparser.parseString body
			.on 'article', callback
			.on 'end', () ->
				cb null, new_info, new_post_ids
			.on 'error', cb




