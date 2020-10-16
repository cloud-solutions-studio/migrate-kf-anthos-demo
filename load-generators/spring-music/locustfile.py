#!/usr/bin/python
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import random
from locust import HttpLocust, TaskSet, between

albums = [
    '5801c98c-4db0-432e-94a3-1f10ca38c3e7',
    'a208bce1-3d20-439f-9126-c23756f786f3',
    'f2a00c48-779f-4074-9735-9a8b5be9b2b2',
    'fb3dba71-3087-41b4-ae60-8c4d8e784f74',
    'ac6ae816-e678-4d7d-94db-22b05c45ac22',
    '5e47b3b9-a655-4af9-8206-6d2f8abb7c45',
    '270bcbab-6f60-4844-b4fd-839c14c4af3b',
    '3b70f589-0dab-49d2-9f7a-37c3dc71b8f0',
    'd5520009-2c9f-4036-a5a3-2008964a003b']

def index(l):
    l.client.get("/")

def browseAlbum(l):
    l.client.get("/albums/" + random.choice(albums))

def viewAlbums(l):
    l.client.get("/albums")

class UserBehavior(TaskSet):

    def on_start(self):
        index(self)

    tasks = {index: 1,
        browseAlbum: 10,
        viewAlbums: 3}

class WebsiteUser(HttpLocust):
    task_set = UserBehavior
    wait_time = between(1, 10)
