###
  ImglyKit
  Copyright (c) 2013-2014 img.ly
###
Resize = require "./vendor/resize"

Utils = {}
Utils.sharedCanvas  = document.createElement "canvas"
Utils.sharedContext = Utils.sharedCanvas.getContext "2d"

###
  @param options Options
  @param options.image Dimensions (width, height) of the image
  @param options.container Dimensions (width, height) of the container
  @returns {Object} An object containing the final canvas dimensions (width, height)
###
Utils.calculateCanvasSize = (options) ->
  # Calculate scale
  scale = Math.min options.container.width / options.image.width, options.container.height / options.image.height

  result =
    width: options.image.width * scale
    height: options.image.height * scale

  return result

###
  Creates a number as a fingerprint for an array of numbers.

  Based on http://stackoverflow.com/questions/7616461/generate-a-hash-from-string-in-javascript-jquery.

  @param {Array} data
  @returns {Number}
###
Utils.fingerprint = (data) ->
  hash = 0
  return hash unless data.length

  for point in data
    hash = ((hash << 5) - hash) + point
    hash |= 0 # Convert to 32bit integer

  hash

###
  @param {Image} image
  @returns {ImageData}
###
Utils.getImageDataForImage = (image) ->
  # Create a canvas to draw to
  canvas = document.createElement "canvas"

  # Resize canvas to fit the image size
  canvas.width  = image.width
  canvas.height = image.height

  # Draw the image on the canvas
  context = canvas.getContext("2d")
  context.drawImage image, 0, 0

  # Get the image data
  context.getImageData 0, 0, image.width, image.height

###
  @param {Image} image
  @param {CanvasRenderingContext2d} context
###
Utils.resizeImageSmooth = (image, context) ->
  sourceImageData = Utils.getImageDataForImage image
  destImageData   = context.getImageData 0, 0, context.canvas.width, context.canvas.height

  sourcePixels = sourceImageData.data
  destPixels   = destImageData.data

  destWidth = context.canvas.width
  destHeight = context.canvas.height

  resized = new Resize image.width, image.height, destWidth, destHeight, true, true, false
  resizedBuffer = resized.resize sourcePixels
  resizedBufferLength = resizedBuffer.length

  for i in [0...resizedBufferLength]
    destPixels[i] = resizedBuffer[i] & 0xFF

  context.putImageData destImageData, 0, 0

###
  @param {Image} image
  @returns {ImageData}
###
Utils.getResizedImageDataForImage = (image, dimensions, options={}) ->
  options.smooth ?= false

  # Create a canvas that fits the dimensions
  canvas = document.createElement "canvas"

  # Set canvas dimensions
  canvas.width  = dimensions.width
  canvas.height = dimensions.height

  # Draw the resized image on the canvas
  context = canvas.getContext("2d")
  unless options.smooth
    context.drawImage(
      image,
      0, 0,
      image.width, image.height,
      0, 0,
      canvas.width, canvas.height
    )
  else
    Utils.resizeImageSmooth image, context

  # Get the image data
  context.getImageData 0, 0, canvas.width, canvas.height

###
  @param {ImageData} imageData
  @param {Object} dimensions
  @returns {ImageData}
###
Utils.resizeImageData = (imageData, options={}) ->
  unless options.size?
    throw new Error("No size given.")

  options.smooth ?= false

  # Create a canvas that fits the dimensions
  sourceCanvas = document.createElement "canvas"
  sourceCanvas.width = imageData.width
  sourceCanvas.height = imageData.height

  sourceContext = sourceCanvas.getContext "2d"
  sourceContext.putImageData imageData, 0, 0

  dimensions = Utils.calculateDimensionsFromSize imageData, options.size

  # Create the destination canvas
  destinationCanvas = document.createElement "canvas"
  destinationCanvas.width = dimensions.width
  destinationCanvas.height = dimensions.height

  destinationContext = destinationCanvas.getContext "2d"

  unless options.smooth
    destinationContext.drawImage(
      sourceCanvas,
      0, 0,
      sourceCanvas.width, sourceCanvas.height,
      0, 0,
      destinationCanvas.width, destinationCanvas.height
    )
  else
    Utils.resizeImageSmooth sourceCanvas, destinationContext

  # Get the image data
  destinationContext.getImageData 0, 0, destinationCanvas.width, destinationCanvas.height

###
  @param {Object} size
  @returns {Object}
###
Utils.calculateDimensionsFromSize = (sourceSize, size) ->
  match = size.match /^([0-9]+)?x([0-9]+)?([\!])?$/i
  unless match
    throw new Error("Invalid size option: #{size}")

  [m, x, y, modifier] = match

  # Validations
  if modifier is "!" and not (x? && y?)
    throw new Error("Both `x` and `y` have to be set when using the fixed (!) modifier.")
  unless x? or y?
    throw new Error("Neither `x` nor `y` are given.")

  if modifier is "!"
    return width: x, height: y
  else
    containerSize =
      width: sourceSize.width
      height: sourceSize.height

    if x? and y?
      return Utils.calculateCanvasSize
        container:
          width: x
          height: y
        image: sourceSize
    else if x?
      # Fixed x, y by ratio
      width = x

      ratio = sourceSize.height / sourceSize.width
      height = width * ratio
    else if y?
      # Fixed y, x by ratio
      height = y

      ratio = sourceSize.width / sourceSize.height
      width = height * ratio

    return { width, height }

###
  @param {ImageData} imageData
  @returns {ImageData}
###
Utils.cloneImageData = (imageData) ->
  newImageData = @sharedContext.createImageData imageData.width, imageData.height

  # Set the data
  for i in [0...imageData.data.length]
    newImageData.data[i] = imageData.data[i]

  return newImageData

###
  @param {Object} dimensions
  @param {Integer} dimensions.width
  @param {Integer} dimensions.height
  @returns {HTMLCanvasElement}
###
Utils.newCanvasWithDimensions = (dimensions) ->
  # Create canvas
  canvas = document.createElement "canvas"

  # Resize canvas
  canvas.width  = dimensions.width
  canvas.height = dimensions.height

  return canvas

###
  @param {imageData} imageData
  @returns {HTMLCanvasElement}
###
Utils.newCanvasFromImageData = (imageData) ->
  # Create canvas
  canvas = document.createElement "canvas"

  # Resize canvas to fit the image data dimensions
  canvas.width  = imageData.width
  canvas.height = imageData.height

  # Put the image data to the canvas
  context = canvas.getContext("2d")
  context.putImageData imageData, 0, 0

  return canvas

###
  @param {String} str Input String
  @returns {String} Output Stirng
###
Utils.dasherize = (str) ->
  str.toLowerCase().replace(/[^\w\s-]/g, ' ').replace(/[-_\s]+/g, '-')

###
  @param {Integer} number
  @param {Integer} min
  @param {Integer} max
  @returns {Integer}
###
Utils.clamp = (number, min, max) ->
  Math.min(Math.max(number, min), max)

###
  @param {Integer} number
  @param {Integer} min
  @param {Integer} max
  @returns {Integer}
###
Utils.within = (number, min, max) ->
  return (min < number < max)

###
  @param {Object} x/y coordinates
  @param [Object] minimum and maximum x/y coordinates
  @returns {Boolean}
###
Utils.withinBoundaries = (coords, boundaries) ->
  boundaries ?=
    x:
      min: 0, max: 1
    y:
      min: 0, max: 1

  return !(
    coords.x < boundaries.x.min or
    coords.x > boundaries.x.max or
    coords.y < boundaries.y.min or
    coords.y > boundaries.y.max
  )

###
  @param {String} string
  @returns {String}
###
Utils.truncate = (string, length=10) ->
  if string.length > length
    return string.substr(0, length - 3) + "..."
  else
    return string

module.exports = Utils
