from typing import Any, Dict, List, Tuple


def task_1(data_1: Dict[str, int], data_2: Dict[str, int]) -> Dict[str, int]:
    result = data_1.copy()
    for key, value in data_2.items():
        result[key] = result.get(key, 0) + value
    return result


def task_2() -> Dict[int, int]:
    return {i: i ** 2 for i in range(1, 16)}


def task_3(data: Dict[Any, List[str]]) -> list[str]:
    if not data:
        return []

    keys = list(data.keys())
    result = [""]

    for key in keys:
        current_letters = data[key]
        temp_result = []

        for prefix in result:
            for letter in current_letters:
                temp_result.append(prefix + letter)

        result = temp_result

    return result


def task_4(data: Dict[str, int]) -> List[str]:
    top_items = []

    for key, value in data.items():
        inserted = False
        for i in range(len(top_items)):
            if value > data[top_items[i]]:
                top_items.insert(i, key)
                inserted = True
                break
        if not inserted and len(top_items) < 3:
            top_items.append(key)

        if len(top_items) > 3:
            top_items = top_items[:3]

    return top_items

def task_5(data: List[Tuple[Any, Any]]) -> Dict[str, List[int]]:
    result: Dict[str, List[int]] = {}
    for key, value in data:
        result.setdefault(key, []).append(value)
    return result


def task_6(data: List[Any]):
    seen = set()
    result = []
    for item in data:
        if item not in seen:
            seen.add(item)
            result.append(item)
    return result


def task_7(words: [List[str]]) -> str:
    if not words:
        return ""

    prefix = words[0]
    for word in words[1:]:
        while not word.startswith(prefix):
            prefix = prefix[:-1]
            if not prefix:
                return ""
    return prefix


def task_8(haystack: str, needle: str) -> int:
    if needle == "":
        return 0
    return haystack.find(needle)

