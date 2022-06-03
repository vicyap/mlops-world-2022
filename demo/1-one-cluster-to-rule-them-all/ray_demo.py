import os
from collections import Counter
from pprint import pprint
from ray.autoscaler.sdk import request_resources

import ray


RAY_ADDRESS = os.environ.get("RAY_ADDRESS", "ray://127.0.0.1:10001")


@ray.remote
def gethostname():
    import platform
    import time

    time.sleep(1)
    return platform.node()


def main():
    ray.init(RAY_ADDRESS)

    results = [gethostname.remote() for _ in range(100)]
    counter = Counter(ray.get(results))
    pprint(counter)


if __name__ == "__main__":
    main()
