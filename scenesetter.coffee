app = undefined

promptCB = (text, def, callback) ->
	result = prompt text, def
	if result != null
		callback result

drag = (e, callback) ->
	lx = e.pageX
	ly = e.pageY
	window.onmousemove = (e) =>
		callback e.pageX - lx, e.pageY - ly, false
		lx = e.pageX
		ly = e.pageY
		window.onmouseup = (e) =>
			callback e.pageX - lx, e.pageY - ly, true
			window.onmousemove = undefined
			window.onmouseup   = undefined
			return false
		return false
	return false

evalCode = (canvas, ctx, code) ->
	w = canvas.width
	h = canvas.height
	eval CoffeeScript.compile(code)


class Application

	constructor: ->
		@canvas = new Canvas(718, 256)
		@layerman = new LayerManager(@canvas)
		@palette = new Palette(@canvas)

	trace: ->
		console.log arguments...


class Component

	listen: (name, fn) ->
		fnname = 'on' + name
		if fnname of @
			old = @[fnname]
			@[fnname] = ->
				old.apply @, arguments
				fn.apply @, arguments
		else
			@[fnname] = fn

	fire: (name, args...) ->
		fnname = 'on' + name
		if fnname of @
			@[fnname] args...
	
	proxy: (name) ->
		return =>
			@[name] arguments...


class Bar extends Component

	addButton: (className) ->
		button = $ '<span class="button button-' + className + '">' + className + '</span>'
		@buttons.append button
		return button



class Dialog extends Component

	constructor: (title) ->
		@element = $ '<div class="dialog"><div class="dialog-title"><span class="dialog-title-text"></span></div><div class="dialog-contents"></div></div>'
		@bar = @element.find '.dialog-title'
		@title = @bar.find '.dialog-title-text'
		@x = 0
		@y = 0
		@bar.mousedown (e) =>
			drag e, (dx, dy, done) =>
				@x += dx
				@y += dy
				@fire 'move'
		@close = @bar.find '.dialog-close'
		@contents = @element.find '.dialog-contents'
		@element.appendTo document.body
		@setTitle title
		@fire 'move'
	
	destroy: -> @fire 'destroy'
	
	onmove: ->
		@element.css
			left: @x + 'px'
			top: @y + 'px'
	
	ondestroy: ->
		@element.remove()

	setTitle: (title) ->
		@title.text title




class LayerRepresentative extends Bar

	constructor: (layer) ->
		@layer = layer
		@element = $ '<div class="layer"><span class="buttons"></span><span class="layer-name"></span></div>'
		@name = @element.find('.layer-name')
		@buttons = @element.find('.buttons')
		@layer.fire 'decorate', @
		@updateName()
		@layer.listen 'rename', => @updateName()
		@layer.listen 'delete', => @element.remove()

	updateName: ->
		@name.text '' + @layer


class LayerManager extends Component
	
	constructor: (canvas) ->
		@canvas = canvas
		@container = $ '<div class="layers"></div>'
		@container.appendTo document.body
		@canvas.listen 'layeradd',     => @update()
		@canvas.listen 'layermove',    => @update()
		@canvas.listen 'layerdelete',  => @update()
		@reps = {}
		@update()
	
	update: ->
		index = 0
		for layer in @canvas.layers
			if not (layer.id of @reps)
				@reps[layer.id] = new LayerRepresentative layer
				@container.prepend @reps[layer.id].element
			@reps[layer.id].element.css 'top', ((@canvas.layers.length - index - 1) * 34 + 3) + 'px'
			index++
		@container.css 'height', (index * 34 + 3) + 'px'


class Canvas extends Component

	constructor: (width, height) ->
		@canvas = document.createElement 'canvas'
		@ctx = @canvas.getContext '2d'
		@canvas.width = width
		@canvas.height = height
		@layers = []
		document.body.appendChild @canvas

	addLayer: (layer) ->
		@layers.push layer
		@fire 'layeradd'
		@fire 'update'
		layer.canvas = @
		layer.index = @layers.length - 1
		layer.listen 'update', => @fire 'update'

	onupdate: ->
		@ctx.clearRect 0, 0, @canvas.width, @canvas.height
		for layer in @layers
			@ctx.save()
			layer.render @
			@ctx.restore()
	
	swapLayer: (a, b) ->
		if 0 <= a < @layers.length
			if 0 <= b < @layers.length
				[@layers[a], @layers[b]] = [@layers[b], @layers[a]]
				@layers[a].index = a
				@layers[b].index = b
				@fire 'update'
				@fire 'layermove'

	deleteLayer: (index) ->
		@layers[index].destroy()
		@layers[index..index] = []
		index = 0
		for layer in @layers
			layer.index = index
			index++
		@fire 'update'
		@fire 'layerdelete'


class Layer extends Component

	nextid = 0

	generateID = ->
		return '' + (++nextid)

	constructor: ->
		@id = generateID()
		@index = NaN
		@canvas = undefined
		@init arguments...
		app.canvas.addLayer @

	init: ->

	destroy: ->
		@fire 'destroy'

	ondecorate: (rep) ->
		rep.addButton('del').click  => @canvas.deleteLayer @index; @fire 'delete'
		rep.addButton('up').click   => @swapWith @index + 1
		rep.addButton('down').click => @swapWith @index - 1
	
	swapWith: (index) ->
		@canvas.swapLayer @index, index

class Property extends Component

	constructor: (layer) ->
		@layer = layer
		@layer.listen 'decorate', (rep) => @fire 'decorate', rep

class PositionProperty extends Property

	constructor: (layer, x, y) ->
		super(layer)
		@x = x
		@y = y

	ondecorate: (rep) ->
		rep.addButton('move').mousedown (e) =>
			drag e, (dx, dy, done) =>
				@x += dx
				@y += dy
				@layer.fire 'update'

class StringProperty extends Property

	constructor: (layer, name, prompt, value) ->
		super(layer)
		@name = name
		@prompt = prompt
		@value = value

	ondecorate: (rep) ->
		rep.addButton(@name).click =>
			promptCB @prompt, @value, (value) =>
				@setValue value
				@fire 'setvalue'
	
	setValue: (value) ->
		@value = value
	
	onsetvalue: ->
		@layer.fire 'update'
		@layer.fire 'rename'



class TextDialog extends Dialog

	constructor: (title, value) ->
		super(title)
		@textarea = $ '<textarea class="textdialog-ta"></textarea>'
		@textarea.appendTo @element
		@textarea.val value
		@textarea.change =>
			@fire 'value'
	
	value: ->
		return @textarea.val()


class TextProperty extends Property

	constructor: (layer, name, value) ->
		super(layer)
		@name = name
		@value = new TextDialog(name, value)
		@value.listen 'value',  => @fire 'setvalue'
		layer.listen 'destroy', => @value.destroy()
	
	onsetvalue: ->
		@layer.fire 'update'
		@layer.fire 'rename'


class ImageLayer extends Layer

	init: (image, name) ->
		super()
		@position = new PositionProperty(@, 0, 0)
		@image = image
		@name = name
		@image.onload = =>
			@fire 'update'

	render: (canvas) ->
		canvas.ctx.drawImage @image, @position.x, @position.y

	toString: -> 'image ' + @name

	ondecorate: (rep) ->
		super(rep)
		rep.addButton('x-center').click =>
			@position.x = Math.round((app.canvas.canvas.width - @image.width) / 2)
			@fire 'update'


class BackgroundLayer extends Layer

	init: (color) ->
		@color = new StringProperty(@, 'color', 'Background Color', color)
		super()

	render: (canvas) ->
		canvas.ctx.fillStyle = @color.value
		canvas.ctx.fillRect 0, 0, canvas.canvas.width, canvas.canvas.height

	toString: -> 'background ' + @color.value



class ShadowLayer extends Layer

	init: (color) ->
		@color = new StringProperty(@, 'color', 'Shadow Color', color)
		super()

	toString: -> 'shadow ' + @color.value

	render: (canvas) ->
		ctx = canvas.ctx
		w = canvas.canvas.width
		h = canvas.canvas.height
		ctx.fillStyle = @color.value
		ctx.shadowColor = @color.value
		ctx.shadowOffsetX = 0
		ctx.shadowOffsetY = 2
		ctx.shadowBlur = 20
		ctx.beginPath()
		ctx.moveTo -1 * w, -1 * h
		ctx.lineTo  2 * w, -1 * h
		ctx.lineTo  2 * w,  2 * h
		ctx.lineTo -1 * w,  2 * h
		ctx.lineTo -1 * w, -1 * h
		@drawInnerFrame(canvas, ctx, w, h)
		ctx.closePath()
		ctx.fill()
	
	drawInnerFrame: (canvas, ctx, w, h) ->
		ctx.moveTo 0, 0
		ctx.lineTo 0, h
		ctx.lineTo w, h
		ctx.lineTo w, 0
		ctx.lineTo 0, 0


class RoundedFrameLayer extends ShadowLayer

	init: (color) ->
		@color = new StringProperty(@, 'shadow', 'Shadow Color', color)
		@frame = new StringProperty(@, 'frame', 'Frame Color', '#353433')

	drawInnerFrame: (canvas, ctx, w, h) ->
		ctx.fillStyle = @frame.value
		radii = 10
		PI = Math.PI
		ctx.moveTo 0,         radii
		ctx.arc    radii,     h - radii, radii, PI * 6 / 2, PI * 5 / 2, true
		ctx.arc    w - radii, h - radii, radii, PI * 5 / 2, PI * 4 / 2, true
		ctx.arc    w - radii, radii,     radii, PI * 4 / 2, PI * 3 / 2, true
		ctx.arc    radii,     radii,     radii, PI * 3 / 2, PI * 2 / 2, true


class CoffeeScriptLayer extends Layer

	init: (code) ->
		@code = new TextProperty(@, 'code', code)
		super()

	toString: -> 'coffeescript'

	render: (canvas) ->
		evalCode(canvas.canvas, canvas.ctx, @code.value.value())


class Palette extends Bar

	constructor: (canvas) ->
		@canvas = canvas
		@element = $ '<div class="toolbar"><span class="buttons"></span></div>'
		@element.appendTo document.body
		@buttons = @element.find('.buttons')
		@init()
	
	init: ->
		@addButton('width').click  => promptCB 'Width',  @canvas.canvas.width, (width)  =>
			@canvas.canvas.width = width
			@canvas.fire 'update'
		@addButton('height').click => promptCB 'Height', @canvas.canvas.height, (height) =>
			@canvas.canvas.height = height
			@canvas.fire 'update'
		@addButton('new-background').click => new BackgroundLayer '#151413'
		@addButton('new-shadow').click => new ShadowLayer '#090807'
		@addButton('new-script').click => new CoffeeScriptLayer ''
		@dropHold()
	
	dropHold: ->
		ondragenter = (e) =>
			e.stopPropagation()
			e.preventDefault()
		ondragleave = (e) =>
		ondragover = (e) =>
			e.stopPropagation()
			e.preventDefault()
			if e.dataTransfer
				e.dataTransfer.effectAllowed = 'copy'
				e.dataTransfer.dropEffect = 'copy'
		ondrop = (e) =>
			e.stopPropagation()
			e.preventDefault()
			dt = e.dataTransfer
			files = dt.files
			for file in files
				image = new Image()
				image.src = file.getAsDataURL()
				new ImageLayer image, file.name
		drop = document.body
		drop.addEventListener 'dragenter', ondragenter, false
		drop.addEventListener 'dragleave', ondragleave, false
		drop.addEventListener 'dragover', ondragover, false
		drop.addEventListener 'drop', ondrop, false



$ ->
	app = new Application()
	new BackgroundLayer '#252423'
	new RoundedFrameLayer 'rgba(9, 8, 7, 0.6)'
