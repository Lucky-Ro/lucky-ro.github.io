# 野麦子的博客



在线访问：<https://lucky-ro.github.io>

## 本地开发

### 环境要求

- Ruby 3.4+（项目使用 [chruby](https://github.com/postmodern/chruby) 管理）
- Bundler

### 安装依赖

```bash
bundle install
```

### 启动本地服务

```bash
bundle exec jekyll serve
```

浏览器访问 `http://127.0.0.1:4000` 即可预览博客。

常用选项：

```bash
# 包含草稿
bundle exec jekyll serve --drafts

# 实时刷新（文件变更后浏览器自动刷新）
bundle exec jekyll serve --livereload

# 指定端口
bundle exec jekyll serve --port 5000
```

> **注意：** 修改 `_config.yml` 后需要重启服务才能生效。

### 仅构建（不启动服务）

```bash
bundle exec jekyll build
```

构建产物在 `_site/` 目录下。

## 写新文章

在 `_posts/` 目录下创建 Markdown 文件，命名格式为 `YYYY-MM-DD-title.md`，文件开头需要包含 YAML front matter。

## 许可证

本项目代码基于 [MIT](LICENSE) 许可证。文章内容版权归作者所有。
