#!/usr/bin/env python
# -*- coding: UTF-8 -*-

import sys, os, json
sys.path.append(os.environ['PANLEX_TOOLDIR'] + '/libpython')
from alex.hantool import HanText
from flask import Flask, request, abort

app = Flask(__name__)

ht = HanText()

@app.route('/', methods=['GET'])
def scripts():
    cmn = request.args.get('cmn', '')

    if cmn:
        ht.update(cmn)

        result = {
            'conflict': ht.has_script_conflict(),
            'scripts':  sorted(ht.get_scripts())
        }

        return json.dumps(result)
    else:
        abort(409)


if __name__ == '__main__':
    app.run(port=3000)
