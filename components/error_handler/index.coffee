_                   = require 'underscore'
fs                  = require 'fs'
jade                = require 'jade'
{ REVEAL_ERRORS }   = require '../../config'

renderTemplate = jade.compile(
  fs.readFileSync(__dirname + '/template.jade')
  { filename: __dirname + '/template.jade' }
)

errorHandler = module.exports = exports = {}

# Since this is the last non-error-handling middleware
# use()d, we assume 404, as nothing else responded.
errorHandler.pageNotFound = (req, res, next) ->
  if req.accepts 'html' # respond with html page
    data = _.extend
      code  : 404
      error : 'Not Found'
      sd    : {}
    , res.locals

    res.send 404, renderTemplate(data)
    return

  if req.accepts 'json' # respond with json
    res.send error: 'Not found'
    return

  # Default to plain-text. send()
  (res.type 'txt').send 'Not found'

# Error-handling middleware
errorHandler.internalError = (err, req, res, next) ->
  detail = if REVEAL_ERRORS then err.message or err.text or err.toString() else null

  data = _.extend
    code   : res.statusCode
    error  : err
    detail : detail
    sd     : {}
  , res.locals

  res.send res.statusCode, renderTemplate(data)

errorHandler.socialAuthError = (err, req, res, next) ->
  if err.toString().match('User Already Exists')
    # Error urls need to be compatible with Gravity
    params =
      if req.url?.indexOf('facebook') > -1
        "?account_created_email=facebook"
      else if req.url?.indexOf('twitter') > -1
        "?account_created_email=twitter"
      else
        "?error=already-signed-up"
    res.redirect "/log_in#{params}"
  else if err.toString().match('Failed to find request token in session')
    res.redirect '/log_in?error=account-not-found'
  else if err.toString().match('twitter denied')
    res.redirect '/log_in?error=twitter-denied'
  else if err.toString().match("Another Account Already Linked: Twitter")
    res.redirect '/user/edit?error=twitter-already-linked'
  else if err.toString().match("Another Account Already Linked: Facebook")
    res.redirect '/user/edit?error=facebook-already-linked'
  else
    res.redirect '/log_in?error=' + err.toString()
