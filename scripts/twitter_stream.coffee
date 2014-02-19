# Dependencies:
#   "twit": "1.1.6"

Twit = require "twit"
_ = require 'underscore'
config = 
  consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
  consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
  access_token: process.env.HUBOT_TWITTER_ACCESS_TOKEN_KEY
  access_token_secret: process.env.HUBOT_TWITTER_ACCESS_TOKEN_SECRET

module.exports = (robot) ->
  twit = undefined
  stream = undefined

  if process.env.HUBOT_IRC_ROOMS
    allRooms = process.env.HUBOT_IRC_ROOMS.split(',')
  else
    allRooms = []

  # Internal: Initialize our brain
  robot.brain.on 'loaded', =>
    streamSettings = robot.brain.data.twitterStream

    if streamSettings
      twit = new Twit config

      if streamSettings.track
        stream = twit.stream("statuses/filter", streamSettings)
      else
        stream = twit.stream("user", streamSettings)

      stream.on "tweet", (tweet) ->
        robot.messageRoom allRooms, "https://twitter.com/#{tweet.user.screen_name}/status/#{tweet.id_str}"
        tweet_text = _.unescape(tweet.text)
        if tweet.entities.urls?
          for url in tweet.entities.urls
            tweet_text = tweet_text.replace(url.url, url.expanded_url)
        if tweet.entities.media?
          for media in tweet.entities.media
            tweet_text = tweet_text.replace(media.url, media.media_url)
        robot.messageRoom allRooms, "@#{tweet.user.screen_name}: #{tweet_text}"
      stream.on "disconnect", (disconnectMessage) ->
        robot.messageRoom allRooms, "I've got disconnected from Twitter stream. Apparently the reason is: #{disconnectMessage}"
      stream.on "reconnect", (request, response, connectInterval) ->
        console.log "I'll reconnect to Twitter stream in #{connectInterval}ms"

  robot.respond /twitter stream (.*)/i, (msg) ->
    unless config.consumer_key
      msg.send "Please set the HUBOT_TWITTER_CONSUMER_KEY environment variable."
      return
    unless config.consumer_secret
      msg.send "Please set the HUBOT_TWITTER_CONSUMER_SECRET environment variable."
      return
    unless config.access_token
      msg.send "Please set the HUBOT_TWITTER_ACCESS_TOKEN_KEY environment variable."
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
      stream.stop()

    settings = {}
    if filter.charAt(0) == "@"
      settings.with = "user"
      stream = twit.stream("user", settings)
    else
      settings.track = filter
      stream = twit.stream("statuses/filter", settings)
    robot.brain.data.twitterStream = settings


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
      console.log "I'll reconnect to Twitter stream in #{connectInterval}ms"
  
  robot.respond /stop twitter stream/i, (msg) ->
    robot.brain.data.twitterStream = null
    if stream
      stream.stop()
    msg.send "Ok, I'm now disconnected from Twitter stream"
