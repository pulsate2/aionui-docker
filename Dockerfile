FROM ubuntu:25.04

# 设置环境变量避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

# 安装基础依赖和常用开发工具
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    nginx \
    supervisor \
    tzdata \
    git \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    vim \
    nano \
    build-essential \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# 安装常用 Python 包
RUN pip3 install --no-cache-dir --break-system-packages \
    requests \
    flask \
    redis \
    pillow \
    beautifulsoup4
	
# This command is updated for modern Ubuntu/Debian distributions
RUN apt-get update \
    && apt-get install -y \
    ca-certificates \
    fonts-liberation \
    libasound2t64 \
    #   ^--- THIS IS THE FIX ---^
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
    lsb-release \
    wget \
    xdg-utils \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 AionUi
RUN wget https://github.com/iOfficeAI/AionUi/releases/download/v1.5.0/AionUi-1.5.0-linux-amd64.deb -O /tmp/aionui.deb \
    && apt-get update \
    && apt-get install -y /tmp/aionui.deb \
    && rm /tmp/aionui.deb \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 code-server
RUN wget https://github.com/coder/code-server/releases/download/v4.105.1/code-server_4.105.1_amd64.deb -O /tmp/code-server.deb \
    && apt-get update \
    && apt-get install -y /tmp/code-server.deb \
    && rm /tmp/code-server.deb \
    && rm -rf /var/lib/apt/lists/*

# 下载并安装 cloudflared
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -O /tmp/cloudflared.deb \
    && apt-get update \
    && apt-get install -y /tmp/cloudflared.deb \
    && rm /tmp/cloudflared.deb \
    && rm -rf /var/lib/apt/lists/*

# 复制 nginx 配置
COPY nginx.conf /etc/nginx/nginx.conf

# 复制 supervisor 配置
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 复制启动脚本
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 暴露端口
EXPOSE 80 25808 8080

# 创建数据目录
RUN mkdir -p /data/aionui /data/code-server /data/projects

# 设置工作目录
WORKDIR /data

# 使用 supervisor 启动所有服务
ENTRYPOINT ["/entrypoint.sh"]
