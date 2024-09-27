class Dog:
    pass

def test_objects_are_objects():  
    fido = Dog()
    
    print(f"{isinstance(fido, object)}. {fido} is an object.")

# Remove hash below to activate function
#test_objects_are_objects()

def test_classes_are_types():
    print(f"{Dog.__class__ == type}. {Dog.__class__} is a type.")

# Remove hash below to activate function
#test_classes_are_types()

def test_classes_are_objects_too():
    print(f"{issubclass(Dog, object)}. {Dog} is a subclass of object.")

# Remove hash below to activate function
#test_classes_are_objects_too()

def test_objects_have_methods():
    fido = Dog()
    print(f"\nThere are {len(dir(fido))} methods in dir(fido). These methods are:\n")
    # While loop to print all methods in dir(fido) and number each incrementally
    method_count = 0
    while method_count < len(dir(fido)):
        print(f"{method_count + 1}. {dir(fido)[method_count]}")
        method_count += 1

# Remove hash below to activate function
#test_objects_have_methods()

def test_classes_have_methods():
    print(f"\nThere are {len(dir(Dog))} methods in dir(Dog). These methods are:\n")
    # While loop to print all methods in dir(Dog) and number each incrementally
    method_count = 0
    while method_count < len(dir(Dog)):
        print(f"{method_count + 1}. {dir(Dog)[method_count]}")
        method_count += 1

# Remove hash below to activate function
#test_classes_have_methods()

def test_creating_objects_without_defining_a_class():
    singularity = object()
    print(f"\nThere are {len(dir(singularity))} methods in dir(singularity). These methods are:\n")
    # While loop to print all methods in dir(singularity) and number each incrementally
    method_count = 0
    while method_count < len(dir(singularity)):
        print(f"{method_count + 1}. {dir(singularity)[method_count]}")
        method_count += 1

# Remove hash below to activate function
#test_creating_objects_without_defining_a_class()

def test_defining_attributes_on_individual_objects():
    fido = Dog()
    fido.legs = 4
    print(f"\n{fido.legs} is the number of legs on the object called fido.")

# Remove hash below to activate function
#test_defining_attributes_on_individual_objects()

def test_defining_functions_on_individual_objects():
    fido = Dog()
    fido.wag = lambda : 'Wag, Wag'
    print(f"\nFido is {fido.wag()}. This is the result of the lambda function fido.wag.")
    
# Remove hash below to activate function
#test_defining_functions_on_individual_objects()

def test_other_objects_are_not_affected_by_these_singleton_functions():
    fido = Dog()
    rover = Dog()
    
    def wag():
        return 'Wagging away'
    
    fido.wag = wag
    print(f"\nFido is {fido.wag()}. This is the result of the function 'wag'.")
    
    try:
        print(f"\nRover is {rover.wag()}. This is the result of the function 'wag'.")
    except AttributeError as msg:
        print(f"\n{AttributeError} has been raised. {msg}")
        rover.wag = wag
        print(f"\nRover is {rover.wag()}. This is the result of the function 'wag'.")
    
# Remove hash below to activate function
#test_other_objects_are_not_affected_by_these_singleton_functions()

# ------------------------------------------------------------------

class Dog2:
    def wag(self):
        return 'Wagging away instance'
    
    def bark(self):
        return 'Barking away instance'
    
    def growl(self):
        return 'Growling away instance'
    
    @staticmethod
    def bark():
        return 'staticmethod bark, arg: None'
    
    @classmethod
    def growl(cls):
        return 'classmethod growl, arg: cls=' + cls.__name__

def test_since_classes_are_objects_you_can_define_singleton_methods_on_them_too():
    print(f"\n{Dog2.growl()} is the result of the class method growl.")
    print(f"\n{Dog2.bark()} is the result of the static method bark.")
    
# Remove hash below to activate function
#test_since_classes_are_objects_you_can_define_singleton_methods_on_them_too()

def test_classmethods_are_not_independent_of_instance_methods():
    fido = Dog2()
    print(f"\n{fido.growl()} is the result of the instance method growl.")
    print(f"\n{Dog2.growl()} is the result of the class method growl.")
    
# Remove hash below to activate function
#test_classmethods_are_not_independent_of_instance_methods()

def test_staticmethods_are_unbound_functions_housed_in_a_class():
    print(f"\n{Dog2.bark()} is the result of the static method bark.")
    
# Remove hash below to activate function
#test_staticmethods_are_unbound_functions_housed_in_a_class()

def test_staticmethods_also_overshadow_instance_methods():
    fido = Dog2()
    print(f"\n{fido.bark()} is the result of the instance method bark.")
    
# Remove hash below to activate function
#test_staticmethods_also_overshadow_instance_methods()

# ------------------------------------------------------------------

class Dog3:
    def __init__(self):
        self._name = None
        
    def get_name_from_instance(self):
        return self._name
    
    def set_name_from_instance(self, name):
        self._name = name
        
    @classmethod
    def get_name(cls):
        return cls._name
    
    @classmethod
    def set_name(cls, name):
        cls._name = name
    
    name = property(get_name, set_name)
    name_from_instance = property(get_name_from_instance, set_name_from_instance)
    
def test_classmethods_can_not_be_used_as_properties():
    fido = Dog3()
    try:
        print(f"\n{fido.name} is the result of the property name.")
    except TypeError as msg:
        print(f"\n{TypeError} has been raised. {msg}")
        
# Remove hash below to activate function
#test_classmethods_can_not_be_used_as_properties()

def test_classes_and_instances_do_not_share_instance_attributes():
    fido = Dog3()
    fido.set_name_from_instance('Fido')
    fido.set_name('Rover')
    
    print(f"\n{fido.get_name_from_instance()} is the result of the property method get_name_from_instance.")
    print(f"{Dog3.get_name()} is the result of the class method get_name.")
    
    try:
        print(f"{Dog3.get_name_from_instance()} is the result of the property method get_name.")
    except TypeError as msg:
        print(f"\n{TypeError} has been raised. {msg}")
    
# Remove hash below to activate function
#test_classes_and_instances_do_not_share_instance_attributes()

def test_classes_and_instances_do_share_class_attributes():
    fido = Dog3()
    fido.set_name('Fido')
    
    print(f"\n{fido.get_name()} is the result of the property method get_name.")
    print(f"{Dog3.get_name()} is the result of the class method get_name.")
    
# Remove hash below to activate function
#test_classes_and_instances_do_share_class_attributes()

# ------------------------------------------------------------------

class Dog4:
    def a_class_method(cls):
        return 'dogs class method'
    
    def a_static_method():
        return 'dogs static method'
    
    a_class_method = classmethod(a_class_method)
    a_static_method = staticmethod(a_static_method)
    
def test_you_can_define_class_methods_without_using_a_decorator():
    print(f"\n{Dog4.a_class_method()} is the string returned in the class method a_class_method.")
    
# Remove hash below to activate function
#test_you_can_define_class_methods_without_using_a_decorator()

def test_you_can_define_static_methods_without_using_a_decorator():
    print(f"\n{Dog4.a_static_method()} is the string returned in the static method a_static_method.")
    
# Remove hash below to activate function
#test_you_can_define_static_methods_without_using_a_decorator()

# ------------------------------------------------------------------

def test_heres_an_easy_way_to_explicitly_call_class_methods_from_instance_methods():
    fido = Dog4()
    print(f"\n{fido.__class__.a_class_method()} is the string returned in the class method a_class_method.")
    
# Remove hash below to activate function
#test_heres_an_easy_way_to_explicitly_call_class_methods_from_instance_methods()