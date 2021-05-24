import random
import time
from locust import HttpUser, task, between

class QuickstartUser(HttpUser):
    wait_time = between(0.5, 2.5) # seconds

    @task(1)
    def get_test(self):
        self.client.get("/front-echo/health", headers={"Ocp-Apim-Subscription-Key": "super-secure"}, name="GET health endpoint")

# POST
# post_id = random.randint(1, 100)