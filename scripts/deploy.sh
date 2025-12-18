#!/bin/bash

# 车辆管理后台系统部署脚本
# 用于部署后台管理系统到生产环境

set -e

echo "🚀 开始部署车辆管理后台系统..."

# 配置变量
DEPLOY_DIR="/var/www/vehicle-admin"
BACKUP_DIR="/var/backups/vehicle-admin"
SERVICE_NAME="vehicle-admin"
NGINX_CONFIG="/etc/nginx/sites-available/vehicle-admin"

# 检查是否以root权限运行
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ 请使用root权限运行此脚本"
        exit 1
    fi
}

# 检查依赖
check_dependencies() {
    echo "📋 检查部署依赖..."
    
    # 检查Nginx
    if ! command -v nginx &> /dev/null; then
        echo "❌ Nginx 未安装，正在安装..."
        apt-get update && apt-get install -y nginx
    fi
    
    # 检查其他必要工具
    if ! command -v rsync &> /dev/null; then
        echo "❌ rsync 未安装，正在安装..."
        apt-get install -y rsync
    fi
    
    echo "✅ 依赖检查通过"
}

# 创建部署目录
setup_directories() {
    echo "📁 创建部署目录..."
    
    mkdir -p "$DEPLOY_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$DEPLOY_DIR/admin"
    mkdir -p "$DEPLOY_DIR/logs"
    
    echo "✅ 目录创建完成"
}

# 备份现有部署
backup_existing() {
    echo "💾 备份现有部署..."
    
    if [ -d "$DEPLOY_DIR" ] && [ "$(ls -A $DEPLOY_DIR)" ]; then
        BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
        cp -r "$DEPLOY_DIR"/* "$BACKUP_DIR/$BACKUP_NAME/"
        echo "✅ 备份完成: $BACKUP_DIR/$BACKUP_NAME"
    else
        echo "ℹ️  无现有部署需要备份"
    fi
}

# 复制文件到部署目录
deploy_files() {
    echo "📂 复制文件到部署目录..."
    
    # 复制管理后台文件
    cp -r admin/* "$DEPLOY_DIR/admin/"
    
    # 复制配置文件
    cp config.json "$DEPLOY_DIR/" 2>/dev/null || echo "⚠️  config.json 不存在，使用默认配置"
    
    # 设置正确的权限
    chown -R www-data:www-data "$DEPLOY_DIR"
    chmod -R 755 "$DEPLOY_DIR"
    chmod -R 644 "$DEPLOY_DIR"/*
    
    echo "✅ 文件复制完成"
}

# 配置Nginx
configure_nginx() {
    echo "⚙️  配置Nginx..."
    
    cat > "$NGINX_CONFIG" << EOF
server {
    listen 80;
    server_name localhost;
    root $DEPLOY_DIR;
    index admin/admin.html;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # 静态文件缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary "Accept-Encoding";
    }

    # 管理后台
    location /admin {
        alias $DEPLOY_DIR/admin;
        try_files \$uri \$uri/ /admin/admin.html;
    }

    # API代理（如果需要）
    location /api {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # 日志配置
    access_log /var/log/nginx/vehicle-admin-access.log;
    error_log /var/log/nginx/vehicle-admin-error.log;
}
EOF

    # 启用站点
    ln -sf "$NGINX_CONFIG" "/etc/nginx/sites-enabled/"
    
    # 测试Nginx配置
    if nginx -t; then
        echo "✅ Nginx配置测试通过"
    else
        echo "❌ Nginx配置测试失败"
        exit 1
    fi
    
    echo "✅ Nginx配置完成"
}

# 重启服务
restart_services() {
    echo "🔄 重启服务..."
    
    # 重启Nginx
    systemctl restart nginx
    
    # 检查服务状态
    if systemctl is-active --quiet nginx; then
        echo "✅ Nginx重启成功"
    else
        echo "❌ Nginx重启失败"
        exit 1
    fi
}

# 验证部署
validate_deployment() {
    echo "🔍 验证部署..."
    
    # 检查文件是否存在
    if [ ! -f "$DEPLOY_DIR/admin/admin.html" ]; then
        echo "❌ admin.html 文件不存在"
        return 1
    fi
    
    # 检查Nginx是否在运行
    if ! systemctl is-active --quiet nginx; then
        echo "❌ Nginx未运行"
        return 1
    fi
    
    # 检查端口是否在监听
    if ! netstat -tlnp | grep -q ":80"; then
        echo "❌ 端口80未监听"
        return 1
    fi
    
    echo "✅ 部署验证通过"
}

# 创建系统服务
create_systemd_service() {
    echo "🔧 创建系统服务..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=Vehicle Admin Backend Service
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=$DEPLOY_DIR
ExecStart=/usr/bin/python3 -m http.server 8080
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    
    echo "✅ 系统服务创建完成"
}

# 显示部署信息
show_deployment_info() {
    echo ""
    echo "🎉 车辆管理后台系统部署完成！"
    echo "================================"
    echo "📁 部署目录: $DEPLOY_DIR"
    echo "🔧 备份目录: $BACKUP_DIR"
    echo "🌐 访问地址: http://localhost/admin"
    echo "📊 日志文件: /var/log/nginx/vehicle-admin-*.log"
    echo ""
    echo "📋 管理功能:"
    echo "  ✅ 登记记录管理"
    echo "  ✅ 分公司管理"
    echo "  ✅ 收费站管理"
    echo "  ✅ 班组管理"
    echo "  ✅ 收费员管理"
    echo "  ✅ 监控员管理"
    echo "  ✅ 用户管理"
    echo ""
    echo "🔐 默认登录信息:"
    echo "  🔑 超级管理员: admin / admin123"
    echo "  🔑 分公司管理员: beijing_admin / beijing123"
    echo "  🔑 收费站管理员: chaoyang_admin / chaoyang123"
    echo ""
    echo "📖 使用说明:"
    echo "1. 打开浏览器访问 http://localhost/admin"
    echo "2. 使用管理员账号登录"
    echo "3. 开始管理车辆收费数据"
    echo ""
    echo "🔧 常用命令:"
    echo "  systemctl status $SERVICE_NAME  # 查看服务状态"
    echo "  systemctl restart $SERVICE_NAME  # 重启服务"
    echo "  systemctl stop $SERVICE_NAME     # 停止服务"
    echo "  systemctl start $SERVICE_NAME    # 启动服务"
    echo ""
    
    # 记录部署日志
    echo "$(date): 部署完成" >> "$DEPLOY_DIR/logs/deploy.log"
}

# 清理函数
cleanup() {
    echo "🧹 清理临时文件..."
    # 这里可以添加清理逻辑
    echo "✅ 清理完成"
}

# 错误处理
error_handler() {
    echo "❌ 部署过程中发生错误"
    echo "📋 错误信息: $1"
    echo "🔄 正在回滚..."
    
    # 回滚逻辑
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A $BACKUP_DIR)" ]; then
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR" | head -1)
        if [ -n "$LATEST_BACKUP" ]; then
            rm -rf "$DEPLOY_DIR"
            mkdir -p "$DEPLOY_DIR"
            cp -r "$BACKUP_DIR/$LATEST_BACKUP"/* "$DEPLOY_DIR/"
            echo "✅ 已回滚到备份: $LATEST_BACKUP"
        fi
    fi
    
    exit 1
}

# 设置错误处理
trap 'error_handler "部署失败"' ERR

# 主函数
main() {
    echo "🚀 开始车辆管理后台系统部署"
    echo "================================"
    
    check_root
    check_dependencies
    setup_directories
    backup_existing
    deploy_files
    configure_nginx
    create_systemd_service
    restart_services
    validate_deployment
    cleanup
    show_deployment_info
    
    echo ""
    echo "✅ 部署流程全部完成！"
}

# 运行主函数
main "$@"