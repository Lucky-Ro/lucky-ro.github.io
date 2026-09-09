---
title: GitHub CLI 配置教程
date: 2026-09-10 00:00:00 +0800
categories: [GitHub]
tags: [GitHub, Git, CLI, SSH]
---

> GitHub CLI（`gh`）是 GitHub 官方的命令行工具，装好之后，你可以在终端里直接管理仓库、创建 PR、查看 Issue，不用反复切回浏览器。这篇带你在 Mac 和 Windows 上走一遍完整配置。
{: .prompt-tip }

---

## 第一步：安装 GitHub CLI

### Mac

打开终端，用 Homebrew 安装：

```bash
brew install gh
```

> 还没装 Homebrew ？
>
> ```bash
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```
{: .prompt-info }

### Windows

打开 PowerShell，用 winget 安装：

```powershell
winget install GitHub.cli
```

装完后**关掉 终端 再重新打开**，source 一下环境变量

### 验证安装

```bash
gh --version
```

能看到版本号说明装好了。

---

## 第二步：准备 SSH 密钥

用它来认证 Git 操作，不用输密码。

### 检查是否已有密钥

Mac 终端或 PowerShell 里都可以查：

**Mac：**

```bash
ls -la ~/.ssh
```

**Windows：**

```powershell
Get-ChildItem C:\Users\你的用户名\.ssh
```

如果能看到成对的文件，比如 `id_ed25519` 和 `id_ed25519.pub`（没有 `.pub` 后缀的是私钥，有 `.pub` 的是公钥），说明你已经有密钥了，可以跳到下面的"确认密钥是否已绑定 GitHub"。

### 没有密钥？生成一个

如果 `.ssh` 目录是空的或者根本不存在，生成一对新密钥。Mac 和 Windows 命令一样：

```bash
ssh-keygen -t ed25519 -C "Your_mail@example.com"
```

它会问你几个问题：

- **Enter file in which to save the key** → 直接回车，用默认路径
- **Enter passphrase** → 可以设一个密码（每次用密钥时要输），也可以直接回车留空

> `-t ed25519` 指定密钥类型为 Ed25519，目前最推荐的算法，比 RSA 更短更安全。`-C` 后面的邮箱只是一个备注标签，方便你认出这把钥匙是谁的。
{: .prompt-info }

生成完之后，你的 `.ssh` 目录里就会多出两个文件：

| 文件             | 说明                        |
| ---------------- | --------------------------- |
| `id_ed25519`     | 私钥，**不要泄露**          |
| `id_ed25519.pub` | 公钥，可以放心上传到 GitHub |

### 确认密钥是否已绑定 GitHub

查看公钥指纹：

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

> Windows 上路径写全：`ssh-keygen -lf C:\Users\你的用户名\.ssh\id_ed25519.pub`
{: .prompt-info }

然后打开 <https://github.com/settings/keys>，对比页面上列出的指纹。如果能匹配上，说明这把钥匙已经绑定过了，登录时 gh 会自动识别，不会重复上传。

如果没匹配上或者列表是空的也没关系——下一步登录时 gh 会帮你上传。

---

## 第三步：登录 GitHub CLI

在终端里运行：

```bash
gh auth login
```

按提示一步步走：

**Where do you use GitHub?** → `GitHub.com`

**What is your preferred protocol for Git operations?** → `SSH`

**Upload your SSH public key to your GitHub account?** → 选你的 `.pub` 公钥文件

**Title for your SSH key** → 随便起个名，比如 `MacBook`、`YOGA`、`Windows-PC`，方便以后在 GitHub 密钥列表里认出是哪台机器的。

**How would you like to authenticate GitHub CLI?** → 选 `Login with a web browser`

> 建议选浏览器登录。它会给你一个一次性验证码，跳转浏览器粘贴、点授权就完事了。另一条路（Paste an authentication token）需要你手动去 GitHub 网页生成 Personal Access Token，步骤多且容易搞混。
{: .prompt-warning }

选了浏览器登录后，终端会显示一串一次性代码，同时自动打开浏览器。在网页上粘贴这串代码，点击授权，回到终端看到 `Logged in as 你的用户名` 就大功告成了。

---

## 第四步：验证

```bash
gh auth status
```

看到类似这样的输出就说明一切正常：

```
github.com
  ✓ Logged in to github.com account YourUsername
  ✓ Git operations for github.com configured to use ssh protocol.
  ✓ Token: gho_****
```

---

## 几个容易踩的坑

**SSH 密钥选错了。** 如果你 `.ssh` 目录下有多把钥匙（比如 `id_rsa`、`id_ed25519`、`id_ed25519_github`），登录时要选跟 GitHub 绑定的那一把。不确定就去 <https://github.com/settings/keys> 对指纹。

**选了 Token 登录。** 如果不小心走了 Paste an authentication token 这条路，需要去 <https://github.com/settings/tokens> 手动生成一个 Personal Access Token（勾选 `repo`、`read:org`、`admin:public_key` 权限），复制粘贴进去。不如浏览器登录省心，建议 `Ctrl+C` 退出重来选浏览器。

**Windows 终端粘贴看不到字。** 这是正常的——密码类输入在终端里不会显示字符，直接粘贴完回车就行。

---

更多用法可以看 [官方文档](https://cli.github.com/manual/)。
