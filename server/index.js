const express = require('express');
const axios = require('axios');
const cron = require('node-cron');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

// 数据库连接
const db = new sqlite3.Database(path.join(__dirname, 'lottery.db'));

// 初始化数据库
db.serialize(() => {
    db.run(`
    CREATE TABLE IF NOT EXISTS ball_info (
      id INTEGER PRIMARY KEY,
      qh TEXT NOT NULL,
      kj_time TEXT,
      zhou TEXT,
      red_balls TEXT,
      blue_ball INTEGER
    )
  `);
});

// 获取双色球数据
async function fetchLotteryData(page = 1) {
    try {
        const callback = `jQuery${Date.now()}`;
        const url = 'https://jc.zhcw.com/port/client_json.php';
        const params = {
            callback,
            transactionType: '10001001',
            lotteryId: '1',
            issueCount: '30',
            type: '0',
            pageNum: page.toString(),
            pageSize: '30',
            tt: (Date.now() / 1000).toString(),
            _: Date.now().toString()
        };

        const headers = {
            'Accept': '*/*',
            'Accept-Language': 'zh-CN,zh;q=0.9,vi;q=0.8,en;q=0.7',
            'Connection': 'keep-alive',
            'Referer': 'https://www.zhcw.com/',
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36'
        };

        const response = await axios.get(url, { params, headers });
        const jsonStr = response.data.substring(callback.length + 1, response.data.length - 1);
        const data = JSON.parse(jsonStr);

        if (data.errorCode === '0' && data.value) {
            return data.value;
        }
        return [];
    } catch (error) {
        console.error('Error fetching lottery data:', error);
        return [];
    }
}

// 更新数据库
async function updateDatabase() {
    console.log('Starting database update...');
    let page = 1;
    let hasMore = true;
    let latestIssue = null;

    // 获取数据库中最新的期号
    const latest = await new Promise((resolve, reject) => {
        db.get('SELECT MAX(qh) as latest FROM ball_info', (err, row) => {
            if (err) reject(err);
            else resolve(row?.latest || '0');
        });
    });

    while (hasMore) {
        const data = await fetchLotteryData(page);
        if (!data.length) break;

        for (const record of data) {
            if (!latestIssue) latestIssue = record.issue;
            if (parseInt(record.issue) <= parseInt(latest)) {
                hasMore = false;
                break;
            }

            await new Promise((resolve, reject) => {
                db.run(
                    'INSERT OR REPLACE INTO ball_info (id, qh, kj_time, zhou, red_balls, blue_ball) VALUES (?, ?, ?, ?, ?, ?)',
                    [
                        parseInt(record.issue),
                        record.issue,
                        record.openTime,
                        record.week || '',
                        record.frontNumber,
                        parseInt(record.backNumber)
                    ],
                    err => {
                        if (err) reject(err);
                        else resolve();
                    }
                );
            });
        }

        page++;
        await new Promise(resolve => setTimeout(resolve, 1000)); // 延迟1秒
    }

    console.log('Database update completed');
}

// API路由
app.get('/lottery/latest', (req, res) => {
    db.get('SELECT * FROM ball_info ORDER BY id DESC LIMIT 1', (err, row) => {
        if (err) {
            res.status(500).json({ error: err.message });
        } else {
            res.json({
                issue: row.qh,
                openTime: row.kj_time,
                week: row.zhou,
                redBalls: row.red_balls.split(',').map(Number),
                blueBall: row.blue_ball
            });
        }
    });
});

app.get('/lottery/range', (req, res) => {
    const { startQh, endQh } = req.query;
    if (!startQh || !endQh) {
        return res.status(400).json({ error: 'Missing parameters' });
    }

    db.all(
        'SELECT * FROM ball_info WHERE id >= ? AND id <= ? ORDER BY id',
        [parseInt(startQh), parseInt(endQh)],
        (err, rows) => {
            if (err) {
                res.status(500).json({ error: err.message });
            } else {
                res.json(rows.map(row => ({
                    issue: row.qh,
                    openTime: row.kj_time,
                    week: row.zhou,
                    redBalls: row.red_balls.split(',').map(Number),
                    blueBall: row.blue_ball
                })));
            }
        }
    );
});

// 定时更新数据（每天凌晨2点和晚上9点）
cron.schedule('0 2,21 * * *', () => {
    updateDatabase();
});

// 启动时更新一次数据
updateDatabase();

// 启动服务器
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
}); 