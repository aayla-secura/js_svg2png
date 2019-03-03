# In-browser svg to png convertor

Convert svg to png using your browser's JavaScript. Can set the size,
background and fill color using URL parameters.

Requires python3 and `simple.py` from [this other project of
mine](https://github.com/aayla-secura/simple_CORS_https_server), though you can
just use the [static HTML page]() and edit to point to your image.

Works in Chrome, does not work in Firefox at the moment. Not tested in any
other browsers.

Also included are scripts to convert an image (png, jpg) to an ASCII text using
the excellent online convertor at https://www.text-image.com/convert/pic2
(`fetch_outline.sh`) and then replace all non-blank (or non-background)
characters with a hex encoding of a text of your choice (`text_to_outline.pl`).

# Tools

## Raster image to ASCII image: `fetch_outline.sh`

```
THIS PROGRAM USES THE ONLINE CONVERTOR AT https://www.text-image.com/convert/pic2.
ALL CREDIT GOES TO THE CREATOR OF THAT SITE.
Network connection is required.

Note that transparent pixels are treates as black. Ensure your image has
a background color. You can use Imagemagick to add a background:
  convert -flatten -background white input.png output.png


Usage:
  ./fetch_outline.sh [<options>]"

Options:
  -w     Width of the text image (no. of characters per line). Default is 100.
  -i     Input image to convert. Default is input.png.
  -o     Output text file to write result to. Default is
         'out/{input image name}_outline_W{width}_B{browser}_I{0|1}_C{0|1}.{txt|html}'
  -B     Browser type. Only used for HTML conversion. As a rule of thumb 'ie'
         gives a square to tall aspect ratio, firefox gives a more squashed
         text image. Default is 'ie'.
  -a     Produce an ASCII output instead of HTML. Default is HTML.
  -I     Invert input image colors.
  -C     Extra contrast.

HTML output will be monochrome, with white and black characters. You can
specify which characters to remove as background using the -b option to
text_to_outline.pl.

With ASCII output will include spaces instead of white pixels (background) and
0's instead of black characters. You can invert the behaviour with the -I
option.
```

## ASCII image to custom text: `text_to_outline.pl`

Takes the output of `fetch_outline.sh` (either ASCII or HTML), removes
background characters and HTML tags (if input is HTML) and replaces all
foreground characrers with a hex encoding of a custom text, such that `xxd -r
-p outfile.txt` will display your text.

```
Usage:
  ./text_to_outline.pl [<options>]

Options:
  -i     Input text file containing the outline of the image (what you get out
         of fetch_outline.sh). Default is 'out/outline.txt'.
  -o     Basebane (no extension) for the output logo. .txt and .svg files will
         be created. Default is 'out/txt/image'.
  -t     Input text file for the filling content. It will be hex encoded and
         written in place of the non-space characters of the outline file.
         Default is 'content.txt'.
  -b     Background color. Used only if the outline is in HTML format.
         Characters with this (exact) color will be removed. Must match what is
         in the outline file, e.g. white and #ffffff, and #FFFFFF and treated
         differently. Default is 'white'.
  -a     Treat the input as ASCII instead of HTML (you gave the equivalent
         switch to fetch_outlinel.sh). Default is HTML, unless the outline text
         file has .txt extension.
```

## SVG to PNG convertor (what you came here for): `svg_to_png.py`

Just run it and follow the instructions:

```console
$ python3 svg_to_png.py
```

# Try it

Download `https://github.com/aayla-secura/simple_CORS_https_server/blob/master/simple.py` and put it in the current directory.

```console
$ ./fetch_outline.sh -i demo.png -o out/demo.html
$ ./fetch_outline.sh -i demo.png -a -o out/demo.txt
$ ./text_to_outline.pl -i out/demo.txt -t demo.txt -o out/txtimage_txt
$ ./text_to_outline.pl -i out/demo.html -t demo.txt -o out/txtimage_html
```

```console
$ xxd -r -p out/txtimage_txt.txt
$ xxd -r -p out/txtimage_html.txt
```

```console
$ python3 svg_to_png.py
```

The go to:

```
http://127.0.0.1:58080/convert/out?fillcol=0x550000&bgcol=cyan
```

# Static source

No python? No problem. It just globs the directory for svg images and outputs
HTML like the one below. Edit the `data` attribute of the object, or add more
`<div class="svg">` sections.

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <style type="text/css" media="screen">
      div.svg { cursor: pointer; border: grey solid 1px; width: 100px; float: left }
      object { pointer-events: none; width: 100%; }
      a { text-decoration: none; }
    </style>
    <script charset="utf-8">
      function convert() {
        var obj = this.querySelector('object');
        var svg = new XMLSerializer().serializeToString(
          obj.contentDocument.querySelector('svg'));
        var img = document.createElement('img');
        img.src = 'data:image/svg+xml;base64,' + btoa(svg);
        var link = this.querySelector('a');
        img.onload = function () {
          var cvs = document.createElement('canvas');
          cvs.width = 2000;
          cvs.height = 2000*img.height/img.width;
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
        if ('') {
          st.textContent += '* { background-color:  !important; }';
        }
        if ('') {
          st.textContent += '* { fill:  !important; }';
        }
        svg.appendChild(st);
      }
    </script>
  </head>
  <body>
    <p>Click on an image do download it as png. Use the
    width={num in px} URL parameter to adjust the size of the png.
    Use the bgcol={name or 0x??????} and fillcol={name or 0x??????}
    parameters to change the colors (i.e. replace '#' with '0x' if
    using hex colors).</p>
    
    <div class="svg" id="demo" onclick="convert.call(this)">
      <a href="#" download="demo.png"></a>
      <object data="/./demo.svg" onload="colorize.call(this)"></object>
    </div>
            
  </body>
</html>
```

# CREDIT

* All credit for the raster to ASCII image conversion goes to the creator of
  the online convertor at `https://www.text-image.com/convert/pic2`.
* `demo.svg` from `https://www.flaticon.com/free-icon/github-logo_3641`
