FName = 'money'
OName = 'money2'

def db_path(local=False):
    if local == True:
        return "/Users/lin/sites/"+FName+"/db/development.sqlite3"
    else:
        return "/home/jie/sites/"+FName+"/db/development.sqlite3"

def test_db_path(local=False):
    if local == True:
        return "/Users/lin/sites/"+FName+"/db/development_test.sqlite3"
    else:
        return "/home/jie/sites/"+FName+"/db/development_test.sqlite3"

def get_params_path():
    return "/home/jie/sites/"+FName+"/py/auto_invest_params.txt"
    
def get_system_params_path():
    return "/home/jie/sites/"+FName+"/config/system_params.txt"

def get_sell_btc_setup():
    return "/home/jie/sites/"+FName+"/py/auto_sell_btc_params.txt"

def get_sell_eth_setup():
    return "/home/jie/sites/"+FName+"/py/auto_sell_eth_params.txt"

def get_other_params_path(local=False):
    if local == True:
        return "/Users/lin/sites/"+OName+"/py/auto_invest_params_local.txt"
    else:
        return "/home/jie/sites/"+OName+"/py/auto_invest_params.txt"
