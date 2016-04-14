CocoModel = require './CocoModel'
schema = require 'schemas/models/classroom.schema'
utils = require 'core/utils'

module.exports = class Classroom extends CocoModel
  @className: 'Classroom'
  @schema: schema
  urlRoot: '/db/classroom'
  
  initialize: () ->
    @listenTo @, 'change:aceConfig', @capitalizeLanguageName
    super(arguments...)
    
  capitalizeLanguageName: ->
    language = @get('aceConfig')?.language
    @capitalLanguage = utils.capitalLanguages[language]

  joinWithCode: (code, opts) ->
    options = {
      url: _.result(@, 'url') + '/~/members'
      type: 'POST'
      data: { code: code }
    }
    _.extend options, opts
    @fetch(options)
    
  removeMember: (userID, opts) ->
    options = {
      url: _.result(@, 'url') + '/members'
      type: 'DELETE'
      data: { userID: userID }
    }
    _.extend options, opts
    @fetch(options)
    
  getLevels: (courseID) ->
    courses = @get('courses')
    return [] unless courses
    levels = []
    for course in courses
      if courseID and courseID isnt course._id
        continue
      levels.push(course.levels)
    return _.flatten(levels)

  statsForSessions: (sessions, courseID) ->
    return null unless sessions
    stats = {}
    sessions = sessions.models or sessions
    sessions = _.sortBy sessions, (s) -> s.get('changed')
    levels = @getLevels(courseID)
    levels = (level for level in levels when not _.contains(level.type, 'ladder'))
    levelOriginals = _.pluck(levels, 'original')
    sessionOriginals = (session.get('level').original for session in sessions when session.get('state').complete)
    levelsLeft = _.size(_.difference(levelOriginals, sessionOriginals))
    lastSession = _.last(sessions)
    stats.levels = {
      size: _.size(levels)
      left: levelsLeft
      done: levelsLeft is 0
      numDone: _.size(levels) - levelsLeft
      pctDone: (100 * (_.size(levels) - levelsLeft) / _.size(levels)).toFixed(1) + '%'
      lastPlayed: if lastSession then _.findWhere levels, { original: lastSession.get('level').original } else null
      first: _.first(levels)
      arena: _.find _.values(@get('levels')), (level) -> _.contains(level.type, 'ladder')
    }
    sum = (nums) -> _.reduce(nums, (s, num) -> s + num) or 0
    stats.playtime = sum((session.get('playtime') or 0 for session in sessions))
    return stats
