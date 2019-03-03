function getPar(parname) {
	var pars = window.location.search.slice(1).split('&');
	for (var i = 0; i < pars.length; i++) {
		var par = pars[i].split('=');
		if (par[0] === parname) { return par[1]; }
	}
};
function convert() {
  var obj = this.querySelector('object');
  var svg = new XMLSerializer().serializeToString(
    obj.contentDocument.querySelector('svg'));
  var img = document.createElement('img');
  img.src = 'data:image/svg+xml;base64,' + btoa(svg);
  var link = this.querySelector('a');
  img.onload = function () {
    var cvs = document.createElement('canvas');
    var wd = getPar('width');
    if (!wd) { wd = '2000'; }
    cvs.width = wd;
    cvs.height = wd*img.height/img.width;
    cvs.getContext('2d').drawImage(img, 0, 0);
    link.href = cvs.toDataURL();
    link.onclick = function(e) {e.stopPropagation();};
    link.click();
    delete img;
    delete cvs;
    link.href = '#';
  }
}
function colorize() {
  var svg = this.contentDocument.querySelector('svg');
  var xmlns = "http://www.w3.org/2000/svg";
  var st = document.createElementNS(xmlns, 'style');
  st.textContent = '';

  var bgcol = getPar('bgcol').replace('0x', '#');
  var fillcol = getPar('fillcol').replace('0x', '#');
  if (bgcol) {
    st.textContent += '* { background-color: ' + bgcol + ' !important; }';
  }
  if (fillcol) {
    st.textContent += '* { fill: ' + fillcol + ' !important; draw: ' + fillcol + ' !important }';
  }
  svg.appendChild(st);
}
