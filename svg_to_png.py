#!/usr/bin/env python3
import simple
import logging
import sys
import os
from glob import glob

logger = logging.getLogger('SVG to PNG converter in our browser')
logger.setLevel(logging.DEBUG)
logger.addHandler(logging.StreamHandler(sys.stdout))

class SVGConvertor(simple.CORSHttpsServer):
    __API = '/convert/'
    __defaults = {
            'width': '2000',
            }
    endpoints = simple.Endpoints(
        convert={
                '': {
                    'args': simple.Endpoints.ARGS_ANY,
                    },
                },
            )
    
    def get_param(self, parname):
        val = super().get_param(parname)
        if val is not None:
            return val
        try:
            return self.__defaults[parname]
        except KeyError:
            return ''

    def do_convert(self, cmd, args):
        template = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <style type="text/css" media="screen">
      div.svg {{ cursor: pointer; border: grey solid 1px; width: 100px; float: left }}
      object {{ pointer-events: none; width: 100%; }}
      a {{ text-decoration: none; }}
    </style>
    <script charset="utf-8">
      function convert() {{
        var obj = this.querySelector('object');
        var svg = new XMLSerializer().serializeToString(
          obj.contentDocument.querySelector('svg'));
        var img = document.createElement('img');
        img.src = 'data:image/svg+xml;base64,' + btoa(svg);
        var link = this.querySelector('a');
        img.onload = function () {{
          var cvs = document.createElement('canvas');
          cvs.width = {width};
          cvs.height = {width}*img.height/img.width;
          cvs.getContext('2d').drawImage(img, 0, 0);
          link.href = cvs.toDataURL();
          link.onclick = function(e) {{e.stopPropagation();}};
          link.click();
          delete img;
          delete cvs;
          link.href = '#';
        }}
      }}
      function colorize() {{
        var svg = this.contentDocument.querySelector('svg');
        var xmlns = "http://www.w3.org/2000/svg";
        var st = document.createElementNS(xmlns, 'style');
        st.textContent = '';
        if ('{bgcol}') {{
          st.textContent += '* {{ background-color: {bgcol} !important; }}';
        }}
        if ('{fillcol}') {{
          st.textContent += '* {{ fill: {fillcol} !important; }}';
        }}
        svg.appendChild(st);
      }}
    </script>
  </head>
  <body>
    <p>Click on an image do download it as png. Use the
    width={{num in px}} URL parameter to adjust the size of the png.
    Use the bgcol={{name or 0x??????}} and fillcol={{name or 0x??????}}
    parameters to change the colors (i.e. replace '#' with '0x' if
    using hex colors).</p>
    {images}
  </body>
</html>
        '''
        
        cwd = args.strip('/')
        if not cwd:
            cwd = '.'

        images = ''
        for fname in glob("{}/*.svg".format(cwd)):
            images += '''
    <div class="svg" id="{name}" onclick="convert.call(this)">
      <a href="#" download="{name}.png"></a>
      <object data="/{img}" onload="colorize.call(this)"></object>
    </div>
            '''.format(img=fname,
                    name=os.path.basename(fname).rsplit('.',1)[0])

        page = template.format(images=images,
                width=self.get_param('width'),
                bgcol=self.get_param('bgcol').replace('0x','#'),
                fillcol=self.get_param('fillcol').replace('0x','#'))
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.send_header('Content-Length', len(page))
        self.end_headers()
        self.wfile.write(page.encode('utf-8'))

if __name__ == "__main__":
    httpd = simple.ThreadingCORSHttpsServer(('127.0.0.1', 58080), SVGConvertor)
    logger.error('''Go to http://127.0.0.1:58080/{api}/path/to/svgs in Google Chrome.'''.format(
    api=SVGConvertor._SVGConvertor__API.strip('/')))
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        httpd.socket.close()
