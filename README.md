# 车辆管理后台系统

基于Supabase的后台管理界面，专为车辆登记管理系统设计，提供完整的后台管理功能。

## 🚀 功能特性

### 🔐 用户认证与管理
- 多角色权限系统（超级管理员、分公司管理员、收费站管理员）
- 安全的用户登录认证
- 用户权限分级管理

### 🏢 组织架构管理
- **分公司管理**：创建和管理分公司信息
- **收费站管理**：管理各分公司下属的收费站
- **班组管理**：收费站的班组设置

### 👥 人员管理
- **收费员管理**：收费员信息录入和管理
- **监控员管理**：监控员信息录入和管理

### 📊 数据管理
- **登记记录管理**：查看和管理所有车辆登记记录
- **数据导出**：支持Excel格式导出
- **数据统计**：各类数据统计和报表

### 🔧 系统特性
- **权限控制**：基于角色的访问控制（RBAC）
- **数据隔离**：不同级别管理员只能查看对应权限范围内的数据
- **响应式设计**：适配各种设备屏幕
- **实时数据**：基于Supabase实时数据同步

## 📋 安装部署

### 环境要求
- Web服务器（如Nginx、Apache）
- 现代浏览器支持
- Supabase项目配置

### 快速部署
1. 克隆本仓库到您的服务器
2. 配置Supabase连接信息（修改`admin/admin.js`）
3. 运行数据库迁移脚本（`supabase/migrations/`）
4. 部署到Web服务器

### 本地测试
```bash
# 进入admin目录
cd admin

# 使用Python启动本地服务器
python3 -m http.server 8080

# 或使用Node.js
npx http-server -p 8080
```

访问 `http://localhost:8080/index.html` 即可打开后台管理系统。

## 🔧 配置说明

### Supabase配置
编辑 `admin/admin.js` 文件，配置您的Supabase项目信息：
```javascript
const SUPABASE_URL = '您的Supabase项目URL';
const SUPABASE_ANON_KEY = '您的Supabase匿名密钥';
```

### 数据库初始化
运行以下SQL迁移文件来创建必要的数据库表结构：
1. `supabase/migrations/00003_create_admin_management_tables.sql` - 创建基础管理表
2. `supabase/migrations/20251216135749_create_admin_users.sql` - 创建管理员用户表

## 👥 角色权限说明

### 超级管理员
- ✅ 查看所有数据
- ✅ 管理所有分公司、收费站、人员
- ✅ 创建和管理所有用户
- ✅ 系统设置和配置

### 分公司管理员
- ✅ 查看自己分公司下的所有数据
- ✅ 管理自己分公司下的收费站、班组、人员
- ✅ 创建和管理收费站管理员
- ❌ 无法查看其他分公司的数据

### 收费站管理员
- ✅ 查看自己收费站下的数据
- ✅ 管理自己收费站下的班组、人员
- ✅ 处理车辆登记记录
- ❌ 无法查看其他收费站的数据
- ❌ 无法管理用户

## 📁 项目结构

```
├── admin/                          # 后台管理前端文件
│   ├── index.html                  # 主页面
│   ├── admin.js                    # 核心JavaScript逻辑
│   └── test-connection.html       # 连接测试页面
├── scripts/                        # 部署和配置脚本
│   └── setup-admin.sh             # 自动配置脚本
├── supabase/migrations/             # 数据库迁移文件
│   ├── 00003_create_admin_management_tables.sql
│   └── 20251216135749_create_admin_users.sql
├── fix-admin.sh                   # 修复脚本（Linux/Mac）
├── fix-admin.ps1                  # 修复脚本（Windows）
└── verify-setup.sh               # 环境验证脚本
```

## 🔒 安全说明

- 系统采用JWT令牌进行身份验证
- 所有数据库操作都通过Supabase Row Level Security (RLS) 进行权限控制
- 支持HTTPS加密传输
- 敏感信息存储在环境变量中

## 🛠️ 技术栈

- **前端**：HTML5, CSS3, JavaScript (ES6+)
- **后端**：Supabase (PostgreSQL + PostgREST)
- **认证**：Supabase Auth
- **部署**：静态文件部署到任何Web服务器

## 📞 支持与联系

如有问题或建议，请通过GitHub Issues提交反馈。

## 📄 许可证

MIT License - 详见LICENSE文件