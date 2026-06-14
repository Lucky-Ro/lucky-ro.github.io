---
title: 新手友好 | Hadoop报告插件教程（hadoop-lab-report skill）
date: 2026-06-14 12:00:00 +0800
categories: [湛科作业克星]
tags: [Hadoop, 新手友好, Claude Code, skill]
---

## 啥玩意？

把一篇 [黑隼](https://heisun.xyz/docs/hadoop-e/hadoop-e02/) 的 Hadoop 实验教程链接丢给这个 skill，它就会自动帮你：

> **读教程 → 在你的虚拟机上执行 → 截图 → 生成 Word 实验报告**

然后你就能直接交作业啦 ：）

### [啥是SKILL？](https://lucky-ro.github.io/posts/hadoop-lab-report-docs/#skill解释) 


> **！！ 工具本身无好坏**：请遵守课程规定酌情使用，使用中出现的任何问题本工具概不负责。

---

## 一、前期准备

1. 安装并配置 Claude Code。

**还不会配置？** [新手友好：三步配置 Claude Code 与 DeepSeek](https://lucky-ro.github.io/posts/go-claude-code)

2. 下载SKILL技能安装脚本（该脚本是我写的，没有病毒：））

<a href="/assets/files/update-claude-skill.ps1" download> **点击下载 ：）**(install-claude-code.ps1)</a>

3. 运行脚本

 - 在脚本文件上**右键 → 使用 终端（或PowerShell） 运行**。
 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/ps0.png)

 - 注：使用较新电脑的同学们右键点击 **使用 终端 打开**
 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/ps1.png)

当命令窗消失之后，就代表安装好了。

 - 我们可以在C:\Users\你的用户名\.claude\skill 中查看。
 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/ps2.png)
{: .prompt-tip }

3. 确认实验虚拟机已开机，且能用 **FinalShell** 连上。

4. 新建一个空文件夹作为工作目录，并把**老师发的 Hadoop 实验材料文件夹**和**报告模板**都拷进这个工作目录。

 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude1.png)

 - 老师发的实验材料文件夹
 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude2.png)
{: .prompt-tip }

 - 这一步做好应该是这样
 ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude3.png)

5.并在**文件夹内**打开 Claude Code （AI 会把报告写在这里）。

 - 右键这个文件夹，选择**在终端打开**
 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude4.png)

 - 输入:

```powershell
claude
```

 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude5.png)

 - 确认
 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude6.png)

 - 将会弹出Claude的对话框。如图，你可以输入 /skill 确认插件安装成功。
 - ![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude7.png)


## 二、一句话开跑（以 P5 / hadoop-e05 为例，Codex 同理）

在 Claude Code 的对话框里**直接说**：

```
用 hadoop-lab-report skill 帮我跑 P5 实验并续写报告，教程地址：
https://heisun.xyz/docs/hadoop-e/hadoop-e05

最终报告放在工作目录根目录，命名为 …-P5-完成.docx
```

就这一句。接下来它会自动：弹窗收集你的姓名学号（只存在本地）→ 读教程 → 连接虚拟机 → 逐步执行 → 截图 → 排版 → 生成报告。

![运行脚本](/assets/img/2026-06-14-hadoop-lab-report-docs/claude8.png)

快去交作业吧 ：）

> 换实验同理：把 `hadoop-e05` 换成 `hadoop-e01`～`hadoop-e07`（对应 P1–P7）即可，身份和连接信息不用重新填。

## 注意事项!!

### **跑之前务必：给虚拟机拍快照！**
{: .prompt-warning }

![备份](/assets/img/2026-06-14-hadoop-lab-report-docs/bk.png)

**先给 NodeA、B、C 三台虚拟机拍快照（备份当前状态）**。万一执行出错，可以随时回滚，不至于把环境弄坏。


### 卡住了也没关系

中途如果出问题，程序会弹出提醒并引导你处理；处理完**接着跑**就行，不用从头重来。

---
## 杂

### SKILL解释
> 不太准确的解释：可以理解成AI的技能包，可以让大模型学会一些技能。比如说连接虚拟机，读老师的教程...

---

 [`skill/hadoop-lab-report/ 仓库地址`](https://github.com/Lucky-Ro/zjkju_Copilot/blob/main/skill/hadoop-lab-report)