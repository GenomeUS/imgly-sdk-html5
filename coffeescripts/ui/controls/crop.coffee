###
  ImglyKit
  Copyright (c) 2013-2014 img.ly
###
$       = require "jquery"
List    = require "./base/list.coffee"
Vector2 = require "../../math/vector2.coffee"
Rect    = require "../../math/rect.coffee"
class UIControlsCrop extends List
  displayButtons: true
  minimumCropSize: 50
  singleOperation: true
  ###
    @param {ImglyKit} app
    @param {ImglyKit.UI} ui
    @param {ImglyKit.UI.Controls} controls
  ###
  constructor: (@app, @ui, @controls) ->
    super
    @operationClass = require "../../operations/crop.coffee"
    @listItems = [
      {
        name: "Square"
        cssClass: "square"
        method: "setSize"
        arguments: ["square"]
        tooltip: "Squared crop"
        default: true
        options:
          size: "square"
      }
    ]
    
  updateOptions: (@operationOptions) ->
    @resizeCanvasControls()

  ###
    @param {jQuery.Object} canvasControlsContainer
  ###
  hasCanvasControls: true
  setupCanvasControls: (@canvasControlsContainer) ->
    ###
      Create the dark parts around the cropped area
    ###
    @spotlightDivs = {}
    for position in [
      "tl", "tc", "tr",
      "lc",       "rc",
      "bl", "bc", "br"]
        div = $("<div>")
          .addClass(ImglyKit.classPrefix + "canvas-cropping-spotlight")
          .attr("id", ImglyKit.classPrefix + "controls-wrapper-spotlight-" + position)
          .addClass(ImglyKit.classPrefix + "canvas-cropping-spotlight-" + position)
          .appendTo @canvasControlsContainer

        @spotlightDivs[position] = div

    ###
      Create the center div (cropped area)
    ###
    @centerDiv = $("<div>")
      .addClass(ImglyKit.classPrefix + "canvas-cropping-center")
      .attr("id", ImglyKit.classPrefix + "canvas-cropping-center")
      .appendTo @canvasControlsContainer
      
    ###
      Create the knobs the user can use to resize the cropped area
    ###
    @knobs = {}
    for position in ["tl", "tr", "bl", "br"]
      div = $("<div>")
        .addClass(ImglyKit.classPrefix + "canvas-knob")
        .attr("id", ImglyKit.classPrefix + "canvas-knob-" + position)
        .appendTo @canvasControlsContainer

      @knobs[position] = div
      
    @handleCenterDragging()
    @handleTopLeftKnob()
    @handleBottomRightKnob()
    @handleBottomLeftKnob()
    @handleTopRightKnob()
    
    
    # Binding crop center to touch events
    
    @Touch.bind document.getElementById 'imgly-canvas-cropping-center'
    @Touch.on 'swipe:left', => @handleCenterTouchDragging()
    @Touch.on 'swipe:right', => @handleCenterTouchDragging()
    @Touch.on 'swipe:up', => @handleCenterTouchDragging()
    @Touch.on 'swipe:down', => @handleCenterTouchDragging()
    
    # Binding top left knob to touch events
    ###
    @Touch.bind document.getElementById 'imgly-canvas-knob-tl'
    @Touch.on 'swipe:left', => @handleTopLeftKnobTouchDragging()
    @Touch.on 'swipe:right', => @handleTopLeftKnobTouchDragging()
    @Touch.on 'swipe:up', => @handleTopLeftKnobTouchDragging()
    @Touch.on 'swipe:down', => @handleTopLeftKnobTouchDragging()
    ###
    # Binding bottom right knob to touch events
    ###
    @Touch.bind document.getElementById 'imgly-canvas-knob-br'
    @Touch.on 'swipe:left', => @handleBottomRightKnobTouchDragging()
    @Touch.on 'swipe:right', => @handleBottomRightKnobTouchDragging()
    @Touch.on 'swipe:up', => @handleBottomRightKnobTouchDragging()
    @Touch.on 'swipe:down', => @handleBottomRightKnobTouchDragging()
    ###
    # Binding bottom left knob to touch events
    ###
    @Touch.bind document.getElementById 'imgly-canvas-knob-bl'
    @Touch.on 'swipe:left', => @handleBottomLeftKnobTouchDragging()
    @Touch.on 'swipe:right', => @handleBottomLeftKnobTouchDragging()
    @Touch.on 'swipe:up', => @handleBottomLeftKnobTouchDragging()
    @Touch.on 'swipe:down', => @handleBottomLeftKnobTouchDragging()
    ###
    # Binding top right knob to touch events
    ###
    @Touch.bind document.getElementById 'imgly-canvas-knob-tr'
    @Touch.on 'swipe:left', => @handleTopRightKnobTouchDragging()
    @Touch.on 'swipe:right', => @handleTopRightKnobTouchDragging()
    @Touch.on 'swipe:up', => @handleTopRightKnobTouchDragging()
    @Touch.on 'swipe:down', => @handleTopRightKnobTouchDragging()
    ###
    
  ###
    Handles top left knob touch dragging 
  ###  
  handleTopLeftKnobTouchDragging: -> 
    # console.log "Top left knob dragged from X:"  + @Touch.touchStartX + ",Y:" + @Touch.touchStartY + " to X:" + @Touch.touchDX + ",Y:" + @Touch.touchDY
    knob = @knobs.tl
    canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())
    initialMousePosition  = new Vector2(@Touch.touchStartX, @Touch.touchStartY)
    initialStart          = new Vector2().copy(@operationOptions.start)
    ratio = @operationOptions.ratio
      
    # Touch position difference to initial position
    diffMousePosition = new Vector2((@Touch.touchStartX + @Touch.touchDX), (@Touch.touchStartY + @Touch.touchDY))
      .subtract(initialMousePosition)

    if @operationOptions.ratio is 0
      # Custom cropping, allow free scaling
      @operationOptions.start
        .copy(initialStart)
        .multiplyWithRect(canvasRect)
        .add(diffMousePosition)
        .divideByRect(canvasRect)
    else
      # Turn start and end into pixel values
      endInPixels   = new Vector2().copy(@operationOptions.end).multiplyWithRect(canvasRect)
      startInPixels = new Vector2().copy(initialStart).multiplyWithRect(canvasRect)

      # Increase x by average touch position and clamp to boundaries
      startInPixels.x += (diffMousePosition.x + diffMousePosition.y) / 2
      startInPixels.clamp(1, endInPixels.x - 50)

      # First method: Calculate height by width / ratio
      widthInPixels  = endInPixels.x - startInPixels.x
      heightInPixels = widthInPixels / @operationOptions.ratio

      # If the first method exceeds the upper y boundary,
      # calculate width by height * ratio
      if endInPixels.y - heightInPixels < 1
        heightInPixels = @operationOptions.end.y * canvasRect.height - 1
        widthInPixels  = heightInPixels * @operationOptions.ratio

      # Update the start position
      @operationOptions.start
        .copy(@operationOptions.end)
        .multiplyWithRect(canvasRect)
        .subtract(new Vector2(widthInPixels, heightInPixels))
        .divideByRect(canvasRect)

    @resizeCanvasControls()    
    
  ###
    Handles bottom right knob touch dragging 
  ###  
  handleBottomRightKnobTouchDragging: -> 
    # console.log "Bottom right knob dragged from X:"  + @Touch.touchStartX + ",Y:" + @Touch.touchStartY + " to X:" + @Touch.touchDX + ",Y:" + @Touch.touchDY
    knob = @knobs.br
    canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())
    initialMousePosition  = new Vector2(@Touch.touchStartX, @Touch.touchStartY)
    initialEnd            = new Vector2().copy(@operationOptions.end)
    ratio = @operationOptions.ratio

    # Touch position difference to initial position
    diffMousePosition = new Vector2((@Touch.touchStartX + @Touch.touchDX), (@Touch.touchStartY + @Touch.touchDY))
      .subtract(initialMousePosition)

    # Turn start and end into pixel values
    endInPixels   = new Vector2().copy(initialEnd).multiplyWithRect(canvasRect)
    startInPixels = new Vector2().copy(@operationOptions.start).multiplyWithRect(canvasRect)

    if @operationOptions.ratio is 0
      # Custom cropping, allow free scaling
      @operationOptions.end
        .copy(endInPixels)
        .add(diffMousePosition)
        .clamp(
          new Vector2(startInPixels.x + 50, startInPixels.y + 50),
          new Vector2(canvasRect.width - 1, canvasRect.height - 1)
        )
        .divideByRect(canvasRect)

        {width, height} = @app.ui.getCanvas().getImageData()
        widthInPixels  = endInPixels.x - startInPixels.x

    else
      # Increase x by average touch position and clamp to boundaries
      endInPixels.x += (diffMousePosition.x + diffMousePosition.y) / 2
      endInPixels.clamp(startInPixels.x + 50, canvasRect.width - 1)

      # First method: Calculate height by width / ratio
      widthInPixels  = endInPixels.x - startInPixels.x
      heightInPixels = widthInPixels / @operationOptions.ratio

      # If the first method exceeds the upper y boundary,
      # calculate width by height * ratio
      if startInPixels.y + heightInPixels > canvasRect.height - 1
        heightInPixels = (1 - @operationOptions.start.y) * canvasRect.height - 1
        widthInPixels  = heightInPixels * @operationOptions.ratio

      # Update the start position
      @operationOptions.end
        .copy(@operationOptions.start)
        .multiplyWithRect(canvasRect)
        .add(new Vector2(widthInPixels, heightInPixels))
        .divideByRect(canvasRect)
        
    @resizeCanvasControls()
    
  ###
    Handles bottom left knob touch dragging 
  ###  
  handleBottomLeftKnobTouchDragging: -> 
    # console.log "Bottom left knob dragged from X:"  + @Touch.touchStartX + ",Y:" + @Touch.touchStartY + " to X:" + @Touch.touchDX + ",Y:" + @Touch.touchDY
    knob = @knobs.bl
    canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())
    initialMousePosition  = new Vector2(@Touch.touchStartX, @Touch.touchStartY)
    initialStart          = @operationOptions.start.clone()
    initialEnd            = @operationOptions.end.clone()
    ratio = @operationOptions.ratio
    
    # Touch position difference to initial position
    diffMousePosition = new Vector2((@Touch.touchStartX + @Touch.touchDX), (@Touch.touchStartY + @Touch.touchDY))
      .subtract(initialMousePosition)

    # Turn start and end into pixel values
    endInPixels   = new Vector2().copy(initialEnd).multiplyWithRect(canvasRect)
    startInPixels = new Vector2().copy(initialStart).multiplyWithRect(canvasRect)

    if @operationOptions.ratio is 0
      # Custom cropping, allow free scaling
      @operationOptions.end.copy(endInPixels)

      @operationOptions.end.y   += diffMousePosition.y
      @operationOptions.end.clamp(
        new Vector2(endInPixels.x, startInPixels.y + 50),
        new Vector2(endInPixels.x, canvasRect.height - 1)
      ).divideByRect(canvasRect)

      @operationOptions.start.copy(startInPixels)
      @operationOptions.start.x += diffMousePosition.x
      @operationOptions.start.clamp(
        new Vector2(1, 1),
        new Vector2(endInPixels.x - 50, endInPixels.y - 50)
      ).divideByRect(canvasRect)
    else
      # Increase x by average touch position and clamp to boundaries
      startInPixels.x += (diffMousePosition.x - diffMousePosition.y) / 2
      startInPixels.clamp(1, endInPixels.x - 50)

      # First method: Calculate height by width / ratio
      widthInPixels  = endInPixels.x - startInPixels.x
      heightInPixels = widthInPixels / @operationOptions.ratio

      # If the first method exceeds the upper y boundary,
      # calculate width by height * ratio
      if startInPixels.y + heightInPixels > canvasRect.height - 1
        heightInPixels = (1 - @operationOptions.start.y) * canvasRect.height - 1
        widthInPixels  = heightInPixels * @operationOptions.ratio

      # Update the start position
      @operationOptions.start.x = (endInPixels.x - widthInPixels) / canvasRect.width
      @operationOptions.end.y   = (startInPixels.y + heightInPixels) / canvasRect.height

    @resizeCanvasControls()    
    
  ###
    Handles top right knob touch dragging 
  ###  
  handleTopRightKnobTouchDragging: -> 
    # console.log "Top right knob dragged from X:"  + @Touch.touchStartX + ",Y:" + @Touch.touchStartY + " to X:" + @Touch.touchDX + ",Y:" + @Touch.touchDY
    knob = @knobs.tr
    canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())
    initialMousePosition  = new Vector2(@Touch.touchStartX, @Touch.touchStartY)
    initialStart          = @operationOptions.start.clone()
    initialEnd            = @operationOptions.end.clone()
    ratio = @operationOptions.ratio
    
    # Touch position difference to initial position
    diffMousePosition = new Vector2((@Touch.touchStartX + @Touch.touchDX), (@Touch.touchStartY + @Touch.touchDY))
      .subtract(initialMousePosition)

    # Turn start and end into pixel values
    endInPixels   = new Vector2().copy(initialEnd).multiplyWithRect(canvasRect)
    startInPixels = new Vector2().copy(initialStart).multiplyWithRect(canvasRect)

    if @operationOptions.ratio is 0
      # Custom cropping, allow free scaling
      @operationOptions.start.copy(startInPixels)

      @operationOptions.start.y   += diffMousePosition.y
      @operationOptions.start.clamp(
        new Vector2(startInPixels.x, 1),
        new Vector2(startInPixels.x, endInPixels.y - 50)
      ).divideByRect(canvasRect)

      @operationOptions.end.copy(endInPixels)
      @operationOptions.end.x += diffMousePosition.x
      @operationOptions.end.clamp(
        new Vector2(startInPixels.x + 50, endInPixels.y),
        new Vector2(canvasRect.width - 1, endInPixels.y)
      ).divideByRect(canvasRect)
    else
      # Increase x by average touch position and clamp to boundaries
      endInPixels.x += (diffMousePosition.x - diffMousePosition.y) / 2
      endInPixels.clamp(startInPixels.x + 50, canvasRect.width - 1)

      # First method: Calculate height by width / ratio
      widthInPixels  = endInPixels.x - startInPixels.x
      heightInPixels = widthInPixels / @operationOptions.ratio

      # If the first method exceeds the upper y boundary,
      # calculate width by height * ratio
      if endInPixels.y - heightInPixels < 1
        heightInPixels = @operationOptions.end.y * canvasRect.height - 1
        widthInPixels  = heightInPixels * @operationOptions.ratio

      # Update the start position
      @operationOptions.end.x   = (startInPixels.x + widthInPixels) / canvasRect.width
      @operationOptions.start.y = (endInPixels.y   - heightInPixels) / canvasRect.height

    @resizeCanvasControls()
    
  ###
    Handles crop center touch dragging 
  ###  
  handleCenterTouchDragging: -> 
    # console.log "Center dragged from X:"  + @Touch.touchStartX + ",Y:" + @Touch.touchStartY + " to X:" + @Touch.touchDX + ",Y:" + @Touch.touchDY
    canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())
    min = new Vector2(1, 1)
    max = new Vector2(
      canvasRect.width  - @centerDiv.width() - 1,
      canvasRect.height - @centerDiv.height() - 1
    )

    initialMousePosition  = new Vector2(@Touch.touchStartX, @Touch.touchStartY)
    initialStart          = new Vector2().copy(@operationOptions.start)
    initialEnd            = new Vector2().copy(@operationOptions.end)

    centerRect = new Rect(0, 0, @centerDiv.width(), @centerDiv.height())
    currentMousePosition = new Vector2( (@Touch.touchStartX + @Touch.touchDX), (@Touch.touchStartY + @Touch.touchDY) )

    # Normalized touch position
    diffMousePosition = new Vector2()
      .copy(currentMousePosition)
      .subtract(initialMousePosition)

    # Calculate new start vector
    @operationOptions.start
      .copy(initialStart)
      .multiplyWithRect(canvasRect)
      .add(diffMousePosition)
      .clamp(min, max)
      .divideByRect(canvasRect)

    # Calculate the end position relatively
    # to the start position
    @operationOptions.end
      .copy(@operationOptions.start)
      .multiplyWithRect(canvasRect)
      .addRect(centerRect)
      .divideByRect(canvasRect)

    @resizeCanvasControls()
    
    
  ###
    Handles the dragging of the upper right knob
  ###
  handleTopRightKnob: ->
    knob = @knobs.tr
    knob.mousedown (e) =>
      canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())

      initialMousePosition  = new Vector2(e.clientX, e.clientY)
      initialStart          = @operationOptions.start.clone()
      initialEnd            = @operationOptions.end.clone()

      ratio = @operationOptions.ratio

      $(document).mouseup (e) =>
        $(document).off "mouseup"
        $(document).off "mousemove"

      $(document).mousemove (e) =>
        # Mouse position difference to initial position
        diffMousePosition = new Vector2(e.clientX, e.clientY)
          .subtract(initialMousePosition)

        # Turn start and end into pixel values
        endInPixels   = new Vector2().copy(initialEnd).multiplyWithRect(canvasRect)
        startInPixels = new Vector2().copy(initialStart).multiplyWithRect(canvasRect)

        if @operationOptions.ratio is 0
          # Custom cropping, allow free scaling
          @operationOptions.start.copy(startInPixels)

          @operationOptions.start.y   += diffMousePosition.y
          @operationOptions.start.clamp(
            new Vector2(startInPixels.x, 1),
            new Vector2(startInPixels.x, endInPixels.y - 50)
          ).divideByRect(canvasRect)

          @operationOptions.end.copy(endInPixels)
          @operationOptions.end.x += diffMousePosition.x
          @operationOptions.end.clamp(
            new Vector2(startInPixels.x + 50, endInPixels.y),
            new Vector2(canvasRect.width - 1, endInPixels.y)
          ).divideByRect(canvasRect)
        else
          # Increase x by average mouse position and clamp to boundaries
          endInPixels.x += (diffMousePosition.x - diffMousePosition.y) / 2
          endInPixels.clamp(startInPixels.x + 50, canvasRect.width - 1)

          # First method: Calculate height by width / ratio
          widthInPixels  = endInPixels.x - startInPixels.x
          heightInPixels = widthInPixels / @operationOptions.ratio

          # If the first method exceeds the upper y boundary,
          # calculate width by height * ratio
          if endInPixels.y - heightInPixels < 1
            heightInPixels = @operationOptions.end.y * canvasRect.height - 1
            widthInPixels  = heightInPixels * @operationOptions.ratio

          # Update the start position
          @operationOptions.end.x   = (startInPixels.x + widthInPixels) / canvasRect.width
          @operationOptions.start.y = (endInPixels.y   - heightInPixels) / canvasRect.height

        @resizeCanvasControls()

  ###
    Handles the dragging of the lower left knob
  ###
  handleBottomLeftKnob: ->
    knob = @knobs.bl
    knob.mousedown (e) =>
      canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())

      initialMousePosition  = new Vector2(e.clientX, e.clientY)
      initialStart          = @operationOptions.start.clone()
      initialEnd            = @operationOptions.end.clone()

      ratio = @operationOptions.ratio

      $(document).mouseup (e) =>
        $(document).off "mouseup"
        $(document).off "mousemove"

      $(document).mousemove (e) =>
        # Mouse position difference to initial position
        diffMousePosition = new Vector2(e.clientX, e.clientY)
          .subtract(initialMousePosition)

        # Turn start and end into pixel values
        endInPixels   = new Vector2().copy(initialEnd).multiplyWithRect(canvasRect)
        startInPixels = new Vector2().copy(initialStart).multiplyWithRect(canvasRect)

        if @operationOptions.ratio is 0
          # Custom cropping, allow free scaling
          @operationOptions.end.copy(endInPixels)

          @operationOptions.end.y   += diffMousePosition.y
          @operationOptions.end.clamp(
            new Vector2(endInPixels.x, startInPixels.y + 50),
            new Vector2(endInPixels.x, canvasRect.height - 1)
          ).divideByRect(canvasRect)

          @operationOptions.start.copy(startInPixels)
          @operationOptions.start.x += diffMousePosition.x
          @operationOptions.start.clamp(
            new Vector2(1, 1),
            new Vector2(endInPixels.x - 50, endInPixels.y - 50)
          ).divideByRect(canvasRect)
        else
          # Increase x by average mouse position and clamp to boundaries
          startInPixels.x += (diffMousePosition.x - diffMousePosition.y) / 2
          startInPixels.clamp(1, endInPixels.x - 50)

          # First method: Calculate height by width / ratio
          widthInPixels  = endInPixels.x - startInPixels.x
          heightInPixels = widthInPixels / @operationOptions.ratio

          # If the first method exceeds the upper y boundary,
          # calculate width by height * ratio
          if startInPixels.y + heightInPixels > canvasRect.height - 1
            heightInPixels = (1 - @operationOptions.start.y) * canvasRect.height - 1
            widthInPixels  = heightInPixels * @operationOptions.ratio

          # Update the start position
          @operationOptions.start.x = (endInPixels.x - widthInPixels) / canvasRect.width
          @operationOptions.end.y   = (startInPixels.y + heightInPixels) / canvasRect.height

        @resizeCanvasControls()

  ###
    Handles the dragging of the lower right knob
  ###
  handleBottomRightKnob: ->
    knob = @knobs.br
    knob.mousedown (e) =>
      canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())

      initialMousePosition  = new Vector2(e.clientX, e.clientY)
      initialEnd            = new Vector2().copy(@operationOptions.end)

      ratio = @operationOptions.ratio

      $(document).mouseup (e) =>
        $(document).off "mouseup"
        $(document).off "mousemove"

      $(document).mousemove (e) =>
        # Mouse position difference to initial position
        diffMousePosition = new Vector2(e.clientX, e.clientY)
          .subtract(initialMousePosition)

        # Turn start and end into pixel values
        endInPixels   = new Vector2().copy(initialEnd).multiplyWithRect(canvasRect)
        startInPixels = new Vector2().copy(@operationOptions.start).multiplyWithRect(canvasRect)

        if @operationOptions.ratio is 0
          # Custom cropping, allow free scaling
          @operationOptions.end
            .copy(endInPixels)
            .add(diffMousePosition)
            .clamp(
              new Vector2(startInPixels.x + 50, startInPixels.y + 50),
              new Vector2(canvasRect.width - 1, canvasRect.height - 1)
            )
            .divideByRect(canvasRect)

            {width, height} = @app.ui.getCanvas().getImageData()
            widthInPixels  = endInPixels.x - startInPixels.x

        else
          # Increase x by average mouse position and clamp to boundaries
          endInPixels.x += (diffMousePosition.x + diffMousePosition.y) / 2
          endInPixels.clamp(startInPixels.x + 50, canvasRect.width - 1)

          # First method: Calculate height by width / ratio
          widthInPixels  = endInPixels.x - startInPixels.x
          heightInPixels = widthInPixels / @operationOptions.ratio

          # If the first method exceeds the upper y boundary,
          # calculate width by height * ratio
          if startInPixels.y + heightInPixels > canvasRect.height - 1
            heightInPixels = (1 - @operationOptions.start.y) * canvasRect.height - 1
            widthInPixels  = heightInPixels * @operationOptions.ratio

          # Update the start position
          @operationOptions.end
            .copy(@operationOptions.start)
            .multiplyWithRect(canvasRect)
            .add(new Vector2(widthInPixels, heightInPixels))
            .divideByRect(canvasRect)


        @resizeCanvasControls()

  ###
    Handles the dragging of the upper left knob
  ###
  handleTopLeftKnob: ->
    knob = @knobs.tl
    knob.mousedown (e) =>
      canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())

      initialMousePosition  = new Vector2(e.clientX, e.clientY)
      initialStart          = new Vector2().copy(@operationOptions.start)

      ratio = @operationOptions.ratio

      $(document).mouseup (e) =>
        $(document).off "mouseup"
        $(document).off "mousemove"

      $(document).mousemove (e) =>
        # Mouse position difference to initial position
        diffMousePosition = new Vector2(e.clientX, e.clientY)
          .subtract(initialMousePosition)

        if @operationOptions.ratio is 0
          # Custom cropping, allow free scaling
          @operationOptions.start
            .copy(initialStart)
            .multiplyWithRect(canvasRect)
            .add(diffMousePosition)
            .divideByRect(canvasRect)
        else
          # Turn start and end into pixel values
          endInPixels   = new Vector2().copy(@operationOptions.end).multiplyWithRect(canvasRect)
          startInPixels = new Vector2().copy(initialStart).multiplyWithRect(canvasRect)

          # Increase x by average mouse position and clamp to boundaries
          startInPixels.x += (diffMousePosition.x + diffMousePosition.y) / 2
          startInPixels.clamp(1, endInPixels.x - 50)

          # First method: Calculate height by width / ratio
          widthInPixels  = endInPixels.x - startInPixels.x
          heightInPixels = widthInPixels / @operationOptions.ratio

          # If the first method exceeds the upper y boundary,
          # calculate width by height * ratio
          if endInPixels.y - heightInPixels < 1
            heightInPixels = @operationOptions.end.y * canvasRect.height - 1
            widthInPixels  = heightInPixels * @operationOptions.ratio

          # Update the start position
          @operationOptions.start
            .copy(@operationOptions.end)
            .multiplyWithRect(canvasRect)
            .subtract(new Vector2(widthInPixels, heightInPixels))
            .divideByRect(canvasRect)

        @resizeCanvasControls()

  ###
    Handles the dragging of the visible, cropped part
  ###
  handleCenterDragging: ->
    @centerDiv.mousedown (e) =>
      canvasRect = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())
      min = new Vector2(1, 1)
      max = new Vector2(
        canvasRect.width  - @centerDiv.width() - 1,
        canvasRect.height - @centerDiv.height() - 1
      )

      initialMousePosition  = new Vector2(e.clientX, e.clientY)
      initialStart          = new Vector2().copy(@operationOptions.start)
      initialEnd            = new Vector2().copy(@operationOptions.end)

      centerRect = new Rect(0, 0, @centerDiv.width(), @centerDiv.height())

      $(document).mouseup (e) =>
        $(document).off "mouseup"
        $(document).off "mousemove"

      $(document).mousemove (e) =>
        currentMousePosition = new Vector2(e.clientX, e.clientY)

        # Normalized mouse position
        diffMousePosition = new Vector2()
          .copy(currentMousePosition)
          .subtract(initialMousePosition)

        # Calculate new start vector
        @operationOptions.start
          .copy(initialStart)
          .multiplyWithRect(canvasRect)
          .add(diffMousePosition)
          .clamp(min, max)
          .divideByRect(canvasRect)

        # Calculate the end position relatively
        # to the start position
        @operationOptions.end
          .copy(@operationOptions.start)
          .multiplyWithRect(canvasRect)
          .addRect(centerRect)
          .divideByRect(canvasRect)

        @resizeCanvasControls()

  updateOperationOptions: ->
    canvasWidth = @canvasControlsContainer.width()
    canvasHeight = @canvasControlsContainer.height()
    @operation.setStart @operationOptions.start.x / canvasWidth, @operationOptions.start.y / canvasHeight
    @operation.setEnd   @operationOptions.end.x   / canvasWidth, @operationOptions.end.y   / canvasHeight

  resizeCanvasControls: ->
    canvasRect  = new Rect(0, 0, @canvasControlsContainer.width(), @canvasControlsContainer.height())
    scaledStart = new Vector2()
      .copy(@operationOptions.start)
      .multiplyWithRect(canvasRect)
    scaledEnd   = new Vector2()
      .copy(@operationOptions.end)
      .multiplyWithRect(canvasRect)

    ###
      Set fragment widths
    ###
    leftWidth = scaledStart.x
    for el in ["tl", "lc", "bl"]
      $el = @spotlightDivs[el]
      $el.css
        width: leftWidth
        left: 0

      if @knobs[el]?
        @knobs[el].css
          left: leftWidth

    centerWidth = scaledEnd.x - scaledStart.x
    for el in ["tc", "bc"]
      $el = @spotlightDivs[el]
      $el.css
        width: centerWidth
        left: leftWidth

    rightWidth = canvasRect.width - centerWidth - leftWidth
    for el in ["tr", "rc", "br"]
      $el = @spotlightDivs[el]
      $el.css
        width: rightWidth
        left: leftWidth + centerWidth

      if @knobs[el]?
        @knobs[el].css
          left: leftWidth + centerWidth

    ###
      Set fragment heights
    ###
    topHeight = scaledStart.y
    for el in ["tl", "tc", "tr"]
      $el = @spotlightDivs[el]
      $el.css
        height: topHeight
        top: 0

      if @knobs[el]?
        @knobs[el].css
          top: topHeight

    centerHeight = scaledEnd.y - scaledStart.y
    for el in ["lc", "rc"]
      $el = @spotlightDivs[el]
      $el.css
        height: centerHeight
        top: topHeight

    bottomHeight = canvasRect.height - topHeight - centerHeight
    for el in ["bl", "bc", "br"]
      $el = @spotlightDivs[el]
      $el.css
        height: bottomHeight
        top: topHeight + centerHeight

      if @knobs[el]?
        @knobs[el].css
          top: topHeight + centerHeight

    ###
      Set center fragment dimensions and position
    ###
    @centerDiv.css
      height: centerHeight
      width: centerWidth
      left: leftWidth
      top: topHeight

module.exports = UIControlsCrop
