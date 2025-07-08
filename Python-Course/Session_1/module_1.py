from typing import List


def task_1(array: List[int], target: int) -> List[int]:
    seen = set()
    for number in array:
        complement = target - number
        if complement in seen:
            return [complement, number]
        seen.add(number)
    return []
    pass


def task_2(number: int) -> int:
    negative = number < 0
    number = abs(number)
    reversed_num = 0

    while number != 0:
        digit = number % 10
        reversed_num = reversed_num * 10 + digit
        number = number // 10

    if negative:
        reversed_num = -reversed_num

    return reversed_num
    pass


def task_3(array: List[int]) -> int:
    for i in range(len(array)):
        val = array[i]
        # Check against earlier values only
        for j in range(i):
            if array[j] == val:
                return val
    return -1
    pass


def task_4(string: str) -> int:
    roman_to_int = {
        'I': 1, 'V': 5, 'X': 10,
        'L': 50, 'C': 100,
        'D': 500, 'M': 1000
    }

    total = 0
    prev_value = 0

    for char in reversed(string):
        value = roman_to_int[char]
        if value < prev_value:
            total -= value
        else:
            total += value
            prev_value = value

    return total
    pass


def task_5(array: List[int]) -> int:
    if not array:
        return -1  # Or raise an error if empty list not allowed
    smallest = array[0]
    for i in range(1, len(array)):
        if array[i] < smallest:
            smallest = array[i]
    return smallest