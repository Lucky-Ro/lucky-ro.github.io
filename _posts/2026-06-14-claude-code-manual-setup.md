---
title: 进阶 | Claude Code 的更多安装方式
date: 2026-06-14 16:02:00 +0800
categories: [进阶]
tags: [墙内, AI, ClaudeCode, deepseek]
pin: false
---

你也可以在 **终端** 里运行脚本:
>
> ```powershell
> irm https://lucky-ro.github.io/assets/files/install-claude-code.ps1 | iex
> ```

{: .prompt-info }

---

**知道你小子爱折腾,想一步步自己来,可以照这个走  :P**

**1. 安装 Node.js**

```powershell
winget install OpenJS.NodeJS.LTS
```

**2. 安装 Claude Code**

国内网络先切镜像再装:

```powershell
npm config set registry https://registry.npmmirror.com
npm install -g @anthropic-ai/claude-code
```

**3. 配置 DeepSeek**

新建文件 `C:\Users\你的用户名\.claude\settings.json`,
加入以下代码块
```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-换成你自己的-DeepSeek-Key",
    "ANTHROPIC_MODEL": "deepseek-chat"
  }
}
```
把 Key 换成你自己的。


## 验证是否成功

新开一个 PowerShell 窗口,输入:

```powershell
claude --version
```

能看到版本号,说明 Claude Code 装好了。接着输入 `claude` 启动它,问它一句话试试:

```powershell
claude "用一句话介绍一下你自己"
```

它能正常回答,就代表 DeepSeek 也接通了,可以开始用了。

---

[碰到问题？](https://lucky-ro.github.io/posts/go-claude-code-QA)