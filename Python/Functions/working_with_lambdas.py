def test_lambdas_can_be_assigned_to_variables_and_called_explicitly():
        add_one = lambda n: n + 1
        print(add_one(10))

# Remove hash from below to activate function
#test_lambdas_can_be_assigned_to_variables_and_called_explicitly()

    # ------------------------------------------------------------------

def make_order(order):
    return lambda qty: str(qty) + " " + order + "s"

def test_accessing_lambda_via_assignment():
    sausages = make_order('sausage')
    eggs = make_order('egg')

    print(sausages(3))
    print(eggs(2))

# Remove hash from below to activate function
#test_accessing_lambda_via_assignment()

def test_accessing_lambda_without_assignment():
    print(make_order('spam')(39823))

# Remove hash from below to activate function
#test_accessing_lambda_without_assignment()