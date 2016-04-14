CocoCollection = require 'collections/CocoCollection'
Level = require 'models/Level'

module.exports = class LevelCollection extends CocoCollection
  url: '/db/level'
  model: Level

  fetchForClassroom: (classroomID, options={}) ->
    options.url = "/db/classroom/#{classroomID}/levels"
    @fetch(options)
    