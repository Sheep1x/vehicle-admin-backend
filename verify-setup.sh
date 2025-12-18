#!/bin/bash

# 车辆管理后台系统验证脚本
# 用于验证系统安装和配置是否正确

set -e

echo "🔍 开始验证车辆管理后台系统..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 验证结果计数
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

# 打印测试结果
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ $test_name${NC}"
        ((TESTS_PASSED++))
    elif [ "$result" = "FAIL" ]; then
        echo -e "${RED}❌ $test_name${NC}"
        echo -e "   ${RED}错误: $message${NC}"
        ((TESTS_FAILED++))
    elif [ "$result" = "WARN" ]; then
        echo -e "${YELLOW}⚠️  $test_name${NC}"
        echo -e "   ${YELLOW}警告: $message${NC}"
        ((WARNINGS++))
    fi
}

# 验证文件结构
test_file_structure() {
    echo "📁 验证文件结构..."
    
    # 检查主要文件
    if [ -f "admin/admin.html" ]; then
        print_test_result "admin.html 文件存在" "PASS"
    else
        print_test_result "admin.html 文件存在" "FAIL" "admin.html 文件不存在"
    fi
    
    if [ -f "admin/admin.css" ]; then
        print_test_result "admin.css 文件存在" "PASS"
    else
        print_test_result "admin.css 文件存在" "FAIL" "admin.css 文件不存在"
    fi
    
    if [ -f "admin/admin.js" ]; then
        print_test_result "admin.js 文件存在" "PASS"
    else
        print_test_result "admin.js 文件存在" "FAIL" "admin.js 文件不存在"
    fi
    
    # 检查脚本文件
    if [ -f "scripts/setup-admin.sh" ]; then
        print_test_result "setup-admin.sh 脚本存在" "PASS"
    else
        print_test_result "setup-admin.sh 脚本存在" "FAIL" "setup-admin.sh 文件不存在"
    fi
    
    if [ -f "scripts/deploy.sh" ]; then
        print_test_result "deploy.sh 脚本存在" "PASS"
    else
        print_test_result "deploy.sh 脚本存在" "FAIL" "deploy.sh 文件不存在"
    fi
    
    if [ -f "scripts/backup.sh" ]; then
        print_test_result "backup.sh 脚本存在" "PASS"
    else
        print_test_result "backup.sh 脚本存在" "FAIL" "backup.sh 文件不存在"
    fi
    
    # 检查数据库迁移文件
    if [ -f "supabase/migrations/20241218_create_tables.sql" ]; then
        print_test_result "数据库迁移文件存在" "PASS"
    else
        print_test_result "数据库迁移文件存在" "FAIL" "数据库迁移文件不存在"
    fi
    
    # 检查README文件
    if [ -f "README.md" ]; then
        print_test_result "README.md 文件存在" "PASS"
    else
        print_test_result "README.md 文件存在" "WARN" "README.md 文件不存在"
    fi
}

# 验证文件权限
test_file_permissions() {
    echo "🔒 验证文件权限..."
    
    # 检查脚本文件是否可执行
    if [ -x "scripts/setup-admin.sh" ]; then
        print_test_result "setup-admin.sh 可执行" "PASS"
    else
        print_test_result "setup-admin.sh 可执行" "WARN" "setup-admin.sh 没有执行权限"
    fi
    
    if [ -x "scripts/deploy.sh" ]; then
        print_test_result "deploy.sh 可执行" "PASS"
    else
        print_test_result "deploy.sh 可执行" "WARN" "deploy.sh 没有执行权限"
    fi
    
    if [ -x "scripts/backup.sh" ]; then
        print_test_result "backup.sh 可执行" "PASS"
    else
        print_test_result "backup.sh 可执行" "WARN" "backup.sh 没有执行权限"
    fi
}

# 验证配置文件
test_configuration() {
    echo "⚙️  验证配置文件..."
    
    if [ -f "config.json" ]; then
        # 检查JSON格式
        if python3 -m json.tool config.json > /dev/null 2>&1; then
            print_test_result "config.json 格式正确" "PASS"
            
            # 检查必要字段
            if grep -q '"supabase"' config.json; then
                print_test_result "Supabase 配置存在" "PASS"
            else
                print_test_result "Supabase 配置存在" "WARN" "缺少 Supabase 配置"
            fi
            
            if grep -q '"url"' config.json && grep -q '"anon_key"' config.json; then
                print_test_result "数据库连接配置完整" "PASS"
            else
                print_test_result "数据库连接配置完整" "WARN" "缺少数据库连接信息"
            fi
        else
            print_test_result "config.json 格式正确" "FAIL" "config.json JSON格式错误"
        fi
    else
        print_test_result "config.json 文件存在" "WARN" "config.json 文件不存在，使用默认配置"
    fi
}

# 验证JavaScript代码
test_javascript_code() {
    echo "📝 验证JavaScript代码..."
    
    if [ -f "admin/admin.js" ]; then
        # 检查基本语法（简单的检查）
        if grep -q "function" admin/admin.js; then
            print_test_result "admin.js 包含函数定义" "PASS"
        else
            print_test_result "admin.js 包含函数定义" "WARN" "admin.js 可能没有函数定义"
        fi
        
        # 检查Supabase配置
        if grep -q "SUPABASE_URL" admin/admin.js; then
            print_test_result "admin.js 包含Supabase配置" "PASS"
        else
            print_test_result "admin.js 包含Supabase配置" "WARN" "admin.js 缺少Supabase配置"
        fi
        
        # 检查登录功能
        if grep -q "login\|auth" admin/admin.js; then
            print_test_result "admin.js 包含认证功能" "PASS"
        else
            print_test_result "admin.js 包含认证功能" "WARN" "admin.js 缺少认证功能"
        fi
    fi
}

# 验证HTML结构
test_html_structure() {
    echo "🏗️  验证HTML结构..."
    
    if [ -f "admin/admin.html" ]; then
        # 检查基本HTML结构
        if grep -q "<!DOCTYPE html>" admin/admin.html; then
            print_test_result "admin.html DOCTYPE正确" "PASS"
        else
            print_test_result "admin.html DOCTYPE正确" "WARN" "admin.html 缺少DOCTYPE声明"
        fi
        
        # 检查包含CSS和JS
        if grep -q "admin.css" admin/admin.html; then
            print_test_result "admin.html 包含CSS文件" "PASS"
        else
            print_test_result "admin.html 包含CSS文件" "WARN" "admin.html 未包含admin.css"
        fi
        
        if grep -q "admin.js" admin/admin.html; then
            print_test_result "admin.html 包含JS文件" "PASS"
        else
            print_test_result "admin.html 包含JS文件" "WARN" "admin.html 未包含admin.js"
        fi
    fi
}

# 验证数据库连接
test_database_connection() {
    echo "🗄️  验证数据库连接..."
    
    # 检查是否能访问Supabase
    if command -v curl > /dev/null; then
        SUPABASE_URL="https://codvnervcuxohwtxotpn.supabase.co"
        if curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL" | grep -q "200\|302"; then
            print_test_result "Supabase服务可访问" "PASS"
        else
            print_test_result "Supabase服务可访问" "WARN" "Supabase服务可能不可访问"
        fi
    else
        print_test_result "Supabase服务可访问" "WARN" "curl命令不可用，无法测试连接"
    fi
}

# 验证系统依赖
test_system_dependencies() {
    echo "🔧 验证系统依赖..."
    
    # 检查基本命令
    if command -v bash > /dev/null; then
        print_test_result "bash 可用" "PASS"
    else
        print_test_result "bash 可用" "FAIL" "bash 命令不可用"
    fi
    
    if command -v curl > /dev/null; then
        print_test_result "curl 可用" "PASS"
    else
        print_test_result "curl 可用" "WARN" "curl 命令不可用"
    fi
    
    if command -v python3 > /dev/null; then
        print_test_result "python3 可用" "PASS"
    else
        print_test_result "python3 可用" "WARN" "python3 命令不可用"
    fi
}

# 验证安全性
test_security() {
    echo "🛡️  验证安全性..."
    
    # 检查是否包含敏感信息
    if [ -f "admin/admin.js" ]; then
        if grep -q "password.*=.*['\"]admin123['\"]" admin/admin.js; then
            print_test_result "默认密码检查" "WARN" "发现使用默认密码，建议修改"
        else
            print_test_result "默认密码检查" "PASS"
        fi
    fi
    
    # 检查是否使用HTTPS
    if grep -q "https://" admin/admin.js; then
        print_test_result "HTTPS连接" "PASS"
    else
        print_test_result "HTTPS连接" "WARN" "建议使用HTTPS连接"
    fi
}

# 性能测试
test_performance() {
    echo "⚡ 性能测试..."
    
    # 检查文件大小
    local js_size=$(wc -c < admin/admin.js 2>/dev/null || echo 0)
    local css_size=$(wc -c < admin/admin.css 2>/dev/null || echo 0)
    local html_size=$(wc -c < admin/admin.html 2>/dev/null || echo 0)
    
    if [ "$js_size" -gt 1000000 ]; then
        print_test_result "JavaScript文件大小" "WARN" "admin.js 文件较大 ($js_size 字节)，可能影响加载速度"
    else
        print_test_result "JavaScript文件大小" "PASS" "admin.js 文件大小合理 ($js_size 字节)"
    fi
    
    if [ "$css_size" -gt 500000 ]; then
        print_test_result "CSS文件大小" "WARN" "admin.css 文件较大 ($css_size 字节)"
    else
        print_test_result "CSS文件大小" "PASS" "admin.css 文件大小合理 ($css_size 字节)"
    fi
    
    # 总大小
    local total_size=$((js_size + css_size + html_size))
    if [ "$total_size" -gt 2000000 ]; then
        print_test_result "总文件大小" "WARN" "总文件较大 ($total_size 字节)，建议优化"
    else
        print_test_result "总文件大小" "PASS" "总文件大小合理 ($total_size 字节)"
    fi
}

# 生成验证报告
generate_report() {
    echo ""
    echo "📊 验证报告"
    echo "================================"
    echo "✅ 通过测试: $TESTS_PASSED"
    echo "❌ 失败测试: $TESTS_FAILED"
    echo "⚠️  警告: $WARNINGS"
    echo ""
    
    local total_tests=$((TESTS_PASSED + TESTS_FAILED))
    if [ "$total_tests" -gt 0 ]; then
        local pass_rate=$((TESTS_PASSED * 100 / total_tests))
        echo "📈 通过率: $pass_rate%"
    fi
    
    echo ""
    echo "📋 建议:"
    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo "  🔧 请修复失败的测试项"
    fi
    if [ "$WARNINGS" -gt 0 ]; then
        echo "  ⚠️  请处理警告项以优化系统"
    fi
    if [ "$TESTS_FAILED" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo "  🎉 系统验证完全通过！"
    fi
    
    echo ""
    echo "🔗 访问地址: file://$(pwd)/admin/admin.html"
    echo "📖 使用说明:"
    echo "  - 管理员账号: admin / admin123"
    echo "  - 分公司管理员: beijing_admin / beijing123"
    echo "  - 收费站管理员: chaoyang_admin / chaoyang123"
}

# 主函数
main() {
    echo "🔍 开始车辆管理后台系统验证"
    echo "================================"
    echo "📍 验证目录: $(pwd)"
    echo "⏰ 验证时间: $(date)"
    echo ""
    
    test_file_structure
    echo ""
    test_file_permissions
    echo ""
    test_configuration
    echo ""
    test_javascript_code
    echo ""
    test_html_structure
    echo ""
    test_database_connection
    echo ""
    test_system_dependencies
    echo ""
    test_security
    echo ""
    test_performance
    echo ""
    
    generate_report
    
    # 记录验证日志
    echo "$(date): 验证完成 - 通过: $TESTS_PASSED, 失败: $TESTS_FAILED, 警告: $WARNINGS" >> verification.log
}

# 显示使用说明
show_usage() {
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示帮助信息"
    echo "  -q, --quiet     静默模式，只显示结果"
    echo "  -v, --verbose   详细模式，显示更多信息"
    echo "  --no-report     不生成报告"
    echo ""
    echo "示例:"
    echo "  $0                    # 完整验证"
    echo "  $0 --quiet            # 静默验证"
    echo "  $0 --verbose          # 详细验证"
}

# 解析命令行参数
QUIET=false
VERBOSE=false
GENERATE_REPORT=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --no-report)
            GENERATE_REPORT=false
            shift
            ;;
        *)
            echo "❌ 未知选项: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 根据参数调整输出
if [ "$QUIET" = true ]; then
    exec > /dev/null 2>&1
fi

if [ "$VERBOSE" = true ]; then
    set -x
fi

# 运行主函数
main

exit_code=0
if [ "$TESTS_FAILED" -gt 0 ]; then
    exit_code=1
fi

exit $exit_code