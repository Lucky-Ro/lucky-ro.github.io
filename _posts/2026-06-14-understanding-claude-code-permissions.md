---
title: AI弹窗太烦人? 认识ClaudeCode权限
date: 2026-06-14 20:00:00 +0800
categories: [新手友好]
tags: [效率, 新手友好, Claude Code, skill]
---

## 弹窗太烦?先搞懂权限模式

Claude Code 默认是「**胆小**」的:每次它想**做点什么**,都要停下来问你「能不能干」。这就是那些烦人弹窗的来源。而**权限模式**就是用来控制"它到底多久问你一次"。

按 **`Shift+Tab`** 就能在几个模式之间循环切换,当前模式会显示在输入框下面的状态栏里。

![入框下面的状态栏](/assets/img/2026-06-14-go-claude-code-QA/claude1.png){: .w-75 }

### Shift+Tab 循环里的三个常用模式

`Shift+Tab` 默认在这三个之间转:**default → acceptEdits → plan**。

- **default -- (Ask before edits)**
  只读模式。凡是改文件、跑命令、联网都要弹窗让你点同意。新手、改重要东西时就用它。

- **acceptEdits(自动接受编辑,状态栏显示 `⏵⏵ accept edits on`)**
  改文件不再问了,顺带 `mkdir / touch / mv / cp / rm` 这类常见文件操作命令(**仅限工作目录内**)也放行。但**其它 bash 命令照样会问**。

- **plan(计划模式)**
  先出一份**行动计划**:你看完批准了它才动手。

![计划模式例子](/assets/img/2026-06-14-go-claude-code-QA/plan-mode.png){: .w-75 }

- **auto mode(自动模式)**
  更激进的一档:几乎全自动执行,仅有某些危险操作会被拦

### 「完全权限」 --dangerously-skip-permissions

> 我们的试验是在虚拟机环境,如果做好备份,理论上可以使用该模式,效率最高
{: .prompt-info }


这个模式**跳过所有权限检查**，Claude 想干啥就干啥、完全不问。
开启方式（默认不在 Shift+Tab 循环里）：

```bash
# 启动时加 CLI 参数
claude --dangerously-skip-permissions
```

> 想临时把 bypass 加进 Shift+Tab 循环、又不想一上来就启用,可以用 `claude --allow-dangerously-skip-permissions`,它只把这一档加进循环,不会立刻激活。
{: .prompt-tip }

注意几点:

- 第一次用会弹**一次性警告**要你确认,之后就再也不拦了。
- 在 Linux/macOS 上,用 **root / sudo** 身份会直接拒绝启动(除非它检测到自己在沙箱里)。
- 名字里的 **dangerously** 是 Claude 故意起的,就是当成警示牌 —— 如果你在自己主机上裸跑,理论上它真能把你 `rm -rf ~/` 然后回车。
