import sys
import os

# Add the Examples directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'Examples'))

import Jims_dog
import Joes_dog

counter = 0

def test_dog_is_not_available_in_the_current_scope():
    try:
        fido = Dog()
    except NameError as ex:
        print(NameError.__name__)
        print(ex)

# Remove hash below to activate function
#test_dog_is_not_available_in_the_current_scope()

def test_you_can_reference_nested_classes_using_the_scope_operator():
    fido = Jims_dog.Dog()
    rover = Joes_dog.Dog()
    print(fido.identify())
    print(rover.identify())
    print(f"{type(fido) == type(rover)}. {type(fido)} is not equal to {type(rover)}")
    print(f"{Jims_dog.Dog == Joes_dog.Dog}. {Jims_dog.Dog} is not equal to {Joes_dog.Dog}")

# Remove hash below to activate function
#test_you_can_reference_nested_classes_using_the_scope_operator()

# ------------------------------------------------------------------

class str:
    pass

def test_bare_bones_class_names_do_not_assume_the_current_scope():
    print(f"{AboutScope.str} is not equal to {str}")