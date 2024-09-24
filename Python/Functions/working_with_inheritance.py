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
        return "Wag, wag, wag"

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

def test_subclasses_add_new_behavior():
    chico = Chihuahua("Chico")
    # Chico can wag his tail because wag() is an attribute of Chihuahua
    print(f"{chico.wag()} goes the {Chihuahua.__name__} named {chico._name}'s tail")
    fido = Dog("Fido")
    
    # Raise attribute error because wag() is not an attribute of Dog
    try:
        print(f"{fido.wag()} goes the {Dog.__name__} named {fido._name}'s tail")
    except AttributeError as error:
        # Print attribute error message "object has not attribute"
        print(error)
        print(f"This is an {AttributeError.__name__}.")
        print(f"{Dog.__name__} named {fido._name} does not wag")
        
    # Fido can bark because bark() is an attribute of Dog
    print(f"{fido.bark()} is the sound the {Dog.__name__} named {fido._name} makes")

# Remove hash below to activate function
#test_subclasses_add_new_behavior()

def test_subclasses_can_modify_existing_behavior():
    chico = Chihuahua("Chico")
    print(f"{chico.bark()} goes the {Chihuahua.__name__} named {chico._name}")
    fido = Dog("Fido")
    print(f"{fido.bark()} goes the {Dog.__name__} named {fido._name}")
    
# Remove hash below to activate function
#test_subclasses_can_modify_existing_behavior()

# ------------------------------------------------------------------

class BullDog(Dog):
    def bark(self):
        return super().bark() + ", GRR"
        # Note, super() is much simpler to use in Python 3!

def test_subclasses_can_invoke_parent_behavior_via_super():
    ralph = BullDog("Ralph")
    print(f"{ralph.bark()} goes the {BullDog.__name__} named {ralph._name}")

# Remove hash below to activate function
#test_subclasses_can_invoke_parent_behavior_via_super()

class GreatDane(Dog):
    def growl(self):
        return super().bark() + ", GROWL"

def test_super_works_across_methods():
    george = GreatDane("George")
    print(f"{george.growl()} goes the {GreatDane.__name__} named {george._name}")

# Remove hash below to activate function
#test_super_works_across_methods()

# ------------------------------------------------------------------

class Pug(Dog):
    def __init__(self, name):
        pass

class Greyhound(Dog):
    def __init__(self, name):
        super().__init__(name)

def test_base_init_does_not_get_called_automatically():
    snoopy = Pug("Snoopy")
    try:
        print(f"{snoopy.name} is the name of the {Pug.__name__} named {snoopy._name}")
    except AttributeError as error:
        print(error)
        print(f"This is an {AttributeError.__name__}.")
        print(f"{Pug.__name__} does not have a name")

# Remove hash below to activate function
test_base_init_does_not_get_called_automatically()

def test_base_init_has_to_be_called_explicitly():
    boxer = Greyhound("Boxer")
    print(f"{boxer.name} is the name of the {Greyhound.__name__} named {boxer._name}")
    
# Remove hash below to activate function
#test_base_init_has_to_be_called_explicitly()