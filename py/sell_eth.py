# -*- coding: utf-8 -*-

# 导入所有的包
import sys
import json
import time
import sqlite3
import base64
import hashlib
import hmac
import json
import urllib
import urllib.parse
import urllib.request
import requests
from db import *
from update_all import *
from update_assets import *
from deal_records import *
from open_orders import *
from huobi_price import *

# 切换测试环境或正式环境
TEST_ENV = False

# 建立数据库实例
if TEST_ENV:
    CONN = sqlite3.connect(db_path())
else:
    CONN = sqlite3.connect(db_path())
# 设定文档路径
PARAMS = get_sell_eth_setup()
# Log文档路径
LOG_FILE = 'auto_invest_eth_log.txt'

# 初始化火币账号ID及API密钥
ACCOUNT_ID = 0
ACCESS_KEY = ""
SECRET_KEY = ""
PHONE = ""

# 初始化自动下单参数
ORDER_ID = '' # 下单回传单号
FORCE_BUY = False # 强制买入旗标
FORCE_SELL = False # 强制卖出旗标
LINE_MARKS = "-"*70 # Log记录的分隔符号
EX_RATE = 0.002  # 交易所手续费率
BUY_RATE = 1.0002  # 比市价多多少比例买入
SELL_RATE = 0.998  # 比市价少多少比例卖出
TRACE_MIN_RATE = 0 # 追踪最低价的反弹率
TRACE_MAX_RATE = 0 # 追踪最高价的回调率
TRACE_MIN_PRICE = 0 # 追踪买入的最低价数值
TRACE_MAX_PRICE = 0 # 追踪卖出的最高价数值
WAIT_SEND_SEC = 10 # 下单后等待几秒读取成交结果
MIN_TRADE_USDT = 5.2 # 下单到交易所的最低买卖金额
MAX_WAIT_BUY_SEC = 180 # 买单若迟迟未成交则等待几秒后撤消下单
MAX_WAIT_SELL_SEC = 300 # 卖单若迟迟未成交则等待几秒后撤消下单
ETH_USDT_NOW = 0 # 计算仓位值使用(=交易所ETH资产以USDT计算的值)
EX_USDT_VALUE = 0 # 计算仓位值使用(=交易所总资产以USDT计算的值)

# 火币API请求地址
MARKET_URL = "https://api.huobi.pro"
TRADE_URL = "https://api.huobi.pro"


########## 火币API开始 ####################################################################


# 火币API函数：'Timestamp': '2017-06-02T06:13:49'
def http_get_request(url, params, add_to_headers=None):
    headers = {
        "Content-type": "application/x-www-form-urlencoded",
        'User-Agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.71 Safari/537.36',
    }
    if add_to_headers:
        headers.update(add_to_headers)
    postdata = urllib.parse.urlencode(params)
    response = requests.get(url, postdata, headers=headers, timeout=10)
    try:

        if response.status_code == 200:
            return response.json()
        else:
            return
    except BaseException as e:
        print("httpGet failed, detail is:%s,%s" %(response.text,e))
        return


# 火币API函数
def http_post_request(url, params, add_to_headers=None):
    headers = {
        "Accept": "application/json",
        'Content-Type': 'application/json'
    }
    if add_to_headers:
        headers.update(add_to_headers)
    postdata = json.dumps(params)
    response = requests.post(url, postdata, headers=headers, timeout=10)
    try:

        if response.status_code == 200:
            return response.json()
        else:
            return
    except BaseException as e:
        print("httpPost failed, detail is:%s,%s" %(response.text,e))
        return


# 火币API函数
def api_key_get(params, request_path):
    method = 'GET'
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S')
    params.update({'AccessKeyId': ACCESS_KEY,
                   'SignatureMethod': 'HmacSHA256',
                   'SignatureVersion': '2',
                   'Timestamp': timestamp})

    host_url = TRADE_URL
    host_name = urllib.parse.urlparse(host_url).hostname
    host_name = host_name.lower()
    params['Signature'] = create_sign(params, method, host_name, request_path, SECRET_KEY)

    url = host_url + request_path
    return http_get_request(url, params)


# 火币API函数
def api_key_post(params, request_path):
    method = 'POST'
    timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S')
    params_to_sign = {'AccessKeyId': ACCESS_KEY,
                      'SignatureMethod': 'HmacSHA256',
                      'SignatureVersion': '2',
                      'Timestamp': timestamp}

    host_url = TRADE_URL
    host_name = urllib.parse.urlparse(host_url).hostname
    host_name = host_name.lower()
    params_to_sign['Signature'] = create_sign(params_to_sign, method, host_name, request_path, SECRET_KEY)
    url = host_url + request_path + '?' + urllib.parse.urlencode(params_to_sign)
    return http_post_request(url, params)


# 火币API函数
def create_sign(pParams, method, host_url, request_path, secret_key):
    sorted_params = sorted(pParams.items(), key=lambda d: d[0], reverse=False)
    encode_params = urllib.parse.urlencode(sorted_params)
    payload = [method, host_url, request_path, encode_params]
    payload = '\n'.join(payload)
    payload = payload.encode(encoding='UTF8')
    secret_key = secret_key.encode(encoding='UTF8')

    digest = hmac.new(secret_key, payload, digestmod=hashlib.sha256).digest()
    signature = base64.b64encode(digest)
    signature = signature.decode()
    return signature


# 火币API函数：获取KLine
def get_kline(symbol, period, size=150):
    """
    :param symbol
    :param period: 可选值：{1min, 5min, 15min, 30min, 60min, 1day, 1mon, 1week, 1year }
    :param size: 可选值： [1,2000]
    :return:
    """
    params = {'symbol': symbol,
              'period': period,
              'size': size}

    url = MARKET_URL + '/market/history/kline'
    return http_get_request(url, params)


# 火币API函数：获取market depth
def get_depth(symbol, type):
    """
    :param symbol
    :param type: 可选值：{ percent10, step0, step1, step2, step3, step4, step5 }
    :return:
    """
    params = {'symbol': symbol,
              'type': type}

    url = MARKET_URL + '/market/depth'
    return http_get_request(url, params)


# 火币API函数：获取trade detail
def get_trade(symbol):
    """
    :param symbol
    :return:
    """
    params = {'symbol': symbol}

    url = MARKET_URL + '/market/trade'
    return http_get_request(url, params)


# 火币API函数：Tickers detail
def get_tickers():
    """
    :return:
    """
    params = {}
    url = MARKET_URL + '/market/tickers'
    return http_get_request(url, params)


# 火币API函数：获取merge ticker
def get_ticker(symbol):
    """
    :param symbol:
    :return:
    """
    params = {'symbol': symbol}

    url = MARKET_URL + '/market/detail/merged'
    return http_get_request(url, params)


# 火币API函数：获取 Market Detail 24小时成交量数据
def get_detail(symbol):
    """
    :param symbol
    :return:
    """
    params = {'symbol': symbol}

    url = MARKET_URL + '/market/detail'
    return http_get_request(url, params)


# 火币API函数：获取支持的交易对
def get_symbols(long_polling=None):
    """

    """
    params = {}
    if long_polling:
        params['long-polling'] = long_polling
    path = '/v1/common/symbols'
    return api_key_get(params, path)


# 火币API函数：Get available currencies
def get_currencies():
    """
    :return:
    """
    params = {}
    url = MARKET_URL + '/v1/common/currencys'

    return http_get_request(url, params)


# 火币API函数：Get all the trading assets
def get_trading_assets():
    """
    :return:
    """
    params = {}
    url = MARKET_URL + '/v1/common/symbols'

    return http_get_request(url, params)


# 火币API函数：获取账号
def get_accounts():
    """
    :return:
    """
    path = "/v1/account/accounts"
    params = {}
    return api_key_get(params, path)


# 火币API函数：获取当前账户资产
def get_balance(acct_id=None):
    """
    :param acct_id
    :return:
    """

    if not acct_id:
        accounts = get_accounts()
        acct_id = accounts['data'][0]['id']

    url = "/v1/account/accounts/{0}/balance".format(acct_id)
    params = {"account-id": acct_id}
    return api_key_get(params, url)


# 火币API函数：创建并执行订单
def send_order(amount, source, symbol, _type, price=0):
    """
    :param amount:
    :param source: 如果使用借贷资产交易，请在下单接口,请求参数source中填写'margin-api'
    :param symbol:
    :param _type: 可选值 {buy-market：市价买, sell-market：市价卖, buy-limit：限价买, sell-limit：限价卖}
    :param price:
    :return:
    """
    try:
        accounts = get_accounts()
        acct_id = accounts['data'][0]['id']
    except BaseException as e:
        print('get acct_id error.%s' % e)
        acct_id = ACCOUNT_ID

    params = {"account-id": acct_id,
              "amount": amount,
              "symbol": symbol,
              "type": _type,
              "source": source}
    if price:
        params["price"] = price

    url = '/v1/order/orders/place'
    return api_key_post(params, url)


# 火币API函数：撤销订单
def cancel_order(order_id):
    """

    :param order_id:
    :return:
    """
    params = {}
    url = "/v1/order/orders/{0}/submitcancel".format(order_id)
    return api_key_post(params, url)


# 火币API函数：查询某个订单
def order_info(order_id):
    """

    :param order_id:
    :return:
    """
    params = {}
    url = "/v1/order/orders/{0}".format(order_id)
    return api_key_get(params, url)


# 火币API函数：查询某个订单的成交明细
def order_matchresults(order_id):
    """
    :param order_id:
    :return:
    """
    params = {}
    url = "/v1/order/orders/{0}/matchresults".format(order_id)
    return api_key_get(params, url)


# 火币API函数：查询当前委托、历史委托
def orders_list(symbol, states, types=None, start_date=None, end_date=None, _from=None, direct=None, size=None):
    """
    :param symbol:
    :param states: 可选值 {pre-submitted 准备提交, submitted 已提交, partial-filled 部分成交, partial-canceled 部分成交撤销, filled 完全成交, canceled 已撤销}
    :param types: 可选值 {buy-market：市价买, sell-market：市价卖, buy-limit：限价买, sell-limit：限价卖}
    :param start_date:
    :param end_date:
    :param _from:
    :param direct: 可选值{prev 向前，next 向后}
    :param size:
    :return:
    """
    params = {'symbol': symbol,
              'states': states}
    if types:
        params['types'] = types
    if start_date:
        params['start-date'] = start_date
    if end_date:
        params['end-date'] = end_date
    if _from:
        params['from'] = _from
    if direct:
        params['direct'] = direct
    if size:
        params['size'] = size
    url = '/v1/order/orders'
    return api_key_get(params, url)


# 火币API函数：查询当前成交、历史成交
def orders_matchresults(symbol, types=None, start_date=None, end_date=None, _from=None, direct=None, size=None):
    """
    :param symbol:
    :param types: 可选值 {buy-market：市价买, sell-market：市价卖, buy-limit：限价买, sell-limit：限价卖}
    :param start_date:
    :param end_date:
    :param _from:
    :param direct: 可选值{prev 向前，next 向后}
    :param size:
    :return:
    """
    params = {'symbol': symbol}
    if types:
        params['types'] = types
    if start_date:
        params['start-date'] = start_date
    if end_date:
        params['end-date'] = end_date
    if _from:
        params['from'] = _from
    if direct:
        params['direct'] = direct
    if size:
        params['size'] = size
    url = '/v1/order/matchresults'
    return api_key_get(params, url)


# 火币API函数：查询所有当前帐号下未成交订单
def open_orders(account_id, symbol, size=10, side=''):
    """
    :param symbol:
    :return:
    """
    params = {}
    url = "/v1/order/openOrders"
    if symbol:
        params['symbol'] = symbol
    if account_id:
        params['account-id'] = account_id
    if side:
        params['side'] = side
    if size:
        params['size'] = size
    return api_key_get(params, url)


# 火币API函数：批量取消符合条件的订单
def cancel_open_orders(account_id, symbol, side='', size=50):
    """
    :param symbol:
    :return:
    """
    params = {}
    url = "/v1/order/orders/batchCancelOpenOrders"
    if symbol:
        params['symbol'] = symbol
    if account_id:
        params['account-id'] = account_id
    if side:
        params['side'] = side
    if size:
        params['size'] = size
    return api_key_post(params, url)


# 火币API函数：申请提现虚拟币
def withdraw(address, amount, currency, fee=0, addr_tag=""):
    """
    :param address_id:
    :param amount:
    :param currency: ...(火币Pro支持的币种)
    :param fee:
    :param addr-tag:
    :return: {
              "status": "ok",
              "data": 700
            }
    """
    params = {'address': address,
              'amount': amount,
              "currency": currency,
              "fee": fee,
              "addr-tag": addr_tag}
    url = '/v1/dw/withdraw/api/create'
    return api_key_post(params, url)


# 申请取消提现虚拟币
def cancel_withdraw(address_id):
    """
    :param address_id:
    :return: {
              "status": "ok",
              "data": 700
            }
    """
    params = {}
    url = '/v1/dw/withdraw-virtual/{0}/cancel'.format(address_id)

    return api_key_post(params, url)



# 火币API函数：创建并执行借贷订单
def send_margin_order(amount, source, symbol, _type, price=0):
    """
    :param amount:
    :param source: 'margin-api'
    :param symbol:
    :param _type: 可选值 {buy-market：市价买, sell-market：市价卖, buy-limit：限价买, sell-limit：限价卖}
    :param price:
    :return:
    """
    try:
        accounts = get_accounts()
        acct_id = accounts['data'][0]['id']
    except BaseException as e:
        print('get acct_id error.%s' % e)
        acct_id = ACCOUNT_ID
    params = {"account-id": acct_id,
              "amount": amount,
              "symbol": symbol,
              "type": _type,
              "source": 'margin-api'}
    if price:
        params["price"] = price
    url = '/v1/order/orders/place'
    return api_key_post(params, url)


# 火币API函数：现货账户划入至借贷账户
def exchange_to_margin(symbol, currency, amount):
    """
    :param amount:
    :param currency:
    :param symbol:
    :return:
    """
    params = {"symbol": symbol,
              "currency": currency,
              "amount": amount}
    url = "/v1/dw/transfer-in/margin"
    return api_key_post(params, url)


# 火币API函数：借贷账户划出至现货账户
def margin_to_exchange(symbol, currency, amount):
    """
    :param amount:
    :param currency:
    :param symbol:
    :return:
    """
    params = {"symbol": symbol,
              "currency": currency,
              "amount": amount}
    url = "/v1/dw/transfer-out/margin"
    return api_key_post(params, url)


# 火币API函数：申请借贷
def get_margin(symbol, currency, amount):
    """
    :param amount:
    :param currency:
    :param symbol:
    :return:
    """
    params = {"symbol": symbol,
              "currency": currency,
              "amount": amount}
    url = "/v1/margin/orders"
    return api_key_post(params, url)


# 火币API函数：归还借贷
def repay_margin(order_id, amount):
    """
    :param order_id:
    :param amount:
    :return:
    """
    params = {"order-id": order_id,
              "amount": amount}
    url = "/v1/margin/orders/{0}/repay".format(order_id)
    return api_key_post(params, url)


# 火币API函数：借贷订单
def loan_orders(symbol, currency, start_date="", end_date="", start="", direct="", size=""):
    """
    :param symbol:
    :param currency:
    :param direct: prev 向前，next 向后
    :return:
    """
    params = {"symbol": symbol,
              "currency": currency}
    if start_date:
        params["start-date"] = start_date
    if end_date:
        params["end-date"] = end_date
    if start:
        params["from"] = start
    if direct and direct in ["prev", "next"]:
        params["direct"] = direct
    if size:
        params["size"] = size
    url = "/v1/margin/loan-orders"
    return api_key_get(params, url)


# 火币API函数：借贷账户详情,支持查询单个币种
def margin_balance(symbol):
    """
    :param symbol:
    :return:
    """
    params = {}
    url = "/v1/margin/accounts/balance"
    if symbol:
        params['symbol'] = symbol

    return api_key_get(params, url)


########## 火币API结束 ####################################################################

########## 自定义函数开始 ##################################################################


# 根据设定文档记录赋值火币账号ID及API密钥
def load_api_key():
    global ACCOUNT_ID
    global ACCESS_KEY
    global SECRET_KEY
    global PHONE
    with open(PARAMS, 'r') as f:
        arr = f.read().strip().split(' ')
        acc_id = arr[24]
        if acc_id == '170':
            ACCOUNT_ID = 6582761
            ACCESS_KEY = "0b259f2c-h6n2d4f5gh-4c7eb89b-845c8"
            SECRET_KEY = "086b3b20-4fc8db0d-21b8ad20-9bf64"
            PHONE = '17099311026'
        if acc_id == '135':
            ACCOUNT_ID = 6565695
            ACCESS_KEY = "c9c13a21-58449e8a-af5fdfd2-mn8ikls4qg"
            SECRET_KEY = "7aa1c5a1-0c7d2bdf-5dd73a82-34136"
            PHONE = '13581706025'
    print("********** Updated ACCOUNT_ID: %s PHONE: %s **********" % (ACCOUNT_ID, PHONE))


# 读取交易所账号简码
def get_acc_id():
    with open(PARAMS, 'r') as f:
        arr = f.read().strip().split(' ')
        return arr[24]


# 从SQLite数据库中读取数据
def select_db(sql):
    cursor = CONN.cursor()          # 该例程创建一个 cursor，将在 Python 数据库编程中用到。
    CONN.row_factory = sqlite3.Row  # 可访问列信息
    cursor.execute(sql)             # 该例程执行一个 SQL 语句
    rows = cursor.fetchall()        # 该例程获取查询结果集中所有（剩余）的行，返回一个列表。
    return rows                     # print(rows[0][2]) # 选择某一列数据


# 取得现在时间
def get_now():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


# 以数据库时间格式输出
def db_time(timestamp):
    if len(str(timestamp)) == 13:
        timestamp = timestamp//1000
    date_time = datetime.fromtimestamp(timestamp)
    return date_time.strftime("%Y-%m-%d %H:%M:%S")


# 以数据库时间格式输出
def to_t(input_time):
    return input_time.strftime("%Y-%m-%d %H:%M:%S")


# 取得交易列表开始读取时间
def get_time_line():
    with open(PARAMS, 'r') as fread:
        arr = fread.read().strip().split(' ')
        return arr[9]+' '+arr[10]


# 扣除交易所手续费率
def fees_rate():
    return 1 - EX_RATE


# 比市价多多少比例买入
def buy_price_rate():
    return BUY_RATE


# 比市价少多少比例卖出
def sell_price_rate():
    return SELL_RATE


# 取得以太坊当前报价
def get_price_now():
    global target_bi
    try:
        return float(get_kline('eth'+target_bi, '1min', 1)['data'][0]['close'])
    except:
        return 0


# 美元兑换人民币汇率
def usd2cny():
    data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'CNY'")
    return round(data[0][0], 4)


# 泰达币兑换美元汇率
def usdt2usd():
    data = select_db("SELECT exchange_rate FROM currencies WHERE code = 'USDT'")
    return round(1/data[0][0], 4)


# 泰达币兑换人民币汇率
def usdt2cny():
    return usd2cny()*usdt2usd()


# 执行下单操作
def place_new_order(price, amount, deal_type):
    global ORDER_ID
    global target_bi
    try:
        if TEST_ENV:
            ORDER_ID = 'T' + get_now()
            msg = "Test Send Order(%s) successfully! Send Data: Price=%s Amount=%s deal_type='%s'" % (ORDER_ID, price, amount, deal_type)
            return msg
        else:
            root = send_order(amount, "api", 'eth'+target_bi, deal_type, price)
            if root["status"] == "ok":
                ORDER_ID = root["data"]
                return "Send Order(%s) successfully" % root["data"]
            else:
                return root["err-msg"]
    except:
        return 'Some unknow error happened when Place New Order!'


# 撤消所有下单
def clear_orders():
    global target_bi
    try:
        root = cancel_open_orders(ACCOUNT_ID, 'eth'+target_bi)
        if root["status"] == "ok":
            return 'All open orders cleared'
    except:
        return 'Some error happened'


# 获得可交易的泰达币总数
def get_trade_usdt():
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'usdt' and item['type'] == 'trade':
                return float(item['balance'])
                break
    except:
        return '0'


# 获得可交易的以太坊总数
def get_trade_eth():
    try:
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'eth' and item['type'] == 'trade':
                return float(item['balance'])
                break
    except:
        return 0


# 获得交易所中所有以太坊的总数
def get_eth_amount_ex():
    try:
        amount = 0
        for item in get_balance(ACCOUNT_ID)['data']['list']:
            if item['currency'] == 'eth':
                amount += float(item['balance'])
        return amount
    except:
        return 0


# 获得数据库中以太坊的总数
def get_all_eth_amount():
    rows = select_db("SELECT sum(amount) FROM properties WHERE currency_id = 15")
    return rows[0][0]


# 储存定投参数的新值
def update_invest_params(index, new_value):
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[index] = str(new_value)
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return True
    except:
        return False


# 处理下单的主要流程
def place_order_process(test_price, price, amount, deal_type, ftext, time_line, u2c):
    global target_bi
    global buy_price_period
    global sell_price_period
    global buy_period_move
    # 如果不是测试单而是实际送单
    if test_price == 0:
        # 如果是卖单
        if deal_type.find('sell-limit') > -1:
            # 执行下单操作并显示下单成功的下单号或下单失败讯息
            if target_bi == 'usdt':
                msg_str = place_new_order("%.2f" % price, "%.4f" % amount, deal_type)
            if target_bi == 'btc':
                msg_str = place_new_order("%.6f" % price, "%.4f" % amount, deal_type)
            print(msg_str)
            ftext += msg_str+'\n'
            # 停留几秒以等待下单成交结果
            time.sleep(WAIT_SEND_SEC)
            # 获得可交易的USDT
            trade_usdt = float(get_trade_usdt())
            # 如果有剩余的USDT
            if trade_usdt > 0:
                # 显示目前USDT的剩余数量
                usdt_cny = trade_usdt*u2c
                msg_str = "USDT Trade Now: %.4f (%.2f CNY)" % (
                    trade_usdt, usdt_cny)
                print(msg_str)
                ftext += msg_str+'\n'
                # 获得可交易的ETH
                trade_eth = float(get_trade_eth())
                # 显示目前ETH的剩余数量与持仓水平
                msg_str = "ETH Now: %.8f Level: %.2f%%" % (trade_eth, eth_hold_level())
                print(msg_str)
                ftext += msg_str+'\n'
                # 更新火币交易所的资产现况并显示
                msg_str = "%i Huobi Assets Updated, Send Order Process Completed" % update_all_huobi_assets()
                print(msg_str)
                ftext += msg_str+'\n'
    # 返回欲显示的输出文字
    return ftext


# 清空所有未卖出的交易记录
def clear_deal_records():
    global acc_id
    sql = "DELETE FROM deal_records WHERE account = '%s' and auto_sell = 0" % acc_id
    CONN.execute(sql)
    CONN.commit()


# 更新设定文档中的'更新交易列表记录日期'与'更新交易列表记录时间'
def update_time_line(time_str):
    dt = time_str.split(' ')
    date_str = dt[0]
    time_str = dt[1]
    new_str = ''
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[9] = date_str
            arr[10] = time_str
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


# 更新设定文档中的'是否强制执行停损卖出'
def setup_force_sell():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[20] = '1'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


# 更新设定文档中的'是否强制执行买入操作'
def setup_force_buy():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[30] = '1'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


# 重置设定文档中的'是否强制执行停损卖出'
def reset_force_sell():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[20] = '0'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


# 重置设定文档中的'是否强制执行买入操作'
def reset_force_buy():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[30] = '0'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


# 重置设定文档中的'用于测试的以太坊价格'
def reset_test_price():
    try:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            arr[11] = '0'
            new_str = ' '.join(arr)
        with open(PARAMS, 'w+') as f:
            f.write(new_str)
        return 1
    except:
        return 0


# 计算以太坊目前的持有仓位
def eth_hold_level():
    global ori_eth
    amounts = {'eth': 0}
    for item in get_balance(ACCOUNT_ID)['data']['list']:
        for currency in ['eth']:
            if item['currency'] == currency:
                amounts[currency] += float(item['balance'])
    return amounts['eth']/ori_eth*100


# 显示下一次执行的时间
def print_next_exe_time(every_sec, ftext):
    next_hours = float(every_sec/3600)
    delta_next_hours = timedelta(hours=next_hours)
    next_exe_time = to_t(datetime.now() + delta_next_hours)
    msg_str = "Next Time: %s (%.2f M | %.2f H)" % (
        next_exe_time, every_sec/60, every_sec/3600)
    print(msg_str)
    ftext += msg_str+'\n'
    return ftext


# 检查是否超出设定的卖出额度，若超出则少卖一些
def check_sell_amount(sell_price, sell_amount, usdt_now, sell_max_usd):
    over_sell = False
    ut2u = usdt2usd()
    if (usdt_now + sell_price*sell_amount*fees_rate())*ut2u > sell_max_usd:
        sell_amount = round((sell_max_usd/ut2u-usdt_now)/sell_price/fees_rate(), 6)
        over_sell = True
    return sell_amount, over_sell


# 由下单回传值计算正确的获利值
def sell_profit_cny_from_order(order_id, cost_usdt_total):
    global WAIT_SEND_SEC        # 下单后等待几秒读取成交结果
    global MAX_WAIT_SELL_SEC    # 卖单若迟迟未成交则等待几秒后撤消下单
    profit_cny = 0              # 人民币损益值
    field_amount = 0            # 成交量
    field_fees = 0              # 成交手续费
    count = 0                   # 计算回圈执行次数以便判断是否超过等待时间
    # 一直循环直到成交为止
    while True:
        time.sleep(WAIT_SEND_SEC)
        count += 1
        data = order_info(order_id)['data']
        field_cash_amount = float(data['field-cash-amount'])
        field_fees = float(data['field-fees'])
        field_amount = float(data['field-amount'])
        # 如果成交量大于0表示已经成交
        if field_amount > 0:
            profit_usdt = field_cash_amount - field_fees - cost_usdt_total
            profit_cny = profit_usdt*usdt2cny()
            break
        # 卖单若迟迟未成交则等待几秒后撤消下单
        elif WAIT_SEND_SEC*count > MAX_WAIT_SELL_SEC:
            cancel_order(order_id)
            break
    return profit_cny, field_amount, field_fees


# 执行卖出下单的主要流程
def sell_process(test_price, price_now, ftext, time_line, u2c, sell_eq_cny):
    global ORDER_ID         # 下单回传编号
    global FORCE_SELL       # 是否执行强制卖出
    global acc_id           # 交易所识别账号
    global stop_sell_level  # 停止自动卖出的仓位值
    global target_bi
    # 卖出后仓位必须大于保留的仓位值
    if safe_after_sell(price_now):
        # 下单的卖出价比市价稍低以争取快速成交
        if target_bi == 'btc':
            sell_price = round(price_now*sell_price_rate(), 6)
        if target_bi == 'usdt':
            sell_price = round(price_now*sell_price_rate(), 2)
        # 卖出的总量
        sell_amount = cal_sell_amount(price_now)
        ftext = place_order_process(test_price, sell_price, sell_amount, \
        'sell-limit', ftext, time_line, u2c)
        # 如果只是测试，则测试完后退出
        if TEST_ENV:
            return ftext
        # 如果提交成功，将这些交易记录标示为已自动卖出并更新下单编号及已实现损益
        if test_price == 0 and len(ORDER_ID) > 0:
            # 获取现在时间
            time_now = get_now()
            # 检查是否已经成交
            count = 0  # 计算回圈执行次数以便判断是否超过等待时间
            # 一直循环直到成交为止或超出等待的秒数
            while True:
                # 如果回传值大于0表示已经成交
                n_dl_added = update_huobi_eth_deal_records(time_line)
                # 如果已成交则显示新增n笔交易记录并结束回圈
                if n_dl_added > 0:
                    msg_str = "%i Deal Records added" % n_dl_added
                    print(msg_str)
                    ftext += msg_str+'\n'
                    break
                time.sleep(WAIT_SEND_SEC)
                count += 1
                # 若买单迟迟未成交则等待几秒后撤消下单
                if WAIT_SEND_SEC*count > MAX_WAIT_SELL_SEC and len(ORDER_ID) > 0:
                  cancel_order(ORDER_ID)
                  msg_str = "Send Sell Order(%s) canceled!" % ORDER_ID
                  print(msg_str)
                  ftext += msg_str+'\n'
                  break
            # 重置交易单号
            ORDER_ID = ''
            # 更新记录time_line文档以避免更新交易记录时重头读取浪费时间
            update_time_line(time_now)
            msg_str = "Time Line Updated to: %s" % time_now
            print(msg_str)
            ftext += msg_str+'\n'
    return ftext


# 返回在指定区间内(几分钟内)以太坊价格的最大值与最小值
def get_min_max_price(buy_price_period, sell_price_period):
    global target_bi
    try:
        # 几分钟内以太坊价格的最小值
        arr = []
        if buy_price_period == 0:
            buy_price_period = 1
        root = get_huobi_price('eth'+target_bi, '1min', buy_price_period)
        for data in root["data"]:
            arr.append(data["low"])
        min_price = min(arr)
        # 几分钟内以太坊价格的最大值
        arr = []
        if sell_price_period == 0:
            sell_price_period = 1
        root = get_huobi_price('eth'+target_bi, '1min', sell_price_period)
        for data in root["data"]:
            arr.append(data["high"])
        max_price = max(arr)
        # 返回最小值与最大值
        return [min_price, max_price]
    except:
        # 如发生异常则返回0
        return [0, 0]


def btc_price_now():
    try:
        return float(get_kline('btcusdt', '1min', 1)['data'][0]['close'])
    except:
        return 0


# 求解买入几分钟内的最低价，返回现价、最低价、是否已达到触发条件，idx为触底反弹买进的索引值
def min_price_in(idx, size):
    global target_bi
    try:
        a = []
        if size == 0:
            size = 1
        root = get_huobi_price('eth'+target_bi, '1min', size)
        price_now = float(root['data'][0]['close'])
        for data in root["data"]:
            a.append(data["low"])
        a.reverse()
        if idx == 0 and int(price_now) <= int(min(a)):
            return [price_now, min(a), True]
        elif idx == 0 and price_now >= min(a):
            return [price_now, min(a), False]
        elif len(a)+idx == a.index(min(a)):
            return [price_now, min(a), True]
        else:
            return [price_now, min(a), False]
    except:
        return [0, 0, False]


# 求解卖出几分钟内的最高价，返回现价、最高价、是否已达到触发条件
def max_price_in(size):
    global target_bi
    try:
        a = []
        if size == 0:
            size = 1
        root = get_huobi_price('eth'+target_bi, '1min', size)
        price_now = float(root['data'][0]['close'])
        for data in root["data"]:
            a.append(data["high"])
        a.reverse()
        if price_now >= max(a):
            return [price_now, max(a), True]
        else:
            return [price_now, max(a), False]
    except:
        return [0, 0, False]


# 重置强制买卖
def reset_force_trade():
    global ORDER_ID
    global FORCE_BUY
    global FORCE_SELL
    global TRACE_MIN_PRICE
    global TRACE_MAX_PRICE
    ORDER_ID = ''
    FORCE_BUY = False
    FORCE_SELL = False
    TRACE_MIN_PRICE = 0
    TRACE_MAX_PRICE = 0


# 回传最近一笔卖单的间隔秒数，若无则回传一个很大的数字
def last_sell_interval():
    global acc_id
    global target_bi
    try:
        sql = ("SELECT updated_at FROM deal_records WHERE account = '%s' and deal_type = 'sell-limit' and symbol = 'eth%s' ORDER BY updated_at DESC LIMIT 1" % acc_id, target_bi)
        rows = select_db(sql)
        start_time = datetime.strptime(rows[0][0], "%Y-%m-%d %H:%M:%S")
        end_time = datetime.strptime(get_now(), "%Y-%m-%d %H:%M:%S")
        total_seconds = (end_time - start_time).total_seconds()
        return int(total_seconds)
    except:
        with open(PARAMS, 'r') as f:
            arr = f.read().strip().split(' ')
            start_time = datetime.strptime(arr[9]+' '+arr[10], "%Y-%m-%d %H:%M:%S")
            end_time = datetime.strptime(get_now(), "%Y-%m-%d %H:%M:%S")
            total_seconds = (end_time - start_time).total_seconds()
            return int(total_seconds)


# 预计要卖出的ETH总量
def cal_sell_amount(price_now):
    global sell_eq_cny
    global target_bi
    # 卖出后得BTC
    if target_bi == 'btc':
        return sell_eq_cny/usdt2cny()/btc_price_now()/price_now
    # 卖出后得USDT
    if target_bi == 'usdt':
        return sell_eq_cny/usdt2cny()/price_now


# 试算卖出后是否还维持在停止自动卖出的仓位值之上
def safe_after_sell(price_now):
    global ori_eth
    global stop_sell_level
    # 下一次预计要卖出的ETH总量
    sell_amount = cal_sell_amount(price_now)
    # 判断卖出后的ETH总量 > 原有ETH总量*停止自动卖出的仓位值 即可！
    ori_amount = get_eth_amount_ex() # 交易所目前剩余的ETH总量
    after_amount = ori_amount - sell_amount # 卖出后的ETH总量
    if after_amount > ori_eth*stop_sell_level/100.0:
        return True
    else:
        return False


# 显示讯息到控制台
def stdout_write( message ):
    sys.stdout.write("\r")
    sys.stdout.write(message)
    sys.stdout.write("\n")


# 破底之后持续追踪直到反弹超过指定的值才返回True允许买入
def reach_buy_price(price_now, min_price):
    global TRACE_MIN_PRICE
    # 初始化追踪买入的最低价然后返回False
    if TRACE_MIN_PRICE == 0:
        TRACE_MIN_PRICE = min_price
        return False
    # 如果现价比记录的值还低则更新记录的值后返回False
    elif min_price < TRACE_MIN_PRICE:
        TRACE_MIN_PRICE = min_price
        return False
    # 如果现价比记录的值还要高出TRACE_MIN_RATE的倍率则返回True
    elif price_now > TRACE_MIN_PRICE*TRACE_MIN_RATE:
        return True
    # 其他的状况一律返回False
    else:
        return False


# 破顶之后持续追踪直到回调超过指定的值才返回True允许卖出
def reach_sell_price(price_now, max_price):
    global TRACE_MAX_PRICE
    # 初始化追踪卖出的最高价然后返回False
    if TRACE_MAX_PRICE == 0:
        TRACE_MAX_PRICE = max_price
        return False
    # 如果现价比记录的值还高则更新记录的值后返回False
    elif max_price > TRACE_MAX_PRICE:
        TRACE_MAX_PRICE = max_price
        return False
    # 如果现价比记录的值还要低于TRACE_MAX_RATE的倍率则返回True
    elif price_now < TRACE_MAX_PRICE*TRACE_MAX_RATE:
        return True
    # 其他的状况一律返回False
    else:
        return False


# 價格越低購買數量成倍數級增加
def cal_invest_usdt( price ):
    global top_price
    global bottom_price
    global reduce_step
    global min_usdt
    global max_usdt
    b = 1  # 倍数从1开始(1,2,4,8...)
    invest_usdt = 0
    for n in range(top_price-reduce_step, bottom_price-1, reduce_step*-1):
        if price >= n and price < n+reduce_step:
            invest_usdt = min_usdt*b+(n+reduce_step-price)*(min_usdt/reduce_step)*b
            if invest_usdt >= max_usdt:
                return max_usdt
            else:
                return invest_usdt
        if price >= top_price:
            invest_usdt = min_usdt
            return invest_usdt
        elif price <= bottom_price+reduce_step*0.5:
            invest_usdt = max_usdt
            return invest_usdt
        b *= 2
    return invest_usdt


# 执行自动下单的主程序
def exe_auto_invest(bottom_price, factor, max_buy_level, min_usdt, max_usdt, time_line, test_price, profit_goal, max_sell_count, min_sec_rate, max_sec_rate):
    # 引用全域变数
    global ORDER_ID
    global FORCE_BUY
    global FORCE_SELL
    global LOG_FILE
    global LINE_MARKS
    global target_bi
    global min_price
    global max_price
    global sell_price_period
    global every_sec_for_sell
    global acc_id
    global stop_sell_level
    global reduce_step
    global top_price
    global force_sell_price
    global sell_eq_cny
    # 写入Log文档
    with open(LOG_FILE, 'a') as fobj:
        # Log分隔符
        sline = LINE_MARKS
        ftext = sline+'\n'
        # 获得现价与汇率值
        price_now = get_price_now()
        u2c = usdt2cny()
        if force_sell_price > 0:
            if target_bi == 'btc':
                msg_str = "%s:%.6f Invest Every %i Sec When Price Over %.6f" % (get_now(), price_now, every_sec_for_sell, force_sell_price)
            if target_bi == 'usdt':
                msg_str = "%s:%.2f Invest Every %i Sec When Price Over %.2f" % (get_now(), price_now, every_sec_for_sell, force_sell_price)
        else:
            if target_bi == 'btc':
                msg_str = "%s:%.6f Invest Every %i Sec When Price Over %i Minutes Max Price" % (get_now(), price_now, every_sec_for_sell, sell_price_period)
            if target_bi == 'usdt':
                msg_str = "%s:%.2f Invest Every %i Sec When Price Over %i Minutes Max Price" % (get_now(), price_now, every_sec_for_sell, sell_price_period)
        if price_now > 0:
            ftext += msg_str+'\n'
            # 必须大于等于最小卖出值才会送单
            if sell_eq_cny >= MIN_TRADE_USDT*u2c and FORCE_SELL == True:
                ftext = sell_process(0, price_now, ftext, time_line, \
                        u2c, sell_eq_cny)
                fobj.write(ftext)
                return every_sec_for_sell
            else:
                fobj.write(ftext)
                return every_sec_for_sell
        else:
            # 无法读取现价，等待3秒后重新执行一遍
            return 3


########## 自定义函数结束 ##################################################################


# 脚本主函数
if __name__ == '__main__':
    # 载入火币账号ID及API密钥
    load_api_key()
    # 卖出后仓位必须大于保留的仓位值警告讯息旗标
    level_warn_already_show = False
    # 无限循环直到按下Ctrl+C终止
    while True:
        # 正常运行的情况
        try:
            # 打开参数设定文档
            with open(PARAMS, 'r') as fread:
                # 将设定文档参数读入内存
                params_str = fread.read().strip()
                every_sec, target_bi, bottom_price, ori_eth, factor, max_buy_level, target_amount, min_usdt, max_usdt, deal_date, deal_time, test_price, profit_goal, max_sell_count, min_sec_rate, max_sec_rate, detect_sec, buy_price_period, sell_price_period, buy_period_move, force_to_sell, min_price_index, every_sec_for_sell, sell_max_cny, acc_id, deal_cost, deal_amount, force_sell_price, acc_real_profit, stop_sell_level, force_to_buy, buy_period_max, is_lower_ave, reduce_step, top_price, trace_min_rate, trace_max_rate, top_price_minutes, sell_period_min, sell_eq_cny = params_str.split(' ')
                # 将设定文档参数根据适当的型别初始化
                every_sec = int(every_sec)
                bottom_price = int(bottom_price)
                ori_eth = float(ori_eth)
                factor = float(factor)
                max_buy_level = float(max_buy_level)
                target_amount = float(target_amount)
                min_usdt = float(min_usdt)
                max_usdt = float(max_usdt)
                time_line = deal_date+' '+deal_time
                test_price = float(test_price)
                profit_goal = float(profit_goal)
                max_sell_count = int(max_sell_count)
                min_sec_rate = float(min_sec_rate)
                max_sec_rate = float(max_sec_rate)
                detect_sec = int(detect_sec)
                buy_price_period = int(buy_price_period)
                sell_price_period = int(sell_price_period)
                buy_period_move = float(buy_period_move)
                force_to_sell = int(force_to_sell)
                min_price_index = int(min_price_index)
                every_sec_for_sell = int(every_sec_for_sell)
                sell_max_cny = int(sell_max_cny)
                force_sell_price = float(force_sell_price)
                stop_sell_level = float(stop_sell_level)
                force_to_buy = int(force_to_buy)
                # 买入最低价时的最高价
                buy_period_max = float(buy_period_max)
                # 成本均价是否越买越低
                is_lower_ave = int(is_lower_ave)
                # 每隔几点购买额度翻倍
                reduce_step = int(reduce_step)
                # 额度翻倍的最大购买价
                top_price = int(top_price)
                # 买入最低价时的反弹率
                TRACE_MIN_RATE = float(trace_min_rate)
                # 卖出最高价时的回调率
                TRACE_MAX_RATE = float(trace_max_rate)
                # 额度翻倍的最大购买价根据几分钟平均价调整
                top_price_minutes = int(top_price_minutes)
                # 卖出最高价时的最低价
                sell_period_min = float(sell_period_min)
                # 每笔卖出值多少人民币
                sell_eq_cny = float(sell_eq_cny)
                # 获得在几分钟内以太坊价格的最大值与最小值
                min_price, max_price = get_min_max_price(buy_price_period, sell_price_period)
                # 是否执行强制买入
                if force_to_buy > 0:
                    FORCE_BUY = True
                # 是否执行强制卖出
                if force_to_sell > 0:
                    FORCE_SELL = True
                # 执行自动下单的主程序
                code = exe_auto_invest(bottom_price, factor, max_buy_level, min_usdt, max_usdt, time_line, test_price, profit_goal, max_sell_count, min_sec_rate, max_sec_rate)
                # 清零与重载：测试单、强制卖出、强制买卖、火币账号
                reset_test_price()
                reset_force_sell()
                reset_force_buy()
                reset_force_trade()
                load_api_key()
                # 如果返回0则结束程序
                if code == 0:
                    break
                else:
                    # 每隔几秒侦测参数变化并显示可否买卖讯息
                    for remaining in range(int(code), 0, -1):
                        sys.stdout.write("\r")
                        sys.stdout.write("********** %i seconds for next operate **********" % remaining)
                        sys.stdout.flush()
                        time.sleep(1)
                        if remaining % detect_sec == 0:
                            # 如果间隔秒数发生变化则跳出回圈重新执行主程序
                            with open(PARAMS, 'r') as f:
                                line_str = f.read().strip()
                                if line_str[0:5] != params_str[0:5]:
                                    break
                            # 将需要打印观察的值写入LOG
                            with open(LOG_FILE, 'a') as fa:
                                ###############################################################
                                # 现价、最高价、是否已达到卖价
                                price_now, max_price, over_max_price = max_price_in(sell_price_period)
                                # 是否达到可卖出的时间
                                over_sell_time = last_sell_interval() > every_sec_for_sell
                                # 是否在可卖出的价格之上
                                is_above_price = price_now > 0 and force_sell_price > 0 and price_now >= force_sell_price
                                # 是否达到分钟内的最高价
                                reach_high_price = sell_price_period > 0 and over_max_price
                                # 如果保留的仓位值为0或者卖出后大于保留的仓位值
                                if stop_sell_level == 0 or safe_after_sell(price_now):
                                    is_safe_after_sell = True
                                else:
                                    is_safe_after_sell = False
                                if is_safe_after_sell == True and level_warn_already_show == True:
                                    msg_str = "%s:%.6f 卖出后仓位>=%i%%，程序可以自动卖出了！" % (get_now(), price_now, stop_sell_level)
                                    fa.write(LINE_MARKS+'\n'+msg_str+'\n')
                                    level_warn_already_show = False
                                if is_safe_after_sell == False and level_warn_already_show == False:
                                    msg_str = "%s:%.6f 卖出后仓位小于%i%%，程序无法自动卖出！" % (get_now(), price_now, stop_sell_level)
                                    fa.write(LINE_MARKS+'\n'+msg_str+'\n')
                                    level_warn_already_show = True
                                #################################################################
                                # 达到卖出的条件则执行卖出
                                # 卖出几分钟内的最高价时是否不低于所设定的最低价
                                if sell_period_min > 0:
                                    if price_now >= sell_period_min:
                                        over_min_sell_price = True
                                    else:
                                        over_min_sell_price = False
                                else:
                                    over_min_sell_price = True
                                # 如果破顶后，检查是否回调到想卖出的价位
                                if over_min_sell_price and \
                                    (reach_high_price or TRACE_MAX_PRICE > 0):
                                    is_sell_price = reach_sell_price(price_now, max_price)
                                else:
                                    is_sell_price = False
                                if price_now > 0 and max_price > 0 and sell_price_period > 0:
                                    if TEST_ENV:
                                        env = '[T]'
                                    else:
                                        env = ''
                                    if target_bi == 'btc':
                                        msg_str = "%s%s:%.6f %imax:%.6f t&b_%.6f:%s over_time:%s over_min_price:%s level_after_sell:%s" % (env, get_now(), price_now, sell_price_period, max_price,  TRACE_MAX_PRICE*TRACE_MAX_RATE, is_sell_price, over_sell_time, over_min_sell_price, is_safe_after_sell)
                                    if target_bi == 'usdt':
                                        msg_str = "%s%s:%.2f %imax:%.2f t&b_%.2f:%s over_time:%s over_min_price:%s level_after_sell:%s" % (env, get_now(), price_now, sell_price_period, max_price,  TRACE_MAX_PRICE*TRACE_MAX_RATE, is_sell_price, over_sell_time, over_min_sell_price, is_safe_after_sell)
                                    stdout_write(msg_str)
                                if is_safe_after_sell and over_sell_time and TRACE_MAX_PRICE > 0:
                                    fa.write(msg_str+'\n')
                                # 卖出条件：仓位、时间、获利、[可卖价格之上|卖出分钟内的最高价且到达卖出价]
                                if is_safe_after_sell and over_sell_time and (is_above_price or is_sell_price):
                                    FORCE_SELL = True
                                    break
                    stdout_write(" "*30)
        except:
            print("Some Unexpected Error or Connect Timeout, Please Wait %i Sec or Break Program to Check!!" % WAIT_SEND_SEC)
            time.sleep(WAIT_SEND_SEC)
