# interval to keep bot awake

noop = () ->
  console.log "Trying to stay awake"

setInterval noop, 5 * 60 * 1000

module.exports = (robot) ->
  return
