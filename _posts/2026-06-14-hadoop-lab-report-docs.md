---
title: 新手友好 | Hadoop报告插件教程
date: 2026-06-14 23:00:00 +0800
categories: [湛科作业克星]
tags: [Hadoop, 效率, 新手友好, Claude Code, skill]
---

> ### 更新适配 Hadoop 实训内容 <a href="/assets/files/update-claude-skill.ps1" download> **点击运行脚本更新**</a>
> [脚本闪退?无法打开?](/posts/go-claude-code-QA/#脚本闪退-无法打开)
> 
> 使用时请备份虚拟机 
> [如何备份?](/posts/hadoop-lab-report-docs/#注意事项)
{: .prompt-tip }

## 这是啥东东？

> **我想干的，就是把时间还给大学生。**

抄教程、敲命令、等结果、截图，再一张张塞进 Word 里排版……一次 Hadoop 实验跑下来，真正动脑的没几步，剩下大半个下午全耗在 **CtrlCV** 上。

这个skill会把这些重复环节交给 AI —— 只需**说一句话**，它就自动帮你：

> **读教程 → 在你的虚拟机上执行 → 截图 → 生成 Word 实验报告**

然后你就能直接交作业，把省下来的时间还给自己 —— 去学真正想学的、做想做的，或者干脆好好歇会儿 ：）

### [啥是SKILL？](#skill解释)

> **！！ 工具本身无好坏**：请遵守课程规定酌情使用，使用中出现的任何问题本工具概不负责。

---

## 一、前期准备

**1. 安装并配置 Claude Code**

还没有安装？看这篇 → [新手友好：三步配置 Claude Code 与 DeepSeek](/posts/go-claude-code)

**2. 下载 SKILL 技能安装脚本**（该脚本是我写的，没有病毒：））



**3. 运行脚本**

在脚本文件上**右键 → 使用 终端（或 PowerShell） 运行**。

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/ps0.png){: .w-75 }

> 注：使用较新电脑的同学们右键点击 **使用 终端 打开**。
{: .prompt-tip }

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/ps1.png){: .w-75 }

[脚本闪退?无法打开?](/posts/go-claude-code-QA/#脚本闪退-无法打开)

当命令窗消失之后，就代表安装好了。可以在 `C:\Users\你的用户名\.claude\skills` 里查看安装结果。

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/ps2.png){: .w-75 }

**4. 确认实验虚拟机已开机**，且能用 **FinalShell** 连上。

**5. 新建一个空文件夹作为工作目录**，并把**老师发的 Hadoop 实验材料文件夹**和**报告模板**都拷进这个工作目录。

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude1.png){: .w-75 }

> 下图就是老师发的实验材料文件夹。
{: .prompt-tip }

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude2.png){: .w-75 }

这一步做好之后，应该是下面这样：

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude3.png){: .w-75 }

**6. 在文件夹内打开 Claude Code**（AI 会把报告写在这里）

右键这个文件夹，选择**在终端打开**：

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude4.png){: .w-75 }

然后输入：

```powershell
claude
```

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude5.png){: .w-75 }

确认：

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude6.png){: .w-75 }

将会弹出 Claude 的对话框。如图，你可以输入 `/skill` 确认插件安装成功：

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude7.png){: .w-75 }

## 二、一句话开跑（以 P5 / hadoop-e05 为例，Codex 同理）

在 Claude Code 的对话框里**直接说**：

```
用 hadoop-lab-report skill 帮我跑 P5 实验并续写报告，教程地址：
https://heisun.xyz/docs/hadoop-e/hadoop-e05

最终报告放在工作目录根目录，命名为 …-P5-完成.docx
```

就这一句。接下来它会自动：弹窗收集你的姓名学号（只存在本地）→ 读教程 → 连接虚拟机 → 逐步执行 → 截图 → 排版 → 生成报告。

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude8.png){: .w-75 }

**你只管去忙别的，回来报告就躺在工作目录里 —— 交完作业，省下的这段时间归你 ：）**

>[API 粗错了?](/posts/go-claude-code-QA/#api-错误)
{: .prompt-warning }

>[AI老让我确认太烦人?如何完全自动做做实验?](/posts/understanding-claude-code-permissions/#完全权限-dangerously-skip-permissions)
{: .prompt-tip }

> 换实验同理：把 `hadoop-e05` 换成 `hadoop-e01`～`hadoop-e07`（对应 P1–P7）即可，身份和连接信息不用重新填。

## 注意事项!!

> ⚠️ **跑之前务必：给虚拟机拍快照！**
{: .prompt-warning }

![备份](/assets/img/2026-06-14-hadoop-lab-report-docs/bk.png){: .w-75 }

**先给 NodeA、B、C 三台虚拟机拍快照（备份当前状态）**。万一执行出错，可以随时回滚，不至于把环境弄坏。

### 卡住了也没关系

中途如果出问题，程序会弹出提醒并引导你处理；处理完**接着跑**就行，不用从头重来。

---

## 杂

### SKILL解释

> 不太准确的解释：可以理解成 AI 的技能包，可以让大模型学会一些技能。比如说连接虚拟机，读老师的教程……

---

[`skill/hadoop-lab-report/ 仓库地址`](https://github.com/Lucky-Ro/zjkju_Copilot/blob/main/skill/hadoop-lab-report)