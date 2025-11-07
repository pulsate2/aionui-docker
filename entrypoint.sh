#!/bin/bash
set -e

/sync_data.sh &
if [ "$DOWNLOAD_BACKUP" = "true" ]; then
	sleep 15
fi

# 创建日志目录
mkdir -p /var/log/supervisor

# 启动 supervisor，这会启动所有配置的服务
echo "Starting services with supervisor..."
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf &

# 等待 supervisor 完全启动
echo "Waiting for supervisor to initialize..."
sleep 5

# 根据环境变量按需启动 code-server
if [ -n "$ENABLE_CODESERVER" ]; then
    echo "ENABLE_CODESERVER is set, starting code-server..."
    supervisorctl start code-server
else
    echo "ENABLE_CODESERVER not set, code-server will not start"
fi

# 根据环境变量按需启动 cloudflared
if [ -n "$CF_TOKEN" ]; then
    echo "CF_TOKEN is set, starting cloudflared..."
    supervisorctl start cloudflared
else
    echo "CF_TOKEN not set, cloudflared will not start"
fi

# 等待 AionUi 启动并截获密码
echo "Waiting for AionUi to start..."
sleep 5

# 尝试从日志中提取初始密码
if [ -f /var/log/supervisor/aionui.out.log ]; then
    echo "=================================="
    echo "AionUi Initial Credentials:"
    echo "=================================="
    grep -A 2 "Initial Admin Credentials" /var/log/supervisor/aionui.out.log || echo "Password not found in logs yet. Check /var/log/supervisor/aionui.out.log manually."
    echo "=================================="
fi

# 显示访问信息
echo ""
echo "=================================="
echo "Services are starting..."
echo "=================================="
echo "AionUi will be available at: http://localhost/aionui/"
echo "Code-Server will be available at: http://localhost/code-server/"
echo ""
echo "To view AionUi logs (including password):"
echo "  docker exec <container-name> cat /var/log/supervisor/aionui.out.log"
echo ""
echo "To view all logs:"
echo "  docker exec <container-name> tail -f /var/log/supervisor/*.log"
echo "=================================="

# 保持容器运行
tail -f /var/log/supervisor/supervisord.log
