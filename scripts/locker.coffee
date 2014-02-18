# Description:
#   Store values in redis
#
# Commands:
#   hubot save <key> <value>
#   hubot fetch <key>
#


module.exports = (robot) ->
  robot.respond /save ([\S]*) (\")?(.*)(\")?$/i, (msg) ->
    key = msg.match[1]
    value = msg.match[3]
    if robot.brain.data[ key ]
      msg.send("Sorry, there is already something stored in " + key + ".")
      msg.send("If you'd like to override it, use save!")
    else
      robot.brain.data[ key ] = value
      msg.send("Saved! " + key + ": " + value)

  robot.respond /fetch ([\S]*)/i, (msg) ->
    key = msg.match[1]
    if !robot.brain.data[ key ]
      msg.send("Sorry, there is nothing stored in " + key + ".")
    else
      msg.send("Found! " + key + ": " + robot.brain.data[ key ])

  robot.respond /save! ([\S]*) (\")?(.*)(\")?$/i, (msg) ->
    key = msg.match[1]
    value = msg.match[3]
    robot.brain.data[ key ] = value
    msg.send("Saved! " + key + ": " + value)
