---
title: 新手友好 | 一键安装 Claude Code 并配置 DeepSeek 大模型
date: 2026-06-14 16:00:00 +0800
categories: [新手友好]
tags: [新手友好, 墙内, AI, ClaudeCode, deepseek]
pin: false
---

> 这篇是写给完全没接触过 **ClaudeCode**，**命令行** 的同学的。跟着走完,你的 Windows 电脑上就能跑起 Claude Code,而且用的是 DeepSeek 的模型——便宜、好用
{: .prompt-tip }

## 啥玩意？

[Claude Code](https://github.com/anthropics/claude-code) 是一个在终端里和 AI 对话写代码的工具:它能帮你生成、改写、调试、解释代码,效率很高。

它默认走的是官方接口,但好消息是**DeepSeek 正好提供了这样的接口**,于是我们就能用 DeepSeek 的模型来驱动 Claude Code,既省钱,国内网络也顺畅。

我把安装 + 配置过程打包成了**一键脚本**:双击运行,剩下的它全帮你搞定。下面先说说怎么用

## 准备工作

开始之前,你只需要准备两样东西:

**1. 一台电脑。** 不需要任何编程基础。

**2. 一个 DeepSeek API Key。** 这是脚本配置时要用到的「钥匙」
>（你需要向里面充些钱，应该不会花很多...几块钱左右）
>

获取方式:

- 打开 [DeepSeek 开放平台](https://platform.deepseek.com/),注册并登录;
- 进入「API Keys」页面,点击创建,复制保存好生成的密钥(以 `sk-` 开头)。

> API Key 相当于你账户的密码。请妥善保管,**不要外发、不要写进截图**。
{: .prompt-warning }

## 一键安装(推荐)

### 第一步:下载脚本（该脚本是我写的，没有病毒：））

<a href="/assets/files/install-claude-code.ps1" download> 点击下载 ：）(install-claude-code.ps1)</a>

下载后,把它放到一个好找的位置,比如桌面。

### 第二步:运行脚本

在脚本文件上**右键 → 使用 终端（或PowerShell） 运行**。

![运行脚本](/assets/img/2026-06-14-go-claude-code/ps1.png)
> 注：使用较新电脑的同学们右键点击 **使用 终端 打开**


![运行脚本](/assets/img/2026-06-14-go-claude-code/ps2.png)

这时候会弹出Node安装对话框，一直点next即可。
![运行脚本](/assets/img/2026-06-14-go-claude-code/node1.png)

![运行脚本](/assets/img/2026-06-14-go-claude-code/node2.png)

![运行脚本](/assets/img/2026-06-14-go-claude-code/node3.png)

回到我们的脚本，等待安装。直到弹出输入API的提示，可以进入下一步

### 第三步:填入你的 API Key

脚本运行过程中会提示你粘贴刚才准备好的 DeepSeek API Key,贴进去回车就行。看到「安装完成」的提示,就可以进入下一步。
直到弹出输入 **API KEY** ，将我们刚刚创建的deepseek复制的那一大串粘贴进去（Ctrl + V）

![运行脚本](/assets/img/2026-06-14-go-claude-code/ps3.png)

![运行脚本](/assets/img/2026-06-14-go-claude-code/ps4.png)

再次等待，直到退出。

#### 此时 Claude Code 已经安装**完毕**

### 验证是否成功

新开一个 PowerShell 窗口,
>(`键盘上Ctrl旁Win徽标键 + X` → 选「终端」或「PowerShell」)
>
输入:

```powershell
claude
```
![运行脚本](/assets/img/2026-06-14-go-claude-code/ps5.png)

回车保持默认即可。
接下来就进入欢迎界面了。

![运行脚本](/assets/img/2026-06-14-go-claude-code/ps6.png)

随便问一个问题
它能正常回答,就代表 DeepSeek 也接通了,可以开始用了。

---

## 大功告成

到这里,你已经拥有了一个跑在 DeepSeek 上的终端 AI 编程助手。

接下来就大胆用起来吧——让它帮你写脚本、改 bug、解释看不懂的代码

慢慢你会发现命令行其实没那么可怕。

---
>有问题欢迎写信交流 ：）
>->  Email: lmyum@protonmail.com
{: .prompt-info }

[想尝试更多安装方式?](https://lucky-ro.github.io/posts/claude-code-manual-setup/)

[好奇这个脚本到底做了什么?](https://lucky-ro.github.io/posts/go-claude-code-script-analysis/)

[碰到问题了？](https://lucky-ro.github.io/posts/go-claude-code-QA/)