import sys
import os

# Add the Examples directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'Examples'))

import Jims_dog
import Joes_dog

counter = 0

class AboutScope():
    pass
    #
    # NOTE:
    #   Look in Jims_dog.py and Joes_dog.py to see definitions of Dog used
    #   in the examples folder for this set of tests
    #

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

    def test_bare_bones_class_names_do_not_assume_the_current_scope(self):
        #print(f"{AboutScope.__name__} is defined.")
        print(AboutScope.str)
        print(str)
        print(f"{AboutScope.str == str}. {AboutScope.str} is not equal to {str}")

scope = AboutScope()
# Remove hash below to activate function
#scope.test_bare_bones_class_names_do_not_assume_the_current_scope()

