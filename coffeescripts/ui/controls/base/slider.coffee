###
  ImglyKit
  Copyright (c) 2013-2014 img.ly
###
$    = require "jquery"
Base = require "./base.coffee"
EventEmitter = require("events").EventEmitter
class UIControlsBaseSlider extends Base
  init: ->
    spaceForPlusAndMinus = 60

    width = @controls.getContainer().width()
    width -= @controls.getHeight() * 2 # Button width == Controls height
    width -= spaceForPlusAndMinus

    @Touch= 
    	 
    	  horizontal_sensitivity: 10
    	  vertical_sensitivity: 6
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
    
    	  
    # Create the slider DOM tree
    @wrapper = $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-wrapper")
      .attr("id", ImglyKit.classPrefix + "controls-wrapper")
      .attr("data-control", @constructor.name)
      .appendTo @controls.getContainer()

    @sliderWrapper = $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-slider-wrapper")
      .attr("id", ImglyKit.classPrefix + "controls-slider-wrapper")
      .width(width)
      .appendTo @wrapper

    @sliderCenterDot = $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-slider-dot")
      .attr("id", ImglyKit.classPrefix + "controls-slider-dot")
      .appendTo @sliderWrapper

    @sliderBar = $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-slider-bar")
      .attr("id", ImglyKit.classPrefix + "controls-slider-bar")
      .appendTo @sliderWrapper

    @slider = $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-slider")
      .attr("id", ImglyKit.classPrefix + "controls-slider")
      .css(left: width / 2)
      .appendTo @sliderWrapper
          
    ###
      Plus / Minus images
    ###
    $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-slider-plus")
      .appendTo @sliderWrapper

    $("<div>")
      .addClass(ImglyKit.classPrefix + "controls-slider-minus")
      .appendTo @sliderWrapper
    
    @handleSliderControl()
    @createButtons()
    
    # Binding slider to touch events (swipe left and right only, we do not need other events)
    
    @Touch.bind document.getElementById 'imgly-controls-slider'
    @Touch.on 'swipe:left', => @handleLeftSwipe()
    @Touch.on 'swipe:right', => @handleRightSwipe()
  
  # Handles swiping to the right  
    
  handleRightSwipe: -> 
    # console.log 'Swiped right! ' + "From "  + @Touch.touchStartX + " to " + @Touch.touchDX
    @sliderWidth = @sliderWrapper.width()
    @currentSliderLeft = parseInt @slider.css("left")
    sliderLeft = Math.min(Math.max(0, @currentSliderLeft + @Touch.touchDX), @sliderWidth) - 10
    if sliderLeft < @sliderWidth and sliderLeft > 0
      @Touch.touchDX = @Touch.touchDX
      @currentSliderLeft = sliderLeft

    @setSliderLeft sliderLeft
    
    
    # Handles swiping to the right
    
  handleLeftSwipe: ->
    # console.log 'Swiped left! ' + "From "  + @Touch.touchStartX + " to " + @Touch.touchDX
    @sliderWidth = @sliderWrapper.width()
    @currentSliderLeft = parseInt @slider.css("left")
    sliderLeft = Math.min(Math.max(0, @currentSliderLeft + @Touch.touchDX), @sliderWidth) - 10
    if sliderLeft < @sliderWidth and sliderLeft > 0
      @Touch.touchDX = @Touch.touchDX
      @currentSliderLeft = sliderLeft

    @setSliderLeft sliderLeft
    
  ###
    Handles slider dragging
  ###
  handleSliderControl: ->
    @sliderWidth = @sliderWrapper.width()

    @slider.mousedown (e) =>
      @lastX = e.clientX
      @currentSliderLeft = parseInt @slider.css("left")

      $(document).mousemove @onMouseMove
      $(document).mouseup @onMouseUp

  ###
    Is called when the slider has been moved

    @param {Integer} left
  ###
  setSliderLeft: (left) ->
    @slider.css left: left

    # Slider is left of center
    if left < @sliderWidth / 2
      barWidth = @sliderWidth / 2 - left
      @sliderBar.css
        left: left
        width: barWidth
    else
      barWidth = left - @sliderWidth / 2
      @sliderBar.css
        left: @sliderWidth / 2
        width: barWidth

    # Normalize to -1 to 1
    normalized = (left - @sliderWidth / 2) / @sliderWidth * 2

    # Set the new value
    @operation[@valueSetMethod].apply @operation, [normalized]
    @app.getPhotoProcessor().renderPreview()

  ###
    Is called when the slider has been pressed and is being dragged

    @param {MouseEvent} e
  ###
  onMouseMove: (e) =>
    curX = e.clientX
    deltaX = curX - @lastX

    sliderLeft = Math.min(Math.max(0, @currentSliderLeft + deltaX), @sliderWidth)

    if sliderLeft < @sliderWidth and sliderLeft > 0
      @lastX = curX
      @currentSliderLeft = sliderLeft

    @setSliderLeft sliderLeft

  ###
    Is called when the slider has been pressed and is being dragged

    @param {MouseEvent} e
  ###
  onMouseUp: (e) =>
    $(document).off "mouseup", @onMouseUp
    $(document).off "mousemove", @onMouseMove
    
module.exports = UIControlsBaseSlider
