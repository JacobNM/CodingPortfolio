import sys
import os

# Add the Examples directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'Examples'))

import Jims_dog
import Joes_dog

counter = 0

class AboutScope():
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

# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_bare_bones_class_names_do_not_assume_the_current_scope()

    def test_nested_string_is_not_the_same_as_the_system_string(self):
        print(f"{self.str == type('HI')}. {self.str} is not equal to {type('HI')}")
        
# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_nested_string_is_not_the_same_as_the_system_string()

    def test_str_without_self_prefix_stays_in_the_global_scope(self):
        print(f"{str == type('HI')}. {str} is equal to {type('HI')}")
    
# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_str_without_self_prefix_stays_in_the_global_scope()

# ------------------------------------------------------------------

    PI = 3.1416

    def test_constants_are_defined_with_an_initial_uppercase_letter(self):
        print(f"{AboutScope.PI} is equal to {self.PI}")
        print(f"{3.1416} is equal to {self.PI}")
        
# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_constants_are_defined_with_an_initial_uppercase_letter()

    def test_constants_are_assumed_by_convention_only(self):
        self.PI = "rhubarb"
        print(f"{self.PI} is equal to rhubarb")
    
# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_constants_are_assumed_by_convention_only()

    # ------------------------------------------------------------------

    def increment_using_local_counter(self, counter):
        counter = counter + 1
    
    def increment_using_global_counter(self):
        global counter
        counter = counter + 1
    
    def test_incrementing_with_local_counter(self):
        global counter
        start = counter
        self.increment_using_local_counter(start)
        print(f"{counter == start + 1}. {counter} is not equal to {start + 1}")
    
# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_incrementing_with_local_counter()

    def test_incrementing_with_global_counter(self):
        global counter
        start = counter
        self.increment_using_global_counter()
        print(f"{counter == start + 1}. {counter} is equal to {start + 1}")

# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_incrementing_with_global_counter()

    # ------------------------------------------------------------------

    def local_access(self):
        stuff = 'eels'
        def from_the_league():
            stuff = 'this is a local shop for local people'
            return stuff
        return from_the_league()
    
    def nonlocal_access(self):
        stuff = 'eels'
        def from_the_boosh():
            nonlocal stuff
            return stuff
        return from_the_boosh()
    
    def test_getting_something_locally(self):
        print(self.local_access())
    
# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_getting_something_locally()

    def test_getting_something_nonlocally(self):
        print(self.nonlocal_access())
        
# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_getting_something_nonlocally()

# ------------------------------------------------------------------

    global deadly_bingo
    deadly_bingo = ['A15', 'C90', 'G60', 'G54', 'B12', 'B6', 'B60', 'B5']
    
    def test_global_attributes_can_be_created_in_the_middle_of_a_class():
        print(f"{deadly_bingo[5] == 'B6'}. {deadly_bingo[5]} is equal to B6")

# Remove hashes below to activate function
#scope = AboutScope()
#scope.test_global_attributes_can_be_created_in_the_middle_of_a_class()