###
  ImglyKit
  Copyright (c) 2013-2014 img.ly
###
$            = require "jquery"
Overview     = require "./controls/overview.coffee"
EventEmitter = require("events").EventEmitter
class UIControls extends EventEmitter
  ###
    @param {imglyUtil} app
    @param {imglyUtil.UI} ui
  ###
  constructor: (@app, @ui) ->
    @container = @app.getContainer()
    @init()

  ###
    @returns {Integer} Height of the controls container
  ###
  getHeight: -> @controlsContainer.height()

  ###
    @returns {jQuery.Object} The controls container
  ###
  getContainer: -> @controlsContainer

  ###
    @returns {ImglyKit.UI.Controls.Base}
  ###
  getCurrentControls: -> @currentControls

  ###
    Initializes the container
  ###
  init: ->
    # Create controls container
    @controlsContainer = $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-container")
      .appendTo @container

    @initOverview()
    @createUndoButton()
    @app.getPhotoProcessor().on "operation_chain_changed", @updateUndoState

  ###
    Initialize the overview
  ###
  initOverview: ->
    @currentControls = @overview = new Overview @app, @ui, this
    @attachEvents @currentControls

    @overview.init()
    unless @app.options.initialControls?
      @overview.show()

  ###
    Attach select events
  ###
  attachEvents: (controls) ->
    controls.on "select", (option) =>
      if option.controls?
        @switchToControls option.controls, controls

      if option.operation?
        @emit "preview_operation", new option.operation(@app, option.options)

    controls.on "back", =>
      @emit "back"

    controls.on "done", =>
      @emit "done"

    controls.on "renderPreview", =>
      @app.getPhotoProcessor().renderPreview()


  ###
    Switch to another controls instance
  ###
  switchToControls: (controlsClass, oldControls, options={}) ->
    @currentControls = new controlsClass @app, @ui, this

    # Apply options
    for key, value of options
      @currentControls.options[key] = value

    @attachEvents @currentControls

    if @currentControls.hasCanvasControls
      canvasControlsContainer = @ui.getCanvas().getControlsContainer()
      @currentControls.setupCanvasControls canvasControlsContainer
      canvasControlsContainer.fadeIn "slow"

    @currentControls.init()
    oldControls.hide =>
      @currentControls.show()

  ###
    Creates the undo button
  ###
  createUndoButton: ->
    @undoButton = $("<div>")
      .addClass("#{ImglyKit.classPrefix}undo #{ImglyKit.classPrefix}disabled")
      .appendTo @container

    @undoButton.click @onUndoClick

  ###
    Gets called when the user clicks the undo button
  ###
  onUndoClick: (e) =>
    e.preventDefault()

    @app.getPhotoProcessor().undo()

  ###
    Updates the undo state (active / inactive)
  ###
  updateUndoState: =>
    disabled = !@app.getPhotoProcessor().isUndoPossible()
    @undoButton.toggleClass "#{ImglyKit.classPrefix}disabled", disabled

  ###
    Returns to the default view
  ###
  reset: ->
    @overview.reset()
    @ui.getCanvas().getControlsContainer().hide().html ""

    @currentControls?.hide =>
      @currentControls.remove()
      @overview.show()

module.exports = UIControls
