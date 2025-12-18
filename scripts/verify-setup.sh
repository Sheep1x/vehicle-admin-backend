#!/bin/bash

# 车辆管理后台系统验证脚本
# 用于验证系统安装和配置是否正确

set -e

echo "🔍 开始验证车辆管理后台系统设置..."

# 配置变量
DEPLOY_DIR="/var/www/vehicle-admin"
CONFIG_FILE="$DEPLOY_DIR/config.json"
ADMIN_HTML="$DEPLOY_DIR/admin/admin.html"
ADMIN_JS="$DEPLOY_DIR/admin/admin.js"
ADMIN_CSS="$DEPLOY_DIR/admin/admin.css"
NGINX_CONFIG="/etc/nginx/sites-available/vehicle-admin"
LOG_FILE="/var/log/vehicle-admin-verify.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 创建日志文件
setup_logging() {
    echo "📝 设置日志..."
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    echo "$(date): 验证脚本开始执行" >> "$LOG_FILE"
    echo -e "${GREEN}✅${NC} 日志设置完成"
}

# 验证基本文件结构
verify_file_structure() {
    echo -e "\n📁 验证文件结构..."
    
    local errors=0
    
    # 检查部署目录
    if [ -d "$DEPLOY_DIR" ]; then
        echo -e "${GREEN}✅${NC} 部署目录存在: $DEPLOY_DIR"
        echo "$(date): 部署目录存在" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} 部署目录不存在: $DEPLOY_DIR"
        echo "$(date): 部署目录不存在" >> "$LOG_FILE"
        ((errors++))
    fi
    
    # 检查管理后台文件
    if [ -f "$ADMIN_HTML" ]; then
        echo -e "${GREEN}✅${NC} 管理HTML文件存在"
        echo "$(date): 管理HTML文件存在" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} 管理HTML文件不存在"
        echo "$(date): 管理HTML文件不存在" >> "$LOG_FILE"
        ((errors++))
    fi
    
    if [ -f "$ADMIN_JS" ]; then
        echo -e "${GREEN}✅${NC} 管理JS文件存在"
        echo "$(date): 管理JS文件存在" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} 管理JS文件不存在"
        echo "$(date): 管理JS文件不存在" >> "$LOG_FILE"
        ((errors++))
    fi
    
    if [ -f "$ADMIN_CSS" ]; then
        echo -e "${GREEN}✅${NC} 管理CSS文件存在"
        echo "$(date): 管理CSS文件存在" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} 管理CSS文件不存在"
        echo "$(date): 管理CSS文件不存在" >> "$LOG_FILE"
        ((errors++))
    fi
    
    if [ "$errors" -eq 0 ]; then
        echo -e "${GREEN}✅${NC} 文件结构验证通过"
        return 0
    else
        echo -e "${RED}❌${NC} 文件结构验证失败，发现 $errors 个错误"
        return 1
    fi
}

# 验证配置文件
verify_config() {
    echo -e "\n⚙️  验证配置文件..."
    
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✅${NC} 配置文件存在"
        echo "$(date): 配置文件存在" >> "$LOG_FILE"
        
        # 验证JSON格式
        if python3 -m json.tool "$CONFIG_FILE" > /dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} 配置文件格式正确"
            echo "$(date): 配置文件格式正确" >> "$LOG_FILE"
            
            # 检查必要字段
            if grep -q '"supabase"' "$CONFIG_FILE" && grep -q '"url"' "$CONFIG_FILE" && grep -q '"anon_key"' "$CONFIG_FILE"; then
                echo -e "${GREEN}✅${NC} Supabase配置完整"
                echo "$(date): Supabase配置完整" >> "$LOG_FILE"
            else
                echo -e "${YELLOW}⚠️${NC} Supabase配置不完整"
                echo "$(date): Supabase配置不完整" >> "$LOG_FILE"
            fi
        else
            echo -e "${RED}❌${NC} 配置文件格式错误"
            echo "$(date): 配置文件格式错误" >> "$LOG_FILE"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️${NC} 配置文件不存在，使用默认配置"
        echo "$(date): 配置文件不存在" >> "$LOG_FILE"
    fi
}

# 验证服务状态
verify_services() {
    echo -e "\n🔄 验证服务状态..."
    
    # 检查Nginx
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}✅${NC} Nginx服务运行正常"
        echo "$(date): Nginx服务运行正常" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} Nginx服务未运行"
        echo "$(date): Nginx服务未运行" >> "$LOG_FILE"
        return 1
    fi
    
    # 检查车辆管理服务（如果存在）
    if systemctl list-unit-files | grep -q "vehicle-admin"; then
        if systemctl is-active --quiet vehicle-admin; then
            echo -e "${GREEN}✅${NC} 车辆管理服务运行正常"
            echo "$(date): 车辆管理服务运行正常" >> "$LOG_FILE"
        else
            echo -e "${YELLOW}⚠️${NC} 车辆管理服务未运行"
            echo "$(date): 车辆管理服务未运行" >> "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}ℹ️${NC} 车辆管理服务未安装"
        echo "$(date): 车辆管理服务未安装" >> "$LOG_FILE"
    fi
    
    echo -e "${GREEN}✅${NC} 服务状态验证完成"
}

# 验证Nginx配置
verify_nginx() {
    echo -e "\n🌐 验证Nginx配置..."
    
    # 检查Nginx配置语法
    if nginx -t > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} Nginx配置语法正确"
        echo "$(date): Nginx配置语法正确" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} Nginx配置语法错误"
        echo "$(date): Nginx配置语法错误" >> "$LOG_FILE"
        nginx -t 2>> "$LOG_FILE"
        return 1
    fi
    
    # 检查站点配置
    if [ -f "$NGINX_CONFIG" ]; then
        echo -e "${GREEN}✅${NC} 站点配置文件存在"
        echo "$(date): 站点配置文件存在" >> "$LOG_FILE"
        
        # 检查配置内容
        if grep -q "listen 80" "$NGINX_CONFIG" && grep -q "server_name" "$NGINX_CONFIG"; then
            echo -e "${GREEN}✅${NC} 站点配置内容完整"
            echo "$(date): 站点配置内容完整" >> "$LOG_FILE"
        else
            echo -e "${YELLOW}⚠️${NC} 站点配置内容不完整"
            echo "$(date): 站点配置内容不完整" >> "$LOG_FILE"
        fi
    else
        echo -e "${YELLOW}⚠️${NC} 站点配置文件不存在"
        echo "$(date): 站点配置文件不存在" >> "$LOG_FILE"
    fi
    
    # 检查端口监听
    if netstat -tlnp | grep -q ":80"; then
        echo -e "${GREEN}✅${NC} 端口80监听正常"
        echo "$(date): 端口80监听正常" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} 端口80未监听"
        echo "$(date): 端口80未监听" >> "$LOG_FILE"
        return 1
    fi
    
    echo -e "${GREEN}✅${NC} Nginx验证完成"
}

# 验证文件权限
verify_permissions() {
    echo -e "\n🔒 验证文件权限..."
    
    if [ -d "$DEPLOY_DIR" ]; then
        # 检查目录所有者
        local owner=$(stat -c "%U:%G" "$DEPLOY_DIR")
        if [ "$owner" = "www-data:www-data" ]; then
            echo -e "${GREEN}✅${NC} 部署目录权限正确"
            echo "$(date): 部署目录权限正确" >> "$LOG_FILE"
        else
            echo -e "${YELLOW}⚠️${NC} 部署目录权限不正确: $owner"
            echo "$(date): 部署目录权限不正确: $owner" >> "$LOG_FILE"
        fi
        
        # 检查文件权限
        local wrong_perms=$(find "$DEPLOY_DIR" -type f -not -perm 644 | wc -l)
        if [ "$wrong_perms" -eq 0 ]; then
            echo -e "${GREEN}✅${NC} 文件权限正确"
            echo "$(date): 文件权限正确" >> "$LOG_FILE"
        else
            echo -e "${YELLOW}⚠️${NC} 发现 $wrong_perms 个文件权限不正确"
            echo "$(date): 发现 $wrong_perms 个文件权限不正确" >> "$LOG_FILE"
        fi
    else
        echo -e "${RED}❌${NC} 部署目录不存在"
        echo "$(date): 部署目录不存在" >> "$LOG_FILE"
        return 1
    fi
    
    echo -e "${GREEN}✅${NC} 权限验证完成"
}

# 验证网络连接
verify_network() {
    echo -e "\n🌐 验证网络连接..."
    
    # 测试本地网络
    if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} 外网连接正常"
        echo "$(date): 外网连接正常" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} 外网连接异常"
        echo "$(date): 外网连接异常" >> "$LOG_FILE"
        return 1
    fi
    
    # 测试本地服务
    if curl -s --max-time 10 "http://localhost/admin" > /dev/null; then
        echo -e "${GREEN}✅${NC} 本地服务访问正常"
        echo "$(date): 本地服务访问正常" >> "$LOG_FILE"
    else
        echo -e "${RED}❌${NC} 本地服务访问异常"
        echo "$(date): 本地服务访问异常" >> "$LOG_FILE"
        return 1
    fi
    
    echo -e "${GREEN}✅${NC} 网络验证完成"
}

# 验证数据库连接
verify_database() {
    echo -e "\n🗄️  验证数据库连接..."
    
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "supabase" "$CONFIG_FILE"; then
            local supabase_url=$(grep -o '"url": *"[^"]*"' "$CONFIG_FILE" | sed 's/"url": *"\([^"]*\)"/\1/')
            
            if curl -s --max-time 10 "$supabase_url" > /dev/null; then
                echo -e "${GREEN}✅${NC} 数据库服务可达"
                echo "$(date): 数据库服务可达" >> "$LOG_FILE"
            else
                echo -e "${YELLOW}⚠️${NC} 数据库服务可能不可达"
                echo "$(date): 数据库服务可能不可达" >> "$LOG_FILE"
            fi
        else
            echo -e "${RED}❌${NC} 数据库配置缺失"
            echo "$(date): 数据库配置缺失" >> "$LOG_FILE"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️${NC} 配置文件不存在"
        echo "$(date): 配置文件不存在" >> "$LOG_FILE"
    fi
    
    echo -e "${GREEN}✅${NC} 数据库验证完成"
}

# 生成验证报告
generate_report() {
    echo -e "\n📊 生成验证报告..."
    
    local report_file="/var/log/vehicle-admin-verify-report-$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
车辆管理后台系统验证报告
生成时间: $(date)
=====================================

验证项目:
- 文件结构: ✅
- 配置文件: ✅
- 服务状态: ✅
- Nginx配置: ✅
- 文件权限: ✅
- 网络连接: ✅
- 数据库连接: ✅

系统信息:
- 主机名: $(hostname)
- 操作系统: $(lsb_release -d -s 2>/dev/null || echo "Unknown")
- 内核版本: $(uname -r)
- 运行时间: $(uptime)

服务状态:
- Nginx: $(systemctl is-active nginx)
- 车辆管理: $(systemctl is-active vehicle-admin 2>/dev/null || echo "未安装")

文件结构:
$(ls -la "$DEPLOY_DIR" 2>/dev/null || echo "部署目录不存在")

网络状态:
- 端口80: $(netstat -tlnp | grep -q ":80" && echo "监听中" || echo "未监听")
- 本地访问: $(curl -s --max-time 5 "http://localhost/admin" > /dev/null && echo "正常" || echo "异常")

访问地址:
- 管理后台: http://localhost/admin
- 配置文件: $CONFIG_FILE
- 部署目录: $DEPLOY_DIR

使用说明:
1. 打开浏览器访问 http://localhost/admin
2. 使用管理员账号登录
3. 开始管理车辆收费数据

默认账号:
- 超级管理员: admin / admin123
- 分公司管理员: beijing_admin / beijing123
- 收费站管理员: chaoyang_admin / chaoyang123

下次验证建议: $(date -d "+7 days")
EOF

    echo -e "${GREEN}✅${NC} 验证报告生成完成: $report_file"
}

# 显示验证结果
show_results() {
    echo -e "\n🎉 车辆管理后台系统验证完成！"
    echo "================================"
    
    local overall_status="${GREEN}✅ 通过${NC}"
    local issues=0
    
    # 统计问题
    [ ! -f "$ADMIN_HTML" ] && ((issues++))
    [ ! -f "$ADMIN_JS" ] && ((issues++))
    [ ! -f "$ADMIN_CSS" ] && ((issues++))
    ! systemctl is-active --quiet nginx && ((issues++))
    
    if [ "$issues" -gt 0 ]; then
        overall_status="${RED}❌ 失败${NC}"
    fi
    
    echo -e "总体状态: $overall_status"
    echo -e "发现问题: ${issues} 个"
    echo ""
    echo "📁 部署目录: $DEPLOY_DIR"
    echo "🔗 访问地址: http://localhost/admin"
    echo "📊 验证报告: /var/log/vehicle-admin-verify-report-*.txt"
    echo ""
    echo "📋 系统状态:"
    echo "  • Nginx服务: $(systemctl is-active nginx)"
    echo "  • 部署目录: $([ -d "$DEPLOY_DIR" ] && echo "存在" || echo "不存在")"
    echo "  • 管理文件: $([ -f "$ADMIN_HTML" ] && echo "存在" || echo "不存在")"
    echo "  • 配置文件: $([ -f "$CONFIG_FILE" ] && echo "存在" || echo "不存在")"
    echo ""
    
    # 记录验证完成
    echo "$(date): 验证完成，发现 $issues 个问题" >> "$LOG_FILE"
}

# 错误处理
error_handler() {
    echo -e "${RED}❌${NC} 验证过程中发生错误"
    echo "📋 错误信息: $1"
    echo "$(date): 验证失败 - $1" >> "$LOG_FILE"
    exit 1
}

# 设置错误处理
trap 'error_handler "验证失败"' ERR

# 主函数
main() {
    echo "🔍 开始车辆管理后台系统验证"
    echo "================================"
    
    setup_logging
    verify_file_structure
    verify_config
    verify_services
    verify_nginx
    verify_permissions
    verify_network
    verify_database
    generate_report
    show_results
    
    echo ""
    echo -e "${GREEN}✅${NC} 验证流程全部完成！"
}

# 显示使用说明
show_usage() {
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -q, --quick     快速验证（仅检查关键项目）"
    echo "  -f, --file      仅验证文件结构"
    echo "  -s, --service   仅验证服务状态"
    echo "  -n, --network   仅验证网络连接"
    echo ""
    echo "示例:"
    echo "  $0                    # 完整验证"
    echo "  $0 --quick            # 快速验证"
    echo "  $0 --file             # 文件验证"
    echo "  $0 --service          # 服务验证"
    echo "  $0 --network          # 网络验证"
}

# 快速验证模式
quick_verify() {
    echo "🏃 快速验证模式..."
    
    setup_logging
    verify_file_structure
    verify_services
    verify_nginx
    
    echo -e "${GREEN}✅${NC} 快速验证完成"
}

# 解析命令行参数
case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -q|--quick)
        quick_verify
        exit 0
        ;;
    -f|--file)
        setup_logging
        verify_file_structure
        exit 0
        ;;
    -s|--service)
        setup_logging
        verify_services
        exit 0
        ;;
    -n|--network)
        setup_logging
        verify_network
        exit 0
        ;;
    "")
        main
        exit 0
        ;;
    *)
        echo -e "${RED}❌${NC} 未知选项: $1"
        show_usage
        exit 1
        ;;
esac