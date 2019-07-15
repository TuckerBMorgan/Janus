from zeroconf import ServiceBrowser, Zeroconf
from typing import cast
import threading
import socket
import queue
import cv2
import io
from PIL import Image
import numpy as np

q = queue.Queue()
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

searchingCharacters = [b'E', b'N', b'D',b'P',b'N',b'G']

flagCharacter = 0
numberOfPngs = 0

def advanceSearchingCharacter(currentIndex):
    if currentIndex + 1 == len(searchingCharacters):
        return -1
    else:
        return currentIndex + 1



hasConnection = False
class MyListener:
    def remove_service(self, zeroconf, type, name):
        print("Service %s removed" % (name,))

    def add_service(self, zeroconf, type, name):
        info = zeroconf.get_service_info(type, name)
        print("Service %s added, service info: %s" % (name, info))
        addresses = ["%s" % (socket.inet_ntoa(addr)) for addr in info.addresses]
        s.connect((addresses[0], info.port))
        global hasConnection
        hasConnection = True

def drain_q():
    f = open('hdr19201080.png', 'wb')
    test = []
    while True:
        data = q.get(block=True, timeout=None)
        test.insert(len(test), data)
        f.write(data)
    
def listen_thread():
    zeroconf = Zeroconf()
    listener = MyListener()
    _browser = ServiceBrowser(zeroconf, "_eye._tcp.local.", listener)
    try:
        while hasConnection is False:
            i = 0
        
        while hasConnection is True:
            data = s.recv(1024)
            q.put(data)
    finally:
        zeroconf.close()

x = threading.Thread(target=listen_thread)
y = threading.Thread(target=drain_q)
x.start()
y.start()