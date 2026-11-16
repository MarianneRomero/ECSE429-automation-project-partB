# ECSE429-automation-project-partB

## Dependencies

Run the following to install the required dependencies to run the unit test suite:

`pip install -r requirements.txt`

## Running the tests

Use the following command to run the tests in file order:

`python3 -m behave -D order=defined ./story_tests/features/categories`

Use the following command to run the tests in a random order (change the seed for a different ordering):

`python3 -m behave -D seed=1234 ./story_tests/features/categories`