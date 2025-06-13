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
    counter = {}

    with PATH_TO_STOP_WORDS.open(encoding='utf-8') as stop_word_txt, PATH_TO_TEXT.open(encoding='utf-8') as txt_file:
        stop_words = set(stop_word_txt.read().splitlines())
        word_regex = re.compile(r'\w+')
        words = word_regex.findall(txt_file.read().lower())

        for word in words:
            if word in stop_words:
                continue

            counter[word] = counter.get(word, 0) + 1

    results = sorted(counter.items(), key=lambda x: x[1], reverse=True)[:top_k]
    return results


def task_3(url: str):
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response
    except ConnectionError:
        raise ConnectionError


def task_4(data: List[Union[int, str, float]]):
    total = 0
    for item in data:
        try:
            total += item
        except (TypeError, ValueError):
            total += float(item)

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


