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
    __templatefile = 'template.html'
    endpoints = simple.Endpoints(
        convert={
                '': {
                    'args': simple.Endpoints.ARGS_ANY,
                    },
                },
            )
    
    def do_convert(self, cmd, args):
        try:
            with open(self.__templatefile) as f:
                template = f.read()
        except IOError as e:
            logger.error(str(e))
            return
        
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

        page = template.format(images=images)
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
