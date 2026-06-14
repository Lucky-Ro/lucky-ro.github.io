---
title: 进阶 | 手动安装 Claude Code 并配置 DeepSeek 大模型
date: 2026-06-14 16:04:00 +0800
categories: [进阶]
tags: [进阶, AI, ClaudeCode]
pin: false
---

让别人无脑运行一个脚本,心里多少会犯嘀咕。所以脚本到底做了什么呢？

1. **放行脚本运行权限** —— 自动把执行策略设为 `RemoteSigned`,省去你手动操作。
2. **安装 Node.js** —— Claude Code 依赖它,脚本会用 `winget` 自动装好(已经装过会自动跳过)。
3. **切换国内镜像源** —— 这样无需科学上网环境就可以体验ClaudeCode啦。
4. **安装 Claude Code 本体** —— 执行 `npm install -g @anthropic-ai/claude-code`。
5. **写入 DeepSeek 配置** —— 在 `~/.claude/settings.json` 里填好 DeepSeek 的接口地址、你的 Key 和模型名,这样 Claude Code 一启动就会自动走 DeepSeek。

(脚本会自动帮你写好，这里仅作为演示):

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "sk-换成你自己的-DeepSeek-Key",
    "ANTHROPIC_MODEL": "deepseek-chat"
  }
}
```

> 模型名(`ANTHROPIC_MODEL`)请以 DeepSeek 平台当前提供的为准。脚本里已经填好了,你一般不用改。
{: .prompt-info }