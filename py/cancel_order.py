# -*- coding: utf-8 -*-
from HuobiServices import *
import sys
import json

if __name__ == '__main__':
    order_id = sys.argv[1].split('=')[1]
    json.dump(cancel_order(order_id), sys.stdout)
