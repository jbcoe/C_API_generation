# Generator module for Python 2 and 3.

import generators
import os

def generator(module_name, binding, api_classes, env, args, output_dir):
    module_dir = os.path.join(output_dir, module_name)
    if not os.path.exists(module_dir):
        os.makedirs(module_dir)

    with open(os.path.join(module_dir, '__init__.py'), 'w') as o:
        o.write(
"""import sys
if sys.version_info[0] == 3:  
    from interop_py3 import *
else:
    from interop_py2 import *
""")
    for o in [os.path.join(module_dir, x) for x in ['interop_py2.py', 'interop_py3.py']]: 
        generators.generate_single_output_file(module_name, 'py.tmpl', api_classes, env, args, o)

def setup_plugin(context):
    context.register(generator, ['python'])

