---
title: 用 GitHub Releases 共享大文件
date: 2026-09-10 00:00:00 +0800
categories: [GitHub]
tags: [GitHub, Git, CLI, Releases]
---

> 网盘限速、强制客户端？GitHub Releases 是一个被严重低估的文件共享方案 —— 这篇记录用 `gh` 命令行从创建到上传。
{: .prompt-tip }

> 本文默认你已经装好了 GitHub CLI 并登录。还没装？先看 [GitHub CLI 配置教程](/posts/github-cli-setup/)。
{: .prompt-info }

---

## 先搞清楚：Releases 和仓库是两套存储

这是最关键的认知。你可能觉得「大文件塞进 git 不现实」——没错，但 Release 附件根本不走 git。

|                  | 仓库里的文件 | Release 附件     |
| ---------------- | ------------ | ---------------- |
| 走 git 吗        | 是，进历史   | 否，独立对象存储 |
| clone 会拉下来吗 | 会           | 不会             |
| 单文件上限       | 100 MB       | **2 GiB**        |
| 占用仓库体积     | 是           | 否               |

所以你在仓库里挂 20 GB 的 Release 附件，`git clone` 依然秒级完成，仓库看起来还是干干净净几百 KB。它本质上是 GitHub 白送你的一块对象存储。

---

## 第一步：建一个专门放文件的仓库

技术上用任何仓库都行，但建议和博客仓库分开——职责清晰，以后迁移互不影响。

```bash
gh repo create resources --public --add-readme
```

> `--public` 必须加，私有仓库的 Release 附件需要 token 才能下载，别人点链接会 404。`--add-readme` 创建一个初始提交，否则打不了 tag，后面创建 Release 会失败。
{: .prompt-warning }

也可以在网页上建：右上角 `+` → **New repository** → 名字填 `resources` → 选 **Public** → 勾选 **Add a README file**。

---

## 第二步：创建 Release 并上传文件

### 一条命令搞定

```bash
gh release create v1 --repo 你的用户名/resources --title "资料包" --notes "第一批文件" 文件1.zip 文件2.zip
```

拆开看每一部分：

| 部分                   | 含义                               |
| ---------------------- | ---------------------------------- |
| `gh release create`    | 子命令：创建一个新的 Release       |
| `v1`                   | **tag 名**，第一个位置参数，必填   |
| `--repo 用户名/仓库名` | 指定操作哪个仓库                   |
| `--title "..."`        | Release 页面上显示的标题           |
| `--notes "..."`        | 说明文字，支持 Markdown            |
| 末尾的文件列表         | 要上传的附件，空格分隔，可以写多个 |

> **tag 名不是标题。** 执行后 GitHub 会在仓库里创建一个叫 `v1` 的 git 标签。名字随便取——`v1`、`env-pack`、`2026-09` 都行，但同一个 tag 只能挂一个 Release，重复会报错。
{: .prompt-info }

### 实战示例

假设你的用户名是 `octocat`，仓库叫 `my-share`，桌面上有两个 zip 要传：

**Mac：**

```bash
cd ~/Desktop
gh release create v1 \
  --repo octocat/my-share \
  --title "项目资料包" \
  --notes "包含源码和文档" \
  --draft \
  source-code.zip \
  docs.zip
```

**Windows（PowerShell）：**

```powershell
cd $env:USERPROFILE\Desktop
gh release create v1 --repo octocat/my-share --title "项目资料包" --notes "包含源码和文档" --draft source-code.zip docs.zip
```

> Windows 上不能用 `\` 续行。要么全部写成一行，要么用 PowerShell 的反引号 `` ` `` 续行。最省事的办法就是一行写完。
{: .prompt-warning }

> 加了 `--draft` 会建成草稿，确认没问题再发布，避免半成品被人看到。
{: .prompt-info }

### `--repo` 什么时候可以省略

如果你的终端当前目录在这个仓库的本地克隆里，`gh` 会自动识别，不用写 `--repo`。但对于「只用来存文件、不写代码」的仓库，没必要克隆，老实写 `--repo` 更直接。

---

## 第三步：追加、覆盖、删除文件

### 往已有的 Release 追加文件

```bash
gh release upload v1 新文件.zip --repo 你的用户名/resources
```

`create` 是新建 Release，`upload` 是往已存在的 Release 里加文件。第一次用 `create`，之后补文件用 `upload`。

### 覆盖同名文件

```bash
gh release upload v1 新文件.zip --clobber --repo 你的用户名/resources
```

不加 `--clobber` 时，如果 Release 里已有同名文件，命令会报错拒绝。加了它就是「覆盖旧的」。因为下载链接是按文件名拼的，覆盖后链接不用改。

### 删除单个附件

```bash
gh release delete-asset v1 文件名.zip --repo 你的用户名/resources --yes
```

### 删除整个 Release

```bash
gh release delete v1 --repo 你的用户名/resources --yes
```

> 删的如果是已发布的 Release（不是草稿），默认只删 Release 本身，git tag 会留在仓库里。要连 tag 一起清掉，加 `--cleanup-tag`：
>
> ```bash
> gh release delete v1 --repo 你的用户名/resources --cleanup-tag --yes
> ```
{: .prompt-info }

---

## 第四步：发布草稿

### 命令行发布

```bash
gh release edit v1 --repo 你的用户名/resources --draft=false
```

如果同时想更新说明文字，加 `--notes`：

```bash
gh release edit v1 --repo 你的用户名/resources --draft=false --notes "更新后的说明"
```

> 如果说明包含中文，Windows PowerShell 5.1 默认用 GBK 编码，传上去可能乱码。建议直接去网页编辑：打开 Release 页面 → 点 **Edit** → 编辑说明 → 点 **Publish release**。
{: .prompt-warning }

### 网页发布

打开草稿 Release 的链接，编辑说明内容，拉到底点 **Publish release** 即可。

---

## 第五步：查看和验证

### 查看 Release 信息

```bash
gh release view v1 --repo 你的用户名/resources
```

会列出所有附件、大小和 SHA256 摘要。

### 在浏览器中打开

```bash
gh release view v1 --repo 你的用户名/resources --web
```

### 列出所有 Release

```bash
gh release list --repo 你的用户名/resources
```

### 查看下载次数

```bash
gh api repos/你的用户名/resources/releases/tags/v1 \
  --jq '.assets[] | "\(.name): \(.download_count)"'
```

---

## 下载链接规则

发布后，每个附件的直链格式是固定的：

```
https://github.com/用户名/仓库名/releases/download/TAG/文件名
```

还有一个永远指向**最新 Release** 的变体：

```
https://github.com/用户名/仓库名/releases/latest/download/文件名
```

用后者的好处：以后更新了文件、发了新 tag，链接完全不用改。

> **文件名用纯英文。** 中文和空格会被 URL 编码成 `%E4%B8%AD%E6%96%87` 这种东西，链接又长又丑，个别下载工具还会出错。
{: .prompt-warning }

在博客里可以这样写 Markdown（e.g.）：

```markdown
| 文件   | 大小   | 下载                                                                             |
| ------ | ------ | -------------------------------------------------------------------------------- |
| 源码包 | 200 MB | [下载](https://github.com/octocat/my-share/releases/download/v1/source-code.zip) |
| 文档   | 5 MB   | [下载](https://github.com/octocat/my-share/releases/download/v1/docs.zip)        |
```

或者更省事——直接把 Release 页面地址发出去，它本身就是现成的下载列表：

```
https://github.com/用户名/仓库名/releases/tag/v1
```

---

## 常用参数速查

| 参数               | 用途                         |
| ------------------ | ---------------------------- |
| `--draft`          | 建成草稿，确认后再发布       |
| `--generate-notes` | 自动生成说明文字             |
| `--target main`    | 指定 tag 打在哪个分支        |
| `--clobber`        | 覆盖同名附件                 |
| `--cleanup-tag`    | 删除 Release 时连 tag 一起删 |
| `--yes`            | 跳过确认提示                 |

---

## 完整性校验

上传前建议算好 SHA256，写进 Release 说明里，下载的人可以自己核对：

**Windows（PowerShell）：**

```powershell
Get-FileHash 文件名.zip -Algorithm SHA256
```

**Mac / Linux：**

```bash
shasum -a 256 文件名.zip
```

---

## 几个要注意的地方

**单文件超过 2 GiB 怎么办？** 用 7-Zip 分卷压缩——「分卷大小」填 `1500m`，压出 `.7z.001`、`.7z.002`，分别上传。下载后解压第一个分卷即可还原。

**上传中途断了？** 重跑 `gh release create` 会报「tag 已存在」，这时改用 `gh release upload` 单独把没传完的文件补上。

**国内下载慢。** GitHub 直链在国内速度不稳定，这是免费方案的固有代价。可以试试换个时间段、用多线程下载工具（IDM、Motrix、aria2），或者浏览器断了重新点——支持断点续传。

**什么东西别往上放。** GitHub 使用条款要求内容与开发活动相关。开源工具（JDK、Maven、Tomcat）没问题，但要避开商业软件安装包 / 破解补丁（可能收到 DMCA），以及有版权的课件教材（公开分享前最好先问一声）。

---

## 命令速查表

```bash
# 创建 Release 并上传文件
gh release create TAG --repo 用户/仓库 --title "标题" --notes "说明" 文件1 文件2

# 追加文件
gh release upload TAG 文件 --repo 用户/仓库

# 覆盖同名文件
gh release upload TAG 文件 --clobber --repo 用户/仓库

# 查看 Release
gh release view TAG --repo 用户/仓库

# 列出所有 Release
gh release list --repo 用户/仓库

# 发布草稿
gh release edit TAG --repo 用户/仓库 --draft=false

# 删除单个附件
gh release delete-asset TAG 文件名 --repo 用户/仓库 --yes

# 删除 Release（连 tag 一起）
gh release delete TAG --repo 用户/仓库 --cleanup-tag --yes

# 查看下载次数
gh api repos/用户/仓库/releases/tags/TAG --jq '.assets[] | "\(.name): \(.download_count)"'
```

---

更多用法可以看 [GitHub CLI 官方文档](https://cli.github.com/manual/gh_release)。
