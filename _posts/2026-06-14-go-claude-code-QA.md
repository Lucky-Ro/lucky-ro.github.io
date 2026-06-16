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

## 脚本闪退? 无法打开?

![没有数字签名?](/assets/img/2026-06-14-go-claude-code-QA/1.png){: .w-75 }

右键脚本,选择**属性**

![右键脚本,选择属性](/assets/img/2026-06-14-go-claude-code-QA/2.png){: .w-75 }

找到**安全**,勾上**解除锁定**

![安全项 -> 解除锁定](/assets/img/2026-06-14-go-claude-code-QA/3.png){: .w-75 }

## API 错误?

**Q：报错 `402 Insufficient Balance`（余额不足）？**

![碰上402错误?](/assets/img/2026-06-14-go-claude-code-QA/API-Err-402.png){: .w-75 }

>充钱即可;登录 DeepSeek 平台充值.

**Q：报错 `429 Too Many Requests` / 请求过于频繁？**
>触发了限流，不是你配置错了。等几秒再发；如果是脚本批量调用，把并发降下来。低档套餐的速率限制更严，频繁撞墙就考虑升档。

**Q：报错 model not found / 模型不存在？**
>检查 `settings.json` 里的模型名是不是写对了。接 DeepSeek 的 Anthropic 兼容端点时要用它支持的模型名（如 `deepseek-chat`），别原样保留 `claude-` 开头的默认模型名。


## 常见问题

**Q：提示 `claude` 不是内部或外部命令?**
>八成是新装完没重开终端。关掉所有 PowerShell 窗口,重新打开再试。

**Q：报错 API key not found / 鉴权失败?**
>检查 `C:\Users\你的用户名\.claude\settings.json` 里的 Key 是不是贴完整了、有没有多空格,以及确认它是 DeepSeek 的 Key(以 `sk-` 开头),不是别处的。

**Q：连接超时?**
>看一下网络是否正常,以及 `ANTHROPIC_BASE_URL` 是不是 `https://api.deepseek.com/anthropic`,别漏了末尾的 `/anthropic`。