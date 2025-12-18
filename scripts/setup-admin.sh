#!/bin/bash

# 车辆管理后台系统设置脚本
# 用于初始化后台管理系统

set -e

echo "🚗 开始设置车辆管理后台系统..."

# 检查必要的依赖
check_dependencies() {
    echo "📋 检查依赖项..."
    
    # 检查Node.js
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js 未安装，请先安装Node.js"
        exit 1
    fi
    
    # 检查Git
    if ! command -v git &> /dev/null; then
        echo "❌ Git 未安装，请先安装Git"
        exit 1
    fi
    
    echo "✅ 依赖项检查通过"
}

# 创建必要的目录
setup_directories() {
    echo "📁 创建目录结构..."
    
    mkdir -p admin
    mkdir -p scripts
    mkdir -p supabase/migrations
    mkdir -p logs
    mkdir -p backups
    
    echo "✅ 目录创建完成"
}

# 设置文件权限
setup_permissions() {
    echo "🔒 设置文件权限..."
    
    chmod +x scripts/*.sh
    chmod 644 admin/*
    chmod 644 supabase/migrations/*
    
    echo "✅ 权限设置完成"
}

# 创建配置文件
create_config() {
    echo "⚙️  创建配置文件..."
    
    cat > config.json << EOF
{
  "supabase": {
    "url": "https://codvnervcuxohwtxotpn.supabase.co",
    "anon_key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvZHZuZXJ2Y3V4b2h3dHhvdHBuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU1MTg0MjQsImV4cCI6MjA4MTA5NDQyNH0.FrxgBbqYWmlhrSKZPLtZzn1DMcVEwyGTHs4mKYUuUTQ"
  },
  "app": {
    "name": "车辆管理后台系统",
    "version": "1.0.0",
    "debug": false
  },
  "security": {
    "session_timeout": 3600,
    "max_login_attempts": 5,
    "lockout_duration": 300
  }
}
EOF
    
    echo "✅ 配置文件创建完成"
}

# 创建日志文件
setup_logging() {
    echo "📝 设置日志系统..."
    
    cat > logs/setup.log << EOF
$(date): 后台管理系统设置开始
EOF
    
    echo "✅ 日志系统设置完成"
}

# 验证安装
validate_installation() {
    echo "🔍 验证安装..."
    
    # 检查文件是否存在
    if [ ! -f "admin/admin.html" ]; then
        echo "❌ admin.html 文件不存在"
        return 1
    fi
    
    if [ ! -f "admin/admin.css" ]; then
        echo "❌ admin.css 文件不存在"
        return 1
    fi
    
    if [ ! -f "admin/admin.js" ]; then
        echo "❌ admin.js 文件不存在"
        return 1
    fi
    
    if [ ! -f "supabase/migrations/20241218_create_tables.sql" ]; then
        echo "❌ 数据库迁移文件不存在"
        return 1
    fi
    
    echo "✅ 安装验证通过"
}

# 主函数
main() {
    echo "🚀 开始车辆管理后台系统设置"
    echo "================================"
    
    check_dependencies
    setup_directories
    setup_permissions
    create_config
    setup_logging
    validate_installation
    
    echo ""
    echo "🎉 车辆管理后台系统设置完成！"
    echo "================================"
    echo "📁 文件结构:"
    echo "  ├── admin/          # 后台管理文件"
    echo "  ├── scripts/        # 脚本文件"
    echo "  ├── supabase/       # 数据库迁移"
    echo "  ├── logs/           # 日志文件"
    echo "  └── backups/        # 备份文件"
    echo ""
    echo "📋 下一步操作:"
    echo "1. 配置数据库连接"
    echo "2. 运行数据库迁移"
    echo "3. 启动后台管理系统"
    echo ""
    echo "🔗 访问地址: file://$(pwd)/admin/admin.html"
    echo ""
    echo "📖 使用说明:"
    echo "- 管理员账号: admin / admin123"
    echo "- 分公司管理员: beijing_admin / beijing123"
    echo "- 收费站管理员: chaoyang_admin / chaoyang123"
    echo ""
    echo "$(date): 设置完成" >> logs/setup.log
}

# 运行主函数
main "$@"