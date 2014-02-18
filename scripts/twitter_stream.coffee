# Dependencies:
#   "twit": "1.1.6"

Twit = require "twit"
_ = require 'underscore'
config = 
  consumer_key: process.env.HUBOT_TWITTER_STREAM_CONSUMER_KEY
  consumer_secret: process.env.HUBOT_TWITTER_STREAM_CONSUMER_SECRET
  access_token: process.env.HUBOT_TWITTER_STREAM_ACCESS_TOKEN
  access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET

module.exports = (robot) ->
  twit = undefined
  stream = undefined

  robot.respond /twitter stream (.*)/i, (msg) ->
    unless config.consumer_key
      msg.send "Please set the HUBOT_TWITTER_STREAM_CONSUMER_KEY environment variable."
      return
    unless config.consumer_secret
      msg.send "Please set the HUBOT_TWITTER_STREAM_CONSUMER_SECRET environment variable."
      return
    unless config.access_token
      msg.send "Please set the HUBOT_TWITTER_STREAM_ACCESS_TOKEN environment variable."
      return
    unless config.access_token_secret
      msg.send "Please set the HUBOT_TWITTER_ACCESS_TOKEN_SECRET environment variable."
      return

    filter = msg.match[1]
    unless filter
      msg.send "Please, specify the Twitter stream filter"
      return

    unless twit
      twit = new Twit config

    if stream
      stream.stop();

    if filter.charAt(0) == "@"
      stream = twit.stream("statuses/filter",
        follow: filter.substring(1);
      )
    else
      stream = twit.stream("statuses/filter",
        track: filter
      )

    msg.send "Thank you, I'll filter out Twitter stream as requested: #{filter}"

    stream.on "tweet", (tweet) ->
      msg.send "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
      tweet_text = _.unescape(tweet.text)
      if tweet.entities.urls?
        for url in tweet.entities.urls
          tweet_text = tweet_text.replace(url.url, url.expanded_url)
      if tweet.entities.media?
        for media in tweet.entities.media
          tweet_text = tweet_text.replace(media.url, media.media_url)
      msg.send "@#{tweet.user.screen_name}: #{tweet_text}"
    stream.on "disconnect", (disconnectMessage) ->
      msg.send "I've got disconnected from Twitter stream. Apparently the reason is: #{disconnectMessage}"
    stream.on "reconnect", (request, response, connectInterval) ->
      msg.send "I'll reconnect to Twitter stream in #{connectInterval}ms"
  
  robot.respond /stop twitter stream/i, (msg) ->
    if stream
      stream.stop()
    msg.send "Ok, I'm now disconnected from Twitter stream"
