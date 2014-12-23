Firebase = require 'firebase'
_ = require 'underscore'
async = require 'async'
fs = require 'fs'

top_stories_ref = new Firebase 'https://hacker-news.firebaseio.com/v0/topstories'
item_ref = new Firebase 'https://hacker-news.firebaseio.com/v0/item/'

module.exports = (old_ids, cb) ->

	top_stories_ref.once 'value', (snapshot) ->

		new_post_ids = snapshot.val()

		update_data = (post, callback) ->
			if not _.contains old_ids, post
				item_ref.child(post).once 'value', (snapshot) ->
					item = snapshot.val()
					if item?
						console.log item
						new_info[item.id] =
							title: item.title
							url: item.url
							comments: "https://news.ycombinator.com/item?id=#{item.id}"
						callback()
					else
						callback 'null item'
			else
				callback()

		new_info = {}
		async.each new_post_ids, update_data, (err) ->

			if err? then cb err

			cb err, new_info, new_post_ids
