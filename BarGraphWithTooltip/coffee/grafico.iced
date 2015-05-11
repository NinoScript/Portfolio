{}class ColorGenerator
	constructor: (h=0.0, s=100.0, l=50.0)->
		@h = h # Hue        (0-1)
		@s = s # Saturation ( % )
		@l = l # Lightness  ( % )
		@g = 0.618033988749895 # 1/phi (golden ratio conjugate)
	nextColor: -> @h = (@h+@g)%1 # http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
	cssColorString: -> "hsl(#{@h*360}, #{@s}%, #{@l}%)"
	getColor: ->
		lastColorString = do @cssColorString
		do @nextColor
		lastColorString
	uniqueColorForIndex: (i) ->
		@array = [] if not @array?
		@array[i] ?= do @getColor
	uniqueColorForKey: (key) ->
		@object = {} if not @object?
		@object[key] ?= do @getColor

# Defines basic d3 behaviour to use in .call()
class BaseD3Chart
	enter:  (selection) =>
		self = @
		selection.each (d, i) ->
			self._enter(d3.select(this), d, i)
	update: (selection) =>
		self = @
		selection.each (d, i) -> self._update(d3.select(this), d, i)
	end:    (selection) =>
		self = @
		selection.each (d, i) -> self._end(d3.select(this), d, i)
	
	_setup:  (elem, d, i) ->
		throw "Not Implemented"
	_update: (elem, d, i) ->
		throw "Not Implemented"
	_end:    (elem, d, i) ->
		throw "Not Implemented"

# Adds axis independence
class RotatableChart extends BaseD3Chart
	constructor: ->
		super
		@sentido "horizontal"
		@size    100

	ejes =
		horizontal: ["left", "right"]
		vertical:   ["top", "bottom"]

	sentido: (value) ->
		if not arguments.length
			return @_sentido
		@_sentido = value
		@_pos1 = ejes[@_sentido][0]
		@_pos2 = ejes[@_sentido][1]
		@

	size: (value) ->
		if not arguments.length
			return @_size
		@_size = value
		domain = [100, 0];
		range  = [0, @_size];
		@_scale_pos1 = d3.scale.linear().domain(domain).range(range)
		@_scale_pos2 = d3.scale.linear().domain(domain).range(range.reverse())
		@

# Makes it easier to have many subgraphics (charts)
class CompoundRotatableChart extends RotatableChart
	sentido: (value) ->
		super value
		for key of @childs
			@childs[key].sentido value
		@
		
	size: (value) ->
		super value
		for key of @childs
			@childs[key].size value
		@

# Something that's just a 1D point (easily extendable to 2D though)
class Mark extends RotatableChart
	_enter: (self, d, i) ->
		# self.append('div').classed('text-container', true)
		# 	.append('p').classed('value', true)
		# 	.text(d)
		self.classed('mark', true)
			.style(@_pos1, @_scale_pos1(0)+'px')
	_update: (self, d, i) ->
		# self.select('.value')
		# 	.text(d)
		self
			.transition().duration(1000)
			.style(@_pos1, @_scale_pos1(d)+'px')

# Something that's just a 1D line (idem)
class Bar extends RotatableChart
	min: (d) -> @_scale_pos1.invert Math.min(@_scale_pos1(d[0]), @_scale_pos1(d[1]))
	max: (d) -> @_scale_pos1.invert Math.max(@_scale_pos1(d[0]), @_scale_pos1(d[1]))
	
	_enter: (self, d, i) ->
		# self.append('p').classed('min', true).classed('value', true)
		# self.append('p').classed('max', true).classed('value', true)
		self.classed('bar', true)
			.style(@_pos1, @_scale_pos1(0)+'px')
			.style(@_pos2, @_scale_pos2(0)+'px')
	_update: (self, d, i) ->
		min = @min d
		max = @max d
		# self.select('.min')
		# 	.text(Math.round min)
		# self.select('.max')
		# 	.text(Math.round max)
		self.transition().duration(1000)
			.style(@_pos1, @_scale_pos1(min)+'px')
			.style(@_pos2, @_scale_pos2(max)+'px')

# Compound Mark with Bar
class MarkedBar extends CompoundRotatableChart
	constructor: ->
		super
		@childs =
			mark: new Mark()
			bar:  new Bar()
		@sentido "horizontal"
		@size 100

	_enter: (self, d, i) ->
		self.append('div')
			.datum(d.middle)
			.call(@childs.mark.enter)
		self.append('div')
			.datum([d.val1, d.val2])
			.call(@childs.bar.enter)

	_update: (self, d, i) ->
		self.select('.mark')
			.datum(d.middle)
			.call(@childs.mark.update)
		self.select('.bar')
			.datum([d.val1, d.val2])
			.call(@childs.bar.update)

D3to$ = (element) -> $(element[0][0])
$toD3 = (element) -> d3.select(element[0])

añosMostrados = {}
colorGen = new ColorGenerator 0.2, 70, 60
class Barra extends CompoundRotatableChart
	constructor: ->
		super
		@childs =
			tope: new Mark()
		@sentido "vertical"
		@size 300

	_enter: (self, d, i) ->
		self.classed('barra', true)
		# c = Math.round(d.seriesIndex * 200 / 2)
		delta = x: -1, y: 5
		barra = self.append('div')
			.datum(d.data)
			.call(@childs.tope.enter)
			.style('background-color', colorGen.uniqueColorForIndex d.seriesIndex)
			# .on('mouseover', ->
			# 	mouse = d3.mouse(this)
			# 	x = mouse[0] + delta.x
			# 	y = mouse[1] + delta.y
			# 	self.select('.value')
			# 		.style('left', "#{x}px")
			# 		.style('top' , "#{y}px")
			# 		.transition().duration(300).delay(300)
			# 		.style('opacity', '1'))
			# .on('mousemove', ->
			# 	mouse = d3.mouse(this)
			# 	x = mouse[0] + delta.x
			# 	y = mouse[1] + delta.y
			# 	self.select('.value')
			# 		.style('left', "#{x}px")
			# 		.style('top' , "#{y}px"))
			# .on('mouseout', ->
			# 	self.select('.value')
			# 		.transition().duration(300)
			# 		.style('opacity', '0'))
		if añosMostrados[d.yearIndex] == undefined and d.data != 0
			console.log(añosMostrados)
			añosMostrados[d.yearIndex] = self
			self.append('div')
				.classed('tick', true)
				.html("<p>#{d.year}</p>")
		# non free tooltip bulshit
			# barra.attr('title', '123')
			# D3to$(barra).tooltip({title:123})
		# tooltipster:
			# barra.attr 'title', """
			# 	<p>#{d.seriesName}</p>
			# 	<p>#{d.data}% success rate</p>
			# """
			# D3to$(barra).tooltipster speed:500
		D3to$(barra).opentip """<p><strong>#{d.seriesName.split(" Expedition")[0]}, #{d.year}</strong></p>
				<p>#{d.data}% success rate</p>
			""",
			tipJoint: 'bottom'
			style: 'dark'
			delay: 0
			hideDelay: 0.3
			# showEffect: ''
			# hideEffect: ''
			# showEffectDuration: 0.3
			# hideEffectDuration: 0.2
			showEffectDuration: 0
			hideEffectDuration: 0
			group: 'bender'
	_update: (self, d, i) ->
		@childs.tope._update(self.select('.mark'), d.data, i)
			.duration(1000)
			.delay(i*30 + d.seriesIndex*300)

$ ->
	global_container = d3.select(".grafico")
	
	barra = new Barra()
	
	
	await d3.json '../json/datos.mini.json', defer(e, json)
	flat_data = do ->
		result = []
		(result.push
			data:d
			seriesName:ds.seriesName
			seriesIndex:di
			year:json.categories[yi]
			yearIndex:yi
		) for d, yi in ds.data for ds, di in json.dataset

		result
			.sort (a, b) ->
				v = (d) -> d.yearIndex*100+d.seriesIndex
				d3.ascending v(a), v(b)
			.filter (d) -> d.data!=0
	w = 800/flat_data.length
	p = Math.round(100/flat_data.length)
	cuadrados = global_container.selectAll('.barra')
		.data(flat_data)
		.enter().append('div')
		.call(barra.enter)
		.call(barra.update)
		.style('width', "#{w}px")
		.style('left', (d, i) -> "#{i*(w+p)}px")
