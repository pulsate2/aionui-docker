FROM ubuntu:25.04
# 设置环境变量避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装基础依赖和常用开发工具 (不包含 nginx)
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    gnupg2 \
    lsb-release \
    supervisor \
    tzdata \
    git \
    python3 \
    python3-pip \
    python3-venv \
    vim \
    nano \
    build-essential \
    fonts-liberation \
    libasound2t64 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libgdk-pixbuf2.0-0 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    --no-install-recommends \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# 添加 Nginx 官方仓库并安装最新版本
RUN curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" > /etc/apt/sources.list.d/nginx.list \
    && printf "Package: *\nPin: origin nginx.org\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx \
    && apt-get update \
    && apt-get install -y nginx \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && rm -rf /var/lib/apt/lists/*

# 安装 Python 依赖
RUN pip install --no-cache-dir --upgrade setuptools wheel --break-system-packages
RUN pip3 install --no-cache-dir --break-system-packages \
    requests \
    flask \
    redis \
    pillow \
    beautifulsoup4 \
    webdavclient3

# 安装 uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /root/.bashrc

# 下载并安装 .deb 包 (合并下载和安装)
RUN wget https://github.com/iOfficeAI/AionUi/releases/download/v1.6.0/AionUi-1.6.0-linux-amd64.deb -O /tmp/aionui.deb && \
    wget https://github.com/coder/code-server/releases/download/v4.105.1/code-server_4.105.1_amd64.deb -O /tmp/code-server.deb && \
    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared.deb && \
    apt-get update && \
    apt-get install -y /tmp/*.deb && \
    rm /tmp/*.deb && \
    rm -rf /var/lib/apt/lists/*

# 复制配置文件和脚本
COPY nginx.conf /etc/nginx/nginx.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
COPY sync_data.sh /sync_data.sh

# ---- 新增部分开始 ----
# 复制你的默认 HTML 页面到 Nginx 的网站根目录
COPY index.html /var/www/html/index.html

# 确保 Nginx 用户 (www-data) 有权限读取网站文件
RUN chown -R www-data:www-data /var/www/html
# ---- 新增部分结束 ----

# 赋予脚本执行权限
RUN chmod +x /entrypoint.sh /sync_data.sh

# 暴露端口
EXPOSE 80 25808 8080

# 创建数据目录
RUN mkdir -p /data/aionui /data/code-server /data/projects

# 设置工作目录
WORKDIR /data

# 使用 supervisor 启动所有服务

ENTRYPOINT ["/entrypoint.sh"]
