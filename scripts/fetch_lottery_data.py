import requests
import json
import sqlite3
from datetime import datetime
import time
import os

def get_database_path():
    # 获取Android应用的数据库路径
    base_path = os.path.expanduser('~/code/AndroidProjects/lucky_lucky')
    db_path = os.path.join(base_path, 'ssq_database.db')
    return db_path

def init_database():
    db_path = get_database_path()
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 创建表（如果不存在）
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS ball_info (
        id INTEGER PRIMARY KEY,
        qh TEXT NOT NULL,
        kj_time TEXT,
        zhou TEXT,
        hong_one INTEGER,
        hong_two INTEGER,
        hong_three INTEGER,
        hong_four INTEGER,
        hong_five INTEGER,
        hong_six INTEGER,
        lan_ball INTEGER
    )
    ''')
    
    conn.commit()
    return conn, cursor

def get_latest_qh_from_db(cursor):
    cursor.execute('SELECT MAX(qh) FROM ball_info')
    result = cursor.fetchone()
    return result[0] if result and result[0] else '0'

def fetch_lottery_data(page=1):
    url = 'https://jc.zhcw.com/port/client_json.php'
    callback = f'jQuery{int(time.time() * 1000)}'
    
    params = {
        'callback': callback,
        'transactionType': '10001001',
        'lotteryId': '1',
        'issueCount': '30',
        'type': '0',
        'pageNum': str(page),
        'pageSize': '30',
        'tt': str(time.time()),
        '_': str(int(time.time() * 1000))
    }
    
    headers = {
        'Accept': '*/*',
        'Accept-Language': 'zh-CN,zh;q=0.9,vi;q=0.8,en;q=0.7',
        'Connection': 'keep-alive',
        'Referer': 'https://www.zhcw.com/',
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36'
    }
    
    try:
        response = requests.get(url, params=params, headers=headers)
        # 提取JSON数据
        json_str = response.text[response.text.index('(') + 1:response.text.rindex(')')]
        data = json.loads(json_str)
        
        if data['errorCode'] == '0' and data['value']:
            return data['value']
        return []
    except Exception as e:
        print(f'Error fetching data: {e}')
        return []

def insert_ball_data(cursor, conn, ball_data):
    try:
        cursor.execute('''
        INSERT OR REPLACE INTO ball_info 
        (id, qh, kj_time, zhou, hong_one, hong_two, hong_three, hong_four, hong_five, hong_six, lan_ball)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', ball_data)
        conn.commit()
        return True
    except Exception as e:
        print(f'Error inserting data: {e}')
        return False

def main():
    conn, cursor = init_database()
    latest_qh = get_latest_qh_from_db(cursor)
    print(f'Database latest issue: {latest_qh}')
    
    page = 1
    new_records = 0
    
    while True:
        print(f'Fetching page {page}...')
        lottery_data = fetch_lottery_data(page)
        
        if not lottery_data:
            break
            
        for record in lottery_data:
            if int(record['issue']) <= int(latest_qh):
                print('Reached existing data, stopping...')
                break
                
            red_balls = record['frontNumber'].split(',')
            ball_data = (
                int(record['issue']),  # id
                record['issue'],       # qh
                record['openTime'],    # kj_time
                record.get('week', ''),# zhou
                int(red_balls[0]),     # hong_one
                int(red_balls[1]),     # hong_two
                int(red_balls[2]),     # hong_three
                int(red_balls[3]),     # hong_four
                int(red_balls[4]),     # hong_five
                int(red_balls[5]),     # hong_six
                int(record['backNumber']) # lan_ball
            )
            
            if insert_ball_data(cursor, conn, ball_data):
                new_records += 1
                print(f'Inserted issue {record["issue"]}')
        
        if int(lottery_data[-1]['issue']) <= int(latest_qh):
            break
            
        page += 1
        time.sleep(1)  # 添加延迟，避免请求过快
    
    print(f'Total new records inserted: {new_records}')
    conn.close()

if __name__ == '__main__':
    main() 