# Grenade Helper 官网

这是 Grenade Helper 的官方网站，使用纯 HTML、CSS 和 JavaScript 构建。

## 部署到 Zeabur

### 方法一：通过 GitHub（推荐）

1. **将 website 文件夹推送到 GitHub 仓库**
   ```bash
   # 如果还没有初始化 git
   cd website
   git init
   git add .
   git commit -m "Initial commit"
   
   # 创建 GitHub 仓库后
   git remote add origin https://github.com/你的用户名/grenade-helper-website.git
   git branch -M main
   git push -u origin main
   ```

2. **在 Zeabur 上部署**
   - 访问 [Zeabur Dashboard](https://dash.zeabur.com)
   - 点击 "New Project"
   - 选择 "Deploy from GitHub"
   - 选择你的仓库
   - Zeabur 会自动检测这是一个静态网站并部署

### 方法二：使用 Zeabur CLI

1. **安装 Zeabur CLI**
   ```bash
   npm i -g @zeabur/cli
   ```

2. **登录 Zeabur**
   ```bash
   zeabur auth login
   ```

3. **部署**
   ```bash
   cd website
   zeabur deploy
   ```

### 方法三：使用 Docker（适用于需要自定义配置）

如果需要使用 Nginx 进行更多自定义配置，可以使用 Docker 部署。

## 本地预览

使用任何静态服务器都可以预览，例如：

```bash
# 使用 Python
python -m http.server 8000

# 使用 Node.js
npx serve .

# 使用 PHP
php -S localhost:8000
```

然后访问 `http://localhost:8000`

## 文件结构

```
website/
├── index.html      # 主页
├── docs.html       # 文档页面
├── style.css       # 样式文件
├── script.js       # JavaScript 脚本
├── assets/         # 资源文件
│   └── app_icon.png
└── zeabur.json     # Zeabur 配置文件
```

## 功能特性

- 🎨 现代化设计，支持深色/浅色主题
- 📱 响应式布局，支持移动端
- ⚡ 纯静态，加载速度快
- 🌐 SEO 友好
