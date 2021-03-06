###
  ImglyKit
  Copyright (c) 2013-2014 img.ly
###
List = require "./base/list.coffee"
class UIControlsOverview extends List
  ###
    @param {ImglyKit} app
    @param {ImglyKit.UI} ui
    @param {ImglyKit.UI.Controls} controls
  ###
  allowMultipleClick: false
  constructor: (@app, @ui, @controls) ->
    super
    @listItems = [
      {
        name: "Filters"
        cssClass: "filters"
        controls: require "./filters.coffee"
        tooltip: "Filters"
      }, {
        name: "Orientation"
        cssClass: "orientation"
        controls: require "./orientation.coffee"
        tooltip: "Orientation"
      }, {
        name: "Crop"
        cssClass: "crop"
        controls: require "./crop.coffee"
        operation: require "../../operations/crop.coffee"
        tooltip: "Crop"
      }, {
        name: "Brightness"
        cssClass: "brightness"
        controls: require "./brightness.coffee"
        operation: require "../../operations/brightness.coffee"
        tooltip: "Brightness"
      }, {
        name: "Contrast"
        cssClass: "contrast"
        controls: require "./contrast.coffee"
        operation: require "../../operations/contrast.coffee"
        tooltip: "Contrast"
      }, {
        name: "Saturation"
        cssClass: "saturation"
        controls: require "./saturation.coffee"
        operation: require "../../operations/saturation.coffee"
        tooltip: "Saturation"
      }, {
        name: "Frames"
        cssClass: "frames"
        controls: require "./frames.coffee"
        operation: require "../../operations/frames.coffee"
        tooltip: "Frames"
      }
    ]
    
module.exports = UIControlsOverview