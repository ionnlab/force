{ extend } = require 'underscore'
Backbone = require 'backbone'
{ Countries } = require 'places'
Form = require '../form/index.coffee'
stripe = require '../stripe/index.coffee'
template = -> require('./index.jade') arguments...

module.exports = class CreditCardView extends Backbone.View
  className: 'credit-card-form'

  events:
    'input .js-cc-number': 'type'
    'click .js-cancel': 'cancel'
    'click button': 'submit'

  initialize: ->
    stripe.initialize()

  type: (e) ->
    number = $(e.currentTarget).val()
    provider = stripe.cardType number
    (@$type ?= @$('.js-cc-type'))
      .attr 'data-provider', provider

  cancel: (e) ->
    e.preventDefault()
    @trigger 'abort'

  validate: (sensitive, validator) ->
    stripe.validate(sensitive).map ({ name, value }) ->
      $input = @$("[data-stripe='#{name}']")
      if value
        validator.clearValidity $input
      else
        validator.setValidity $input, stripe.error(name)

  submit: (e) ->
    e.preventDefault()

    form = new Form $form: $form = @$('form')

    sensitive = stripe.serialize $form
    @validate sensitive, form.validator

    return unless form.isReady()

    form.state 'loading'

    data = extend {}, sensitive, form.data()

    @__submit__ = stripe.tokenize data
      .then ({ id }) =>
        @collection.create token: id, provider: 'stripe'
      .then =>
        @trigger 'done', arguments...
      .catch (err) ->
        form.error err

  render: ->
    @$el.html template
      countries: Countries
    this