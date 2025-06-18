# import time
from typing import List
import time

Matrix = List[List[int]]


def task_1(exp: int):
    def power(base):
        return base ** exp

    return power


def task_2(*args, **kwags):
    for arg in args:
        print(arg)
    for value in kwargs.values():
        print(value)


def helper(func):
    def wrapper(*args, **kwargs):
        print("Hi, friend! What's your name?")
        func(*args, **kwargs)
        print("See you soon!")
    return wrapper


@helper
def task_3(name: str):
    print(f"Hello! My name is {name}.")


def timer(func):
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        run_time = end - start
        print(f"Finished {func.__name__} in {run_time:.4f} secs")
        return result
    return wrapper



@timer
def task_4():
    return len([1 for _ in range(0, 10**8)])


def task_5(matrix: Matrix) -> Matrix:
    return [list(row) for row in zip(*matrix)]



def task_6(queue: str):
    balance = 0
    for char in queue:
        if char == '(':
            balance += 1
        elif char == ')':
            balance -= 1
        if balance < 0:
            return False  # More ')' than '(' at some point
    return balance == 0
