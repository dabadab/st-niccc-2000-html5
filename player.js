var X_SCALE=3;
var Y_SCALE=3;

function sleep(ms) {
	return new Promise(resolve => setTimeout(resolve, ms));
}

function clearScreen() {
	var canvas = document.getElementById('niccc');
	var ctx = canvas.getContext('2d');
	ctx.fillStyle = '#ffffff';
	ctx.clearRect(0, 0, canvas.width, canvas.height);
}

function drawPoly(col, v) {
	var canvas = document.getElementById('niccc');
	var ctx = canvas.getContext('2d');
	ctx.fillStyle = col;
	ctx.beginPath();
	ctx.moveTo(v[0].x * X_SCALE, v[0].y * Y_SCALE);
	for (c = 1; c < v.length; c++) {
		ctx.lineTo(v[c].x * X_SCALE, v[c].y * Y_SCALE);
	}
	ctx.closePath();
	ctx.fill();
}

function renderFrame(frame) {
	if (frame.clr) clearScreen();
	// info = (frame.clr ? '---' : '   ') + (frame.polygons[0].hasOwnProperty("verticesIdx") ? '   ' : 'NON')
	// console.log(info, frame.frameIdx);
	for (p = 0; p < frame.polygons.length; p++) {
		// c = frame.polygons[p].colidx;
		// color='#'+(c*0x100000+c*0x1000+c*0x10).toString(16);
		color = frame.palette[frame.polygons[p].colidx];
		if (frame.polygons[p].hasOwnProperty("verticesIdx")) {
			vertices = frame.polygons[p].verticesIdx.map(v => {
				return frame.vertices[v.idx]
			});
		} else {
			vertices = frame.polygons[p].vertices;
		}
		drawPoly(color, vertices);
	}
}

async function playFrames() {
	FROM=0
	TO=movie.frames.length
	// FROM=171
	// TO=FROM+1
	for ( f=FROM; f<TO; f++) {
		renderFrame(movie.frames[f]);
		await sleep(10);
	}
}

document.addEventListener('DOMContentLoaded', function () {
	var canvas = document.getElementById('niccc');
	canvas.width = 256 * X_SCALE;
	canvas.heigth = 200 * Y_SCALE;
	canvas.style.background = "black";
	playFrames();
});
