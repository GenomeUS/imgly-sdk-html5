###
  ImglyKit
  Copyright (c) 2013-2014 img.ly
###
$            = require "jquery"
EventEmitter = require("events").EventEmitter
class UIControlsBase extends EventEmitter
  allowMultipleClick: true
  ###
    @param {imglyUtil} app
    @param {imglyUtil.UI} ui
  ###
  constructor: (@app, @ui, @controls) ->
    @domCreated = false
    @options ?= {}
    @options.backButton ?= true
    @options.showList   ?= true

    @Touch= 
    	 
    	  horizontal_sensitivity: 10
    	  vertical_sensitivity: 10
    	  touchDX: 0
    	  touchDY: 0
    	  touchStartX: 0
    	  touchStartY: 0
    	 
    	  bind: (elements...) ->
    	    for elem in elements
    	      elem.addEventListener "touchstart", (event) =>
    	       @handleStart(event, elem)
    	      elem.addEventListener "touchmove", (event) =>
    	       @handleMove(event, elem)
    	      elem.addEventListener "touchend", (event) =>
    	       @handleEnd(event, elem)
    	 
    	  emitSlideLeft: -> @emit 'swipe:left'
    	  emitSlideRight: -> @emit 'swipe:right'
    	  emitSlideUp: -> @emit 'swipe:up'
    	  emitSlideDown: -> @emit 'swipe:down'
    	 
    	  handleStart: (event, elem) ->
    	    if event.touches.length is 1
    	      @touchDX = 0
    	      @touchDY = 0
    	      @touchStartX = event.touches[0].pageX
    	      @touchStartY = event.touches[0].pageY
    	      # console.log "X Start: " + @touchStartX + ", Y Start: " + @touchStartY
    	 
    	  handleMove: (event, elem) ->
    	    event.preventDefault()
    	    if event.touches.length > 1
    	      @cancelTouch(elem)
    	      return false
    	 
    	    @touchDX = event.touches[0].pageX - @touchStartX
    	    @touchDY = event.touches[0].pageY - @touchStartY
    	    # console.log "X: " + @touchDX + ", Y: " + @touchDY
    	 
    	  handleEnd: (event,elem) ->
    	    dx = Math.abs(@touchDX)
    	    dy = Math.abs(@touchDY)
    	 
    	    if (dx > @horizontal_sensitivity) and (dy < (dx * 2 / 3))
    	      if @touchDX > 0 then @emitSlideRight() else @emitSlideLeft()
    	    
    	    if (dy > @vertical_sensitivity) and (dx < (dy * 2 / 3))
    	      if @touchDY > 0 then @emitSlideDown() else @emitSlideUp()
    	      
    	    # console.log "X End: " + dx + ", Y End: " + dy  
    	      
    	    @cancelTouch(event, elem)
    	    false
    	 
    	  cancelTouch: (event, elem) ->
    	    elem.removeEventListener('touchmove', @handleTouchMove, false)
    	    elem.removeEventListener('touchend', @handleTouchEnd, false)
    	    true
    	 
    	for key, value of new EventEmitter()
    	  @Touch[key] = value
    		
  ###
    @param {imglyUtil.Operations.Operation}
  ###
  setOperation: (@operation) -> return

  ###
    @param {Object} options
  ###
  init: (options) -> return

  ###
    Handle visibility
  ###
  show: (cb) -> @wrapper.fadeIn "fast", cb
  hide: (cb) -> @wrapper.fadeOut "fast", cb

  ###
    Returns to the default view
  ###
  reset: ->
    return

  ###
    Create "Back" and "Done" buttons
  ###
  createButtons: ->
    @buttons ?= {}

    ###
      "Back" Button
    ###
    if @options.backButton
      back = $("<div>")
        .addClass(ImglyKit.classPrefix + "controls-button-back")
        .appendTo @wrapper

      back.click =>
        @emit "back"

      @buttons.back = back

    ###
      "Done" Button
    ###
    done = $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-button-done")
      .appendTo @wrapper

    done.click =>
      @emit "done"

    @buttons.done = done

  remove: ->
    @wrapper.remove()

module.exports = UIControlsBase
