#!/bin/bash
# You can take the results of your variables and plug them right into the table
letter_a=a
letter_b=b
letter_c=c

number_1=1
number_2=2
number_3=3

word_1=red
word_2=blue
word_3=orange

# Start with paste command as shown, with your first column following it (echo cmds)
example_table=$(paste -d ';' <(echo "$letter_a" ; echo "$letter_b" ; echo "$letter_c") <(
    # second column of table
    echo "$number_1" ; echo "$number_2" ; echo "$number_3") <(
    # Third/final column of table (be sure to pipe end of final column) 
    echo "$word_1" ; echo "$word_2" ; echo "$word_3") | 
    # Column cmd helps to create table
        # by creating labels needed to match number of columns you made above
    column -N Letters,Numbers,'Words (or colours)' -s ';' -o ' | ' -t   )

# Can use cat to neatly print out your table with some neat titles and shit
cat << EOF

         Example Table
        ---------------

$example_table

EOF
