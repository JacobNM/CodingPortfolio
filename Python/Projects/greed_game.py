

def score(dice):
    score = 0
    counts = [0] * 7

    for die in dice:
        counts[die] += 1

    for i in range(1, 7):
        if counts[i] >= 3:
            if i == 1:
                score += 1000
            else:
                score += i * 100
            counts[i] -= 3

    score += counts[1] * 100
    score += counts[5] * 50

    return score

class AboutScoringProject():
    def test_score_of_an_empty_list_is_zero():
        print(score([]))
    
    # Remove hash below to activate function
    #test_score_of_an_empty_list_is_zero() 

    def test_score_of_a_single_roll_of_5_is_50():
        print(score([5]))

    # Remove hash below to activate function
    #test_score_of_a_single_roll_of_5_is_50()
    
    def test_score_of_a_single_roll_of_1_is_100():
        print(score([1]))

    # Remove hash below to activate function
    #test_score_of_a_single_roll_of_1_is_100()    
    
    def test_score_of_multiple_1s_and_5s_is_the_sum_of_individual_scores():
        print(score([1,5,5,1]))

    # Remove hash below to activate function
    #test_score_of_multiple_1s_and_5s_is_the_sum_of_individual_scores()
    
    def test_score_of_single_2s_3s_4s_and_6s_are_zero():
        print(score([2,3,4,6]))
        
    # Remove hash below to activate function
    #test_score_of_single_2s_3s_4s_and_6s_are_zero()

    def test_score_of_a_triple_1_is_1000():
        print(score([1,1,1]))

    # Remove hash below to activate function
    #test_score_of_a_triple_1_is_1000()
    
    def test_score_of_other_triples_is_100x():
        print(score([2,2,2]))
        print(score([3,3,3]))
        print(score([4,4,4]))
        print(score([5,5,5]))
        print(score([6,6,6]))

    # Remove hash below to activate function
    #test_score_of_other_triples_is_100x()
    
    def test_score_of_mixed_is_sum():
        print(score([2,5,2,2,3]))
        print(score([5,5,5,5]))
        print(score([1,1,1,5,1]))

    # Remove hash below to activate function
    #test_score_of_mixed_is_sum()
    
    def test_ones_not_left_out():
        print(score([1,2,2,2]))
        print(score([1,5,2,2,2]))

    # Remove hash below to activate function
    #test_ones_not_left_out()