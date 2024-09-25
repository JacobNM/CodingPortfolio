import sys
import os

from another_local_module import *
from local_module_with_all_defined import *

def test_importing_other_python_scripts_as_modules():
    #from local_module import Duck # local_module.py
    import local_module
    duck = local_module.Duck()
    print(f"{duck.name == 'Daffy'}. {duck.name} is equal to {local_module.Duck().name}")

# Remove hash below to activate function
#test_importing_other_python_scripts_as_modules()

def test_importing_attributes_from_classes_using_from_keyword():
    from local_module import Duck
    duck = Duck()
    print(f"{duck.name == 'Daffy'}. {duck.name} is equal to {Duck().name}")

# Remove hash below to activate function
#test_importing_attributes_from_classes_using_from_keyword()

def test_we_can_import_multiple_items_at_once():

    # Add the Examples directory to the Python path
    sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'Examples'))
    
    import Jims_dog, Joes_dog

    jims_dog = Jims_dog.Dog()
    joes_dog = Joes_dog.Dog()

    print(jims_dog.identify())
    print(joes_dog.identify())
    print(f"{jims_dog.identify() != Jims_dog.Dog().identify}. These are not the same. The first {jims_dog.identify()} is a variable. The second {Jims_dog.Dog().identify()} is an imported class method.")
    
# Remove hash below to activate function
#test_we_can_import_multiple_items_at_once()

def test_importing_all_module_attributes_at_once():
    """
    importing all attributes at once is done like so:
        from another_local_module import *
    The import wildcard cannot be used from within classes or functions.
    """
    
    goose = Goose()
    hamster = Hamster()
    
    print(goose.name)
    print(hamster.name)
    
    # Compare variables with imported class methods
    #print(f"{goose.name != Goose().name}. These are not the same. The first {goose.name} is a variable. The second {Goose().name} is an imported class method.")
    #print(f"{hamster.name != Hamster().name}. These are not the same. The first {hamster.name} is a variable. The second {Hamster().name} is an imported class method.")

# Remove hash below to activate function
#test_importing_all_module_attributes_at_once()
