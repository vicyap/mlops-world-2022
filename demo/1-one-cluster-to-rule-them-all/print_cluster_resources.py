import ray
ray.init("ray://127.0.0.1:10001")

cluster_resources = ray.cluster_resources()
CPUs = int(cluster_resources["CPU"])
memory = round(cluster_resources["memory"] / (1000 ** 3))
print(f"CPUs = {CPUs}")
print(f"memory = {memory}G")
