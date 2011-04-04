[Scene Setter](http://dtinth.github.com/scenesetter/)
=====================================================

My HTML5 image editor that I use to create images in [my documentation website](http://docs.dt.in.th/) ([example](http://docs.dt.in.th/thaiWitter/Usage/Basics)).


Compatibility
-------------

Use with Firefox 4 only. Untested on other browsers.


Technology
----------

* HTML5 Canvas
* HTML5 File API (drag and drop)
* jQuery
* CoffeeScript


Usage
-----

At the top you will see the result canvas and below it you will see a list of layers. Below that list you will see a lot of buttons.

Let's look at the layers. Each layer has buttons that do things:

* __del__: Delete that layer.
* __up__: Move that layer up.
* __down__: Move that layer down.

And most layers have each own set of additional buttons.

To add an image to the canvas, __drag images from the desktop__ and drop it on the canvas, this creates a new image layer.

Now let's look at the toolbar at the bottom, you will see:

* __width__: Change canvas width.
* __height__: Change canvas height.
* __new-background__: Add a new background layer.
* __new-shadow__: Add an inner shadow to the image.
* __new-frame: Add a rounded frame layer to the image (like shadow layer but with rounded borders).
* __new-script__: Add a custom rendering script. When you click this button a popup dialog will open up to allow you to write __custom CoffeeScript code__
to draw to the canvas.


Variables in Custom Script Layer
--------------------------------

* __w__: Width
* __h__: Height
* __ctx__: Context
* __canvas: Canvas Element


















