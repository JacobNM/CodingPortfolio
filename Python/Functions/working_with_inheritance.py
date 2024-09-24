class Dog:
    def __init__(self, name):
        self._name = name

    @property
    def name(self):
        return self._name

    def bark(self):
        return "WOOF"

class Chihuahua(Dog):
    def wag(self):
        return "happy"

    def bark(self):
        return "yip"

def test_subclasses_have_the_parent_as_an_ancestor():
    print(Chihuahua, Dog)
    # Extract the word Chihuahua from the subclass
    #print(f"{Chihuahua.__name__}")
    # print true if Chihuahua is a subclass of Dog
    print(f"{issubclass(Chihuahua, Dog)}. {Chihuahua.__name__} is a subclass of {Dog}")

# Remove hash below to activate function
#test_subclasses_have_the_parent_as_an_ancestor()

def test_all_classes_in_python_3_ultimately_inherit_from_object_class():
    print(f"{issubclass(Chihuahua, object)}. {Chihuahua.__name__} is a subclass of {object}")
    # Note: This isn't the case in Python 2. In that version you have
    # to inherit from a built in class or object explicitly

# Remove hash below to activate function
#test_all_classes_in_python_3_ultimately_inherit_from_object_class()

def test_instances_inherit_behavior_from_parent_class():
    chico = Chihuahua("Chico")
    print(f"{chico.name} is the name of the {Chihuahua.__name__}")

# Remove hash below to activate function
#test_instances_inherit_behavior_from_parent_class()

