/**
 * ImglyKit
 * integration example using XHR image loading
 *
 * Copyright (c) 2013-2014 img.ly
 */
/*
var startX = 0;
var endX = 0; 
var startY = 0;
var endY = 0;
var touchDX = 0;
var touchDY = 0;

function onTouchStart(event) {
	var touchObj = event.changedTouches[0];
	startX = parseInt(touchObj.clientX);
	startY = parseInt(touchObj.clientY);
	console.log(touchObj.target.id + ' touch started');
	
}

function onTouchMove(event) {
	event.preventDefault();
	var touchObj = event.changedTouches[0];
	touchDX = parseInt(touchObj.clientX) - startX;
	touchDY = parseInt(touchObj.clientY) - startY;
	console.log(touchObj.target.id + ' DX: ' + touchDX + ", DY: " + touchDY);
	
}

function onTouchEnd(event) {
	var touchObj = event.changedTouches[0];
	endX = parseInt(touchObj.clientX);
	endY = parseInt(touchObj.clientY);
	console.log(touchObj.target.id + ' touch ended');
	
}
*/

window.onload = function () {
  var imgly
    , image = new Image()
    , renderButton = document.getElementById("renderButton");
  
  /*
  var touchable = 'createTouch' in document
  if(touchable){
  	console.log("Touch events enabled!");
  	
  	var canvas = document.getElementById('container');
  	canvas.addEventListener('touchstart', onTouchStart, false );
  	canvas.addEventListener('touchmove', onTouchMove, false );
  	canvas.addEventListener('touchend', onTouchEnd, false );
  	
  }else{
    console.log("Touch events not available!");
  }
  */
  
  // Load image
  image.src = "img-1.jpg";
  image.onload = function () {

    // Initialize ImglyKit and run it
    // with the image
    imgly = new ImglyKit({
      container: "#container",
      ratio: 1
    });

    try {
      imgly.run(image);
    } catch (e) {
      if(e.name == "InvalidError") {
        alert("The given file is not an image");
      } else {
        throw e;
      }
    }

  };

  // Listen for "Render final image" click
  renderButton.addEventListener("click", function (event) {
    var dataUrl;

    // dataUrl = imgly.renderToDataURL("png", function (err, dataUrl) {});
    // `dataUrl` now contains the full-sized rendered image
    // Caution: This string will probably exceed the maximum
    // dataURL size of 2M. You will not be able to set location.href
    // or an <img> tag's `src` attribute to this dataUrl.

    // dataUrl = imgly.renderToDataURL("png", { size: "100x100" }, function (err, dataUrl) {});
    // `dataUrl` now contains a resized rendered image that
    // does not exceed 100x100 while keeping the ratio

    // dataUrl = imgly.renderToDataURL("png", { size: "100x100!" }, function (err, dataUrl) {});
    // `dataUrl` now contains a resized rendered image with
    // a size of 100x100 pixels while _not_ keeping the ratio

    imgly.renderToDataURL("png", { size: "512x512" }, function (err, dataUrl) {
      // `dataUrl` now contains a resized rendered image with
      // a width of 300 pixels while keeping the ratio

      var image = document.createElement("img");
      image.setAttribute("src", dataUrl);
      document.getElementsByTagName("body")[0].appendChild(image);
    });

  });
  
  
};
