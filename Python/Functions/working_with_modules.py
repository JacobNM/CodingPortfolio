import sys
import os

# Add the Functions directory to the Python path
#sys.path.append(os.path.join(os.path.dirname(__file__), 'Functions'))

from another_local_module import *
from local_module_with_all_defined import *

def test_importing_other_python_scripts_as_modules():
    #from local_module import Duck # local_module.py
    import local_module
    duck = local_module.Duck()
    print(f"{duck.name == 'Daffy'}. {duck.name} is equal to Daffy")

# Remove hash below to activate function
#test_importing_other_python_scripts_as_modules()