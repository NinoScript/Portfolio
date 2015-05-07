var scene = d3.select("#scene");

var lastMouse = 0
var rot = 0.0
x3d = document.getElementById('X3Dcanvas')
x3d.addEventListener("drag", function(event) {
	delta = event.clientX - lastMouse
	lastMouse = event.clientX
	rot += delta/100
	scene.attr('rotation', '0 0 1 ' + rot)
	console.log(event)
	event.stopPropagation()
}, true);
x3d.addEventListener("mousedown", function(event) {
	lastMouse = event.clientX
	event.stopPropagation()
}, true);

function randomData() {
	n = 6
	return d3.range(n * n).map(function(i) {
		return {
			x: i / n - n / 2,
			y: i % n - n / 2,
			z: Math.random() * 10,
		};
	})
};

function drawBox(shape) {
	shape
		.append("appearance")
		.append("material")
		.attr("diffuseColor", "steelblue");

	shape
		.append("box")
		.attr("size", "1 1 1")
}

function refresh(data) {
	shapes = scene.selectAll(".barra").data(data);
	shapesEnter = shapes.enter()
		.append("transform").classed("barra", 1)
		.attr("translation", function(d, i) {
			return d.x * 1.5 + " " + d.y * 1.5 + " 0.0";
		})
		.append("transform")
		.attr("translation", "0.0 0.0 0.5")
		.append("shape")
	shapes
		.transition()
		.duration(function(d, i) {
			return 1500 + 200 * d.x + 50 * d.y
		})
		.attr("scale", function(d) {
			return "1.0 1.0 " + d.z;
		});
	drawBox(shapesEnter);
}

refresh(randomData())
setInterval(
	function() {
		refresh(randomData());
	},
	3000
);
