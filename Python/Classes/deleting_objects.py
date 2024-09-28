def test_del_can_remove_slices():
    lottery_nums = [4, 8, 15, 16, 23, 42]
    print(f"Current lottery numbers: {lottery_nums}")

    del lottery_nums[1]
    del lottery_nums[2:4]
    print(f"New lottery numbers: {lottery_nums}")

# Remove hash below to activate function
#test_del_can_remove_slices()

def test_del_can_remove_entire_lists():
    lottery_nums = [4, 8, 15, 16, 23, 42]
    print(f"Current lottery numbers: {lottery_nums}")

    del lottery_nums
    
    try:
        print(f"New lottery numbers: {lottery_nums}")
    except UnboundLocalError as ex:
        print(f"{UnboundLocalError.__name__} has been raised: {ex}")
    
# Remove hash below to activate function
#test_del_can_remove_entire_lists()

# ====================================================================

class ClosingSale:
    def __init__(self):
        self.hamsters = 7
        self.zebras = 84

    def cameras(self):
        return 34

    def toilet_brushes(self):
        return 48

    def jellies(self):
        return 5
    
def test_del_can_remove_attributes():
    crazy_discounts = ClosingSale()
    # List camera, toilet brush, and jelly attributes
    print(f"Current attributes: {crazy_discounts.__dict__}")
    
    #print(f"Current attributes: {ClosingSale.__dict__.items()}")

    del ClosingSale.toilet_brushes
    del crazy_discounts.hamsters
    print(f"New attributes: {crazy_discounts.__dict__}")

    try:
        still_available = crazy_discounts.toilet_brushes()
    except AttributeError as e:
        err_msg1 = e.args[0]
        print(f"toilet_brushes() has been removed: {err_msg1}")

    try:
        still_available = crazy_discounts.hamsters
    except AttributeError as e:
        err_msg2 = e.args[0]
        print(f"hamsters has been removed: {err_msg2}")
        
# Remove hash below to activate function
#test_del_can_remove_attributes()

# ====================================================================

class ClintEastwood:
    def __init__(self):
        self._name = None

    def get_name(self):
        try:
            return self._name
        except:
            return "The man with no name"
    
    def set_name(self, name):
        self._name = name
    
    def del_name(self):
        del self._name
    
    name = property(get_name, set_name, del_name, \
        "Mr Eastwood's current alias")

def test_del_works_with_properties():
    cowboy = ClintEastwood()
    #print(f"\nDefault alias: {cowboy.name}")
    cowboy.name = 'Senor Ninguno'
    print(f"\nNew alias added: {cowboy.name}")

    
    del cowboy.name
    print("\nAlias removed")
    print(f"Default alias: {cowboy.name}")
    print()

# Remove hash below to activate function
#test_del_works_with_properties()

# ====================================================================

class Prisoner:
    def __init__(self):
        self._name = None

    @property
    def name(self):
        try:
            return self._name
        except:
            return "Number Six"
    
    @name.setter
    def name(self, name):
        self._name = name
    
    @name.deleter
    def name(self):
        del self._name        
        
def test_another_way_to_make_a_deletable_property():
    citizen = Prisoner()
    citizen.name = "Patrick"
    print(f"\nNew citizen added: {citizen.name}")

    del citizen.name
    print("\ncitizen deleted")
    print(f"Default name: {citizen.name}")
    
# Remove hash below to activate function
test_another_way_to_make_a_deletable_property()

# ====================================================================
