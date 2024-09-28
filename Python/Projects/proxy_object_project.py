class Proxy:
    def __init__(self, target_object):
        self._messages = []
        self._obj = target_object
 
    def __getattr__(self, name):
        self._messages.append(name)
        return getattr(self._obj, name)

    def __setattr__(self, name, value):
        if name in ['_obj', '_messages']:
            super().__setattr__(name, value)
        else:
            self._messages.append(name)
            setattr(self._obj, name, value)

    def messages(self):
        return self._messages

    def was_called(self, name):
        return name in self._messages

    def number_of_times_called(self, name):
        return self._messages.count(name)
    
class Television:
    def __init__(self):
        self._channel = None
        self._power = None

    @property
    def channel(self):
        return self._channel

    @channel.setter
    def channel(self, value):
        self._channel = value

    def power(self):
        if self._power == 'on':
            self._power = 'off'
        else:
            self._power = 'on'

    def is_on(self):
        return self._power == 'on'
    
    def is_off(self):
        return self._power == 'off'


def test_proxy_method_returns_wrapped_object():
    # NOTE: The Television class is defined below
    tv = Proxy(Television())

    # Assert that the object is an instance of the Proxy class
    # and that the object is an instance of the Television class
    # Prints: True
    print(isinstance(tv, Proxy))

# Remove hash below to activate function
#test_proxy_method_returns_wrapped_object()

def test_tv_methods_still_perform_their_function():
    tv = Proxy(Television())

    tv.channel = 10
    tv.power()

    print(f"TV channel: {tv.channel}")
    print(f"{tv.is_on()}, The TV is on")

# Remove hash below to activate function
# test_tv_methods_still_perform_their_function()

def test_proxy_records_messages_sent_to_tv():
    tv = Proxy(Television())

    tv.power()
    tv.channel = 10

    print(f"Messages sent to TV: {tv.messages()}")

# Remove hash below to activate function
# test_proxy_records_messages_sent_to_tv()

def test_proxy_handles_invalid_messages():
    tv = Proxy(Television())

    try:
        tv.invalid_message()
    except AttributeError as err:
        print(f"Error message: {err}")

# Remove hash below to activate function
# test_proxy_handles_invalid_messages()

def test_proxy_reports_methods_have_been_called():
    tv = Proxy(Television())

    tv.power()
    # tv.channel = 10
    #Uncomment line ^ to receive true instance in boolean request for channel below

    print(f"Power method called: {tv.was_called('power')}")
    print(f"Channel method called: {tv.was_called('channel')}")
    
# Remove hash below to activate function
# test_proxy_reports_methods_have_been_called()

def test_proxy_counts_method_calls():
    tv = Proxy(Television())

    tv.power()
    tv.is_on()
    # Uncomment line ^ to receive true instance of boolean request for is_on method below
    tv.channel = 48
    tv.power()
    tv.is_off()
    # Uncomment line ^ to receive true instance of boolean request for is_off method below
    
    print(f"Number of times power method called: {tv.number_of_times_called('power')}")
    print(f"Number of times channel method called: {tv.number_of_times_called('channel')}")
    print(f"Number of times is_on method called: {tv.number_of_times_called('is_on')}")
    print(f"Number of times is_off method called: {tv.number_of_times_called('is_off')}")
    print(f"Messages sent to TV: {tv.messages()}")
    
# Remove hash below to activate function
# test_proxy_counts_method_calls()

def test_proxy_can_record_more_than_just_tv_objects():
    proxy = Proxy("Py Ohio 2010")

    result = proxy.upper()

    print(f"Result of upper method: {result}")    
    # "PY OHIO 2010"

    result = proxy.split()

    print(f"Result of split method: {result}")
    # (["Py", "Ohio", "2010"]
    print(f"Messages sent to proxy: {proxy.messages()}")
    # (['upper', 'split']

# Remove hash below to activate function
# test_proxy_can_record_more_than_just_tv_objects()

# ====================================================================
# The following code is to support the testing of the Proxy class.  No
# changes should be necessary to anything below this comment.

# Example class using in the proxy testing above.
# class Television:
#     def __init__(self):
#         self._channel = None
#         self._power = None

#     @property
#     def channel(self):
#         return self._channel

#     @channel.setter
#     def channel(self, value):
#         self._channel = value

#     def power(self):
#         if self._power == 'on':
#             self._power = 'off'
#         else:
#             self._power = 'on'

#     def is_on(self):
#         return self._power == 'on'

# Tests for the Television class.  All of theses tests should pass.

def test_it_turns_on():
    tv = Television()

    tv.power()
    
    print(f"TV is on: {tv.is_on()}")
    
# Remove hash below to activate function
# test_it_turns_on()

def test_it_also_turns_off():
    tv = Television()

    tv.power()
    tv.power()
    
    print(f"TV is off: {tv.is_off()}")
    
# Remove hash below to activate function
test_it_also_turns_off()

def test_edge_case_on_off(self):
    tv = Television()

    tv.power()
    tv.power()
    tv.power()

    self.assertTrue(tv.is_on())

    tv.power()

    self.assertFalse(tv.is_on())

def test_can_set_the_channel(self):
    tv = Television()

    tv.channel = 11
    self.assertEqual(11, tv.channel)
