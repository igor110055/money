# -*- coding: utf-8 -*-
import sys
import time
import json
import sqlite3
from HuobiServices import *
import datetime


def update_huobi_deal_records(time_line='2019-12-14 12:00:00'):
    count = 0
    t = datetime.datetime.today()
    today = datetime.date(t.year, t.month, t.day)
    t = time_line.split(' ')[0].split('-')
    line_day = datetime.date(int(t[0]), int(t[1]), int(t[2]))
    diff_days = (today-line_day).days+1

    n = 1
    date_array = []
    this_day = line_day - datetime.timedelta(days=1)
    while n <= diff_days:
        next_day = this_day + datetime.timedelta(days=1)
        date_array.append((this_day.strftime("%Y-%m-%d"), next_day.strftime("%Y-%m-%d")))
        n += 1
        this_day = next_day

    with open(PARAMS, 'r') as f:
        arr = f.read().strip().split(' ')
        acc_id = arr[24]
        for start_date, end_date in date_array:
            for deal_type in ['buy-limit', 'buy-market']:
                for data in orders_matchresults('btcusdt', deal_type, start_date, end_date)['data']:
                    time.sleep(0.2)
                    data_id = int(data['id'])
                    sql = "SELECT id FROM deal_records WHERE data_id = %i" % data_id
                    result = CONN.execute(sql)
                    if not len(result.fetchall()) == 1:
                        price = float(data['price'])
                        amount = float(data['filled-amount'])
                        fees = float(data['filled-fees'])
                        earn_limit = float((fees*price+price*amount*0.002)*7.1)
                        created_at = db_time(data['created-at'])
                        if created_at > time_line:
                            sql = "INSERT INTO deal_records (account, data_id, symbol, deal_type, price, amount, fees, \
                                    earn_limit, loss_limit, created_at, updated_at, auto_sell) VALUES ('%s', %i, 'btcusdt', '%s', %f, %f, %f, %.4f, 0, '%s', '%s', 0)" \
                                    % (acc_id, data_id, deal_type, price, amount, fees, earn_limit, created_at, created_at)
                            CONN.execute(sql)
                            CONN.commit()
                            count += 1
    return count


def update_huobi_btc_deal_records(time_line='2019-12-14 12:00:00'):
    count = 0
    t = datetime.datetime.today()
    today = datetime.date(t.year, t.month, t.day)
    t = time_line.split(' ')[0].split('-')
    line_day = datetime.date(int(t[0]), int(t[1]), int(t[2]))
    diff_days = (today-line_day).days+1

    n = 1
    date_array = []
    this_day = line_day - datetime.timedelta(days=1)
    while n <= diff_days:
        next_day = this_day + datetime.timedelta(days=1)
        date_array.append((this_day.strftime("%Y-%m-%d"), next_day.strftime("%Y-%m-%d")))
        n += 1
        this_day = next_day

    with open(ETH_PARAMS, 'r') as f:
        arr = f.read().strip().split(' ')
        acc_id = arr[24]
        btc_symbol = 'btcusdt'
        for start_date, end_date in date_array:
            for deal_type in ['sell-limit', 'sell-market']:
                for data in orders_matchresults(btc_symbol, deal_type, start_date, end_date)['data']:
                    time.sleep(0.2)
                    data_id = int(data['id'])
                    sql = "SELECT id FROM deal_records WHERE data_id = %i" % data_id
                    result = CONN.execute(sql)
                    if not len(result.fetchall()) == 1:
                        price = float(data['price'])
                        amount = float(data['filled-amount'])
                        fees = float(data['filled-fees'])
                        created_at = db_time(data['created-at'])
                        if created_at > time_line:
                            sql = "INSERT INTO deal_records (account, data_id, symbol, deal_type, price, amount, fees, \
                                    earn_limit, loss_limit, created_at, updated_at, auto_sell) VALUES ('%s', %i, '%s', '%s', %f, %f, %f, 0, 0, '%s', '%s', 0)" \
                                    % (acc_id, data_id, btc_symbol, deal_type, price, amount, fees, created_at, created_at)
                            CONN.execute(sql)
                            CONN.commit()
                            count += 1
    return count

def update_huobi_eth_deal_records(time_line='2019-12-14 12:00:00'):
    count = 0
    t = datetime.datetime.today()
    today = datetime.date(t.year, t.month, t.day)
    t = time_line.split(' ')[0].split('-')
    line_day = datetime.date(int(t[0]), int(t[1]), int(t[2]))
    diff_days = (today-line_day).days+1

    n = 1
    date_array = []
    this_day = line_day - datetime.timedelta(days=1)
    while n <= diff_days:
        next_day = this_day + datetime.timedelta(days=1)
        date_array.append((this_day.strftime("%Y-%m-%d"), next_day.strftime("%Y-%m-%d")))
        n += 1
        this_day = next_day

    with open(ETH_PARAMS, 'r') as f:
        arr = f.read().strip().split(' ')
        acc_id = arr[24]
        eth_symbol = 'eth'+arr[1]
        for start_date, end_date in date_array:
            for deal_type in ['sell-limit', 'sell-market']:
                for data in orders_matchresults(eth_symbol, deal_type, start_date, end_date)['data']:
                    time.sleep(0.2)
                    data_id = int(data['id'])
                    sql = "SELECT id FROM deal_records WHERE data_id = %i" % data_id
                    result = CONN.execute(sql)
                    if not len(result.fetchall()) == 1:
                        price = float(data['price'])
                        amount = float(data['filled-amount'])
                        fees = float(data['filled-fees'])
                        created_at = db_time(data['created-at'])
                        if created_at > time_line:
                            sql = "INSERT INTO deal_records (account, data_id, symbol, deal_type, price, amount, fees, \
                                    earn_limit, loss_limit, created_at, updated_at, auto_sell) VALUES ('%s', %i, '%s', '%s', %f, %f, %f, 0, 0, '%s', '%s', 0)" \
                                    % (acc_id, data_id, eth_symbol, deal_type, price, amount, fees, created_at, created_at)
                            CONN.execute(sql)
                            CONN.commit()
                            count += 1
    return count

def update_huobi_doge_deal_records(time_line='2019-12-14 12:00:00'):
    count = 0
    t = datetime.datetime.today()
    today = datetime.date(t.year, t.month, t.day)
    t = time_line.split(' ')[0].split('-')
    line_day = datetime.date(int(t[0]), int(t[1]), int(t[2]))
    diff_days = (today-line_day).days+1

    n = 1
    date_array = []
    this_day = line_day - datetime.timedelta(days=1)
    while n <= diff_days:
        next_day = this_day + datetime.timedelta(days=1)
        date_array.append((this_day.strftime("%Y-%m-%d"), next_day.strftime("%Y-%m-%d")))
        n += 1
        this_day = next_day

    with open(DOGE_PARAMS, 'r') as f:
        arr = f.read().strip().split(' ')
        acc_id = arr[24]
        doge_symbol = 'dogebtc'
        for start_date, end_date in date_array:
            for deal_type in ['buy-limit', 'buy-market']:
                for data in orders_matchresults(doge_symbol, deal_type, start_date, end_date)['data']:
                    time.sleep(0.2)
                    data_id = int(data['id'])
                    sql = "SELECT id FROM deal_records WHERE data_id = %i" % data_id
                    result = CONN.execute(sql)
                    if not len(result.fetchall()) == 1:
                        price = float(data['price'])
                        amount = float(data['filled-amount'])
                        fees = float(data['filled-fees'])
                        created_at = db_time(data['created-at'])
                        if created_at > time_line:
                            sql = "INSERT INTO deal_records (account, data_id, symbol, deal_type, price, amount, fees, \
                                    earn_limit, loss_limit, created_at, updated_at) VALUES ('%s', %i, '%s', '%s', %f, %f, %f, 0, 0, '%s', '%s')" \
                                    % (acc_id, data_id, doge_symbol, deal_type, price, amount, fees, created_at, created_at)
                            CONN.execute(sql)
                            CONN.commit()
                            count += 1
    return count


if __name__ == '__main__':
    try:
        new_deal_records = update_huobi_deal_records(get_time_line())
        if new_deal_records > 0:
            print("新增%i笔BTC交易记录！" % new_deal_records, sys.stdout)
        else:
            print("无新增BTC交易！", sys.stdout)
        new_btc_deal_records = update_huobi_btc_deal_records(get_btc_time_line())
        if new_btc_deal_records > 0:
            print("新增%i笔BTC卖出记录！" % new_btc_deal_records, sys.stdout)
        else:
            print("无新增BTC卖出交易！", sys.stdout)
        new_eth_deal_records = update_huobi_eth_deal_records(get_eth_time_line())
        if new_eth_deal_records > 0:
            print("新增%i笔ETH卖出记录！" % new_eth_deal_records, sys.stdout)
        else:
            print("无新增ETH卖出交易！", sys.stdout)
        new_doge_deal_records = update_huobi_doge_deal_records(get_doge_time_line())
        if new_doge_deal_records > 0:
            print("新增%i笔DOGE交易记录！" % new_doge_deal_records, sys.stdout)
        else:
            print("无新增DOGE交易记录！", sys.stdout)
    except:
        print("网路不顺畅或代码有误，请稍后再试！", sys.stdout)
