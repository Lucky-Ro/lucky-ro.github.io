---
title: Claude Code安装常见问题
date: 2026-06-14 16:06:00 +0800
categories: [新手友好]
tags: [新手友好, 墙内, AI, ClaudeCode, deepseek]
pin: false
---

>有问题欢迎私信写信交流 ：）
>->  Email: lmyum@protonmail.com
{: .prompt-info }

## 常见问题

**Q：提示 `claude` 不是内部或外部命令?**
八成是新装完没重开终端。关掉所有 PowerShell 窗口,重新打开再试。

**Q：报错 API key not found / 鉴权失败?**
检查 `C:\Users\你的用户名\.claude\settings.json` 里的 Key 是不是贴完整了、有没有多空格,以及确认它是 DeepSeek 的 Key(以 `sk-` 开头),不是别处的。

**Q：连接超时?**
看一下网络是否正常,以及 `ANTHROPIC_BASE_URL` 是不是 `https://api.deepseek.com/anthropic`,别漏了末尾的 `/anthropic`。