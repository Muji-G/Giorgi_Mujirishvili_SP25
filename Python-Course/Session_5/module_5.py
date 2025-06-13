from collections import Counter
import os
from pathlib import Path
from random import choice
from random import seed
from typing import List, Union

import requests
from requests.exceptions import ConnectionError
from gensim.utils import simple_preprocess


S5_PATH = Path(os.path.realpath(__file__)).parent

PATH_TO_NAMES = S5_PATH / "names.txt"
PATH_TO_SURNAMES = S5_PATH / "last_names.txt"
PATH_TO_OUTPUT = S5_PATH / "sorted_names_and_surnames.txt"
PATH_TO_TEXT = S5_PATH / "random_text.txt"
PATH_TO_STOP_WORDS = S5_PATH / "stop_words.txt"


def task_1():
    seed(1)
    with open(PATH_TO_NAMES, encoding="utf-8") as f:
        names = sorted(line.strip().lower() for line in f if line.strip())

    with open(PATH_TO_SURNAMES, encoding="utf-8") as f:
        surnames = [line.strip().lower() for line in f if line.strip()]

    full_names = [f"{name} {choice(surnames)}" for name in names]

    with open(PATH_TO_OUTPUT, "w", encoding="utf-8") as f:
        f.write("\n".join(full_names) + "\n")



def task_2(top_k: int):
    with open(PATH_TO_TEXT, encoding="utf-8") as f:
        text = f.read()

    with open(PATH_TO_STOP_WORDS, encoding="utf-8") as f:
        stop_words = set(word.strip().lower() for word in f if word.strip())

    words = simple_preprocess(text)

    filtered_words = [word for word in words if word not in stop_words]

    counter = Counter(filtered_words)
    return counter.most_common(top_k)


def task_3(url: str):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response
    except ConnectionError:
        raise ConnectionError


def task_4(data: List[Union[int, str, float]]):
    total = 0
    for value in data:
        try:
            total += float(value)
        except (ValueError, TypeError):
            continue
    return total


def task_5():
    try:
        a, b = input().split()
        a = float(a)
        b = float(b)

        if b == 0:
            print("Can't divide by zero")
        else:
            result = a / b
            print(int(result) if result.is_integer() else round(result, 3))
    except ValueError:
        print("Entered value is wrong")


