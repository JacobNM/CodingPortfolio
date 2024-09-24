class Nameable:
    def __init__(self):
        self._name = None

    def set_name(self, new_name):
        self._name = new_name

    def here(self):
        return "In Nameable class"

class Animal:
    def legs(self):
        return 4

    def can_climb_walls(self):
        return False

    def here(self):
        return "In Animal class"

class Pig(Animal):
    def __init__(self):
        super().__init__()
        self._name = "Jasper"

    @property
    def name(self):
        return self._name

    def speak(self):
        return "OINK"

    def color(self):
        return 'pink'

    def here(self):
        return "In Pig class"

class Spider(Animal):
    def __init__(self):
        super().__init__()
        self._name = "Boris"

    def can_climb_walls(self):
        return True

    def legs(self):
        return 8

    def color(self):
        return 'black'

    def here(self):
        return "In Spider class"

class Spiderpig(Pig, Spider, Nameable):
    def __init__(self):
        super()
        #super(Pig, self).__init__()
        #super(Nameable, self).__init__()
        self._name = "Jeff"
        
    def speak(self):
        return "This looks like a job for Spiderpig!"

    def here(self):
        return "In Spiderpig class"
    
#
# Hierarchy:
#               Animal
#              /     \
#             Pig   Spider  Nameable
#              \      |     /
#                Spiderpig
# ------------------------------------------------

def test_normal_methods_are_available_in_the_object():
    jeff = Spiderpig()
    print(jeff.speak())

# Remove hash to activate function
#test_normal_methods_are_available_in_the_object()

def test_base_class_methods_are_also_available_in_the_object():
    jeff = Spiderpig()
    try:
        print(f"{jeff.name}")
        jeff.set_name("Rover")
        print(f"{jeff.name}")
    except:
        print("This should not happen")
        print(f"{jeff.can_climb_walls}")

        
# Remove hash to activate function
#test_base_class_methods_are_also_available_in_the_object()

def test_base_class_methods_can_affect_instance_variables_in_the_object():
    jeff = Spiderpig()
    print(f"{jeff.name}")
    jeff.set_name("Rover")
    print(f"{jeff.name}")
    
# Remove hash to activate function
#test_base_class_methods_can_affect_instance_variables_in_the_object()

def test_left_hand_side_inheritance_tends_to_be_higher_priority():
    jeff = Spiderpig()
    print(f"{jeff.color()}")
    
# Remove hash to activate function
#test_left_hand_side_inheritance_tends_to_be_higher_priority()

def test_super_class_methods_are_higher_priority_than_super_super_classes():
    jeff = Spiderpig()
    print(f"{jeff.legs()}")

# Remove hash to activate function
#test_super_class_methods_are_higher_priority_than_super_super_classes()

def test_we_can_inspect_the_method_resolution_order():
    #
    # MRO is the order in which Python looks for a method in a class hierarchy
    # MRO = Method Resolution Order
    mro = type(Spiderpig()).mro()
    try:
        print(f"Method Resolution Order call 1: {mro[0].__name__}")
        print(f"Method Resolution Order call 2: {mro[1].__name__}")
        print(f"Method Resolution Order call 3: {mro[2].__name__}")
        print(f"Method Resolution Order call 4: {mro[3].__name__}")
        print(f"Method Resolution Order call 5: {mro[4].__name__}")
        print(f"Method Resolution Order call 6: {mro[5].__name__}")
        print(f"Method Resolution Order call 7: {mro[6].__name__}")
    except IndexError as error:
        print(f"{IndexError.__name__} when attempting to call method resolution order number. {error}")    
    
# Remove hash to activate function
#test_we_can_inspect_the_method_resolution_order()